import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Uncompress;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

/**
	Puts SDL 3.4.18 in vendor/, where linc/linc_sdl3.xml links it from. Run it from the linc_sdl3 folder:

	  haxe --run Fetch                      SDL for this computer
	  haxe --run Fetch windows android      SDL for the targets named: linux-x64, windows, android
	  haxe --run Fetch --force android      again, even if vendor/ already has this version

	- linux-x64: SDL has no prebuilt Linux library, so this builds a static one from the source, with the patches in
	  patches/ applied. It needs CMake, patch, a C compiler, and the X11 or Wayland development headers; Ninja is used
	  when it's installed.
	- windows: SDL's prebuilt SDL3.dll and its import library, for x64 and arm64. hxcpp copies SDL3.dll next to the exe.
	- android: SDL's prebuilt Android package: the headers, libSDL3.so for each CPU type, and SDL3.jar with SDL's
	  Java classes.

	Downloads are checked against their SHA-256 and kept in a per-user cache, so other projects don't download them
	again: LINC_CACHE if set, otherwise ~/.cache/linc, ~/Library/Caches/linc or %LOCALAPPDATA%\linc. Needs curl,
	which Windows 10 and later, macOS and Linux all have.
**/
class Fetch {
	static inline var VERSION = "3.4.18";
	static inline var RELEASES = "https://github.com/libsdl-org/SDL/releases/download";
	static final SOURCE = {file: 'SDL3-$VERSION.tar.gz', sha256: "9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3"};
	static final WINDOWS = {file: 'SDL3-devel-$VERSION-VC.zip', sha256: "78d84602ae616cfe26b33a73b7d3b9b6b56e8a6650e53d92c9c6ca938f747acd"};
	static final ANDROID = {file: 'SDL3-devel-$VERSION-android.zip', sha256: "e09e4d6593335d089ba124375e8b8abd0fd75173dffcd2c17012b45af121d4e9"};
	static final TARGETS = ["linux-x64", "windows", "android"];

	static function main() {
		if (!FileSystem.exists("haxelib.json") || !FileSystem.exists("linc/linc_sdl3.xml")) {
			fail("Run this from the linc_sdl3 folder.");
		}
		var force = false;
		var targets = [];
		for (arg in Sys.args()) {
			switch arg {
				case "--force":
					force = true;
				case "--help" | "-h":
					Sys.println("Usage: haxe --run Fetch [--force] [" + TARGETS.join(" | ") + " ...]");
					return;
				case target if (TARGETS.contains(target)):
					targets.push(target);
				case other:
					fail('Unknown target "$other": use ${TARGETS.join(", ")}.');
			}
		}
		if (targets.length == 0) {
			targets.push(hostTarget());
		}
		for (target in targets) {
			var vendor = Path.join([Sys.getCwd(), "vendor", target]);
			var version = target == "linux-x64" ? linuxVersion() : VERSION;
			if (!force && installedVersion(vendor) == version) {
				Sys.println('SDL $version for $target is already in $vendor');
				continue;
			}
			switch target {
				case "linux-x64":
					buildLinux(vendor, version);
				case "windows":
					unpackWindows(vendor);
				case "android":
					unpackAndroid(vendor);
			}
			File.saveContent(Path.join([vendor, ".version"]), version);
			Sys.println('SDL $version for $target is in $vendor');
		}
	}

	static function hostTarget():String {
		return switch Sys.systemName() {
			case "Windows": "windows";
			case "Linux" if (!isArm()): "linux-x64";
			case system: fail('linc_sdl3 has no SDL build for $system ${isArm() ? "arm64" : "x64"} yet. Name a target: ${TARGETS.join(", ")}.');
		}
	}

	static function isArm():Bool {
		if (Sys.systemName() == "Windows") {
			// hxcpp checks the same variable. An x64 Haxe running under emulation on Windows on Arm still sees "ARMv8".
			var processor = Sys.getEnv("PROCESSOR_IDENTIFIER");
			return processor != null && ~/\barm/i.match(processor);
		}
		var machine = output("uname", ["-m"]);
		return machine != null && (machine.indexOf("aarch64") >= 0 || machine.indexOf("arm64") >= 0);
	}

	static function installedVersion(vendor:String):Null<String> {
		var file = Path.join([vendor, ".version"]);
		return FileSystem.exists(file) ? StringTools.trim(File.getContent(file)) : null;
	}

	/** The patches in patches/, in the order they're applied. **/
	static function patches():Array<String> {
		if (!FileSystem.exists("patches")) {
			return [];
		}
		var names = [for (name in FileSystem.readDirectory("patches")) if (StringTools.endsWith(name, ".patch")) name];
		names.sort(Reflect.compare);
		return [for (name in names) Path.join([Sys.getCwd(), "patches", name])];
	}

	/** The Linux build's version: SDL's, and a hash of the patches, so a new or changed patch builds it again. **/
	static function linuxVersion():String {
		var all = new StringBuf();
		for (patch in patches()) {
			all.add(Path.withoutDirectory(patch) + "\n" + File.getContent(patch));
		}
		return all.length == 0 ? VERSION : VERSION + "+patches." + haxe.crypto.Md5.encode(all.toString()).substr(0, 8);
	}

	static function buildLinux(vendor:String, version:String) {
		if (!FileSystem.exists("/usr/include/X11/Xlib.h") && !FileSystem.exists("/usr/include/wayland-client.h")) {
			fail("SDL needs the X11 or Wayland development headers to open windows on Linux. Install them as listed in "
				+ "SDL's docs/README-linux.md (on Ubuntu: libx11-dev libxext-dev libwayland-dev libxkbcommon-dev), then run this again.");
		}
		if (output("cmake", ["--version"]) == null) {
			fail("Building SDL for Linux needs CMake.");
		}
		if (patches().length > 0 && output("patch", ["--version"]) == null) {
			fail("Building SDL for Linux needs patch, to apply the files in patches/.");
		}
		var cache = cacheDir();
		var built = Path.join([cache, 'linux-x64-$version']);
		if (installedVersion(built) != version) {
			var tarball = download(SOURCE);
			// A fresh copy of the source, so each patch applies to the release exactly once. tar gives the files their
			// release dates, which can be older than objects built from patched copies, so the build starts over too.
			var source = Path.join([cache, 'SDL3-$VERSION']);
			removeTree(source);
			run("tar", ["xzf", tarball, "-C", cache]);
			for (patch in patches()) {
				Sys.println('  applying ${Path.withoutDirectory(patch)}');
				run("patch", ["-p1", "-d", source, "-i", patch]);
			}
			var build = Path.join([cache, "build-linux-x64"]);
			removeTree(build);
			var configure = ["-S", source, "-B", build];
			if (output("ninja", ["--version"]) != null) {
				configure = configure.concat(["-G", "Ninja"]);
			}
			run("cmake", configure.concat([
				"-DCMAKE_BUILD_TYPE=Release",
				'-DCMAKE_INSTALL_PREFIX=$built',
				// linc_sdl3.xml looks in lib/; Fedora and other distros would otherwise install into lib64/.
				"-DCMAKE_INSTALL_LIBDIR=lib",
				"-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
				"-DSDL_SHARED=OFF",
				"-DSDL_STATIC=ON",
				"-DSDL_TEST_LIBRARY=OFF",
				"-DSDL_TESTS=OFF",
				"-DSDL_EXAMPLES=OFF",
				// SDL warps the mouse with XTest when it has it and falls back to XWarpPointer; off skips the libxtst headers.
				"-DSDL_X11_XTEST=OFF",
			]));
			run("cmake", ["--build", build]);
			run("cmake", ["--install", build]);
			File.saveContent(Path.join([built, ".version"]), version);
		}
		removeTree(vendor);
		copyTree(built, vendor);
	}

	static function unpackWindows(vendor:String) {
		var entries = readZip(download(WINDOWS));
		removeTree(vendor);
		var top = 'SDL3-$VERSION/';
		var count = extract(entries, vendor, name -> {
			if (!StringTools.startsWith(name, top)) {
				return null;
			}
			var path = name.substr(top.length);
			if (StringTools.startsWith(path, "include/")) {
				return path;
			}
			// Only the 64-bit libraries: hxcpp builds x64 or arm64 on Windows. The .pdb files are SDL's debug symbols.
			return ~/^lib\/(x64|arm64)\/SDL3\.(dll|lib)$/.match(path) ? path : null;
		});
		Sys.println('  $count files');
	}

	static function unpackAndroid(vendor:String) {
		var aar = null;
		for (entry in readZip(download(ANDROID))) {
			if (entry.name == 'SDL3-$VERSION.aar') {
				aar = entry.data();
			}
		}
		if (aar == null) {
			fail('SDL3-$VERSION.aar is missing from ${ANDROID.file}.');
		}
		removeTree(vendor);
		var headers = "prefab/modules/SDL3-Headers/include/";
		var library = ~/^prefab\/modules\/SDL3-shared\/libs\/android\.([^\/]+)\/libSDL3\.so$/;
		var count = extract(Zip.read(aar), vendor, name -> {
			if (StringTools.startsWith(name, headers)) {
				return "include/" + name.substr(headers.length);
			}
			if (library.match(name)) {
				return 'lib/${library.matched(1)}/libSDL3.so';
			}
			return name == "classes.jar" ? "SDL3.jar" : null;
		});
		Sys.println('  $count files');
	}

	/** Writes the entries that `place` maps to a path under `dir`, and skips the ones it maps to null. **/
	static function extract(entries:Array<ZipEntry>, dir:String, place:String->Null<String>):Int {
		var count = 0;
		for (entry in entries) {
			if (StringTools.endsWith(entry.name, "/")) {
				continue;
			}
			var path = place(entry.name);
			if (path == null) {
				continue;
			}
			var file = Path.join([dir, path]);
			FileSystem.createDirectory(Path.directory(file));
			File.saveBytes(file, entry.data());
			count++;
		}
		return count;
	}

	static function readZip(file:String):Array<ZipEntry> {
		Sys.println('  unpacking ${Path.withoutDirectory(file)}');
		return Zip.read(File.getBytes(file));
	}

	/** The cached copy of a release file, downloaded and checked first if it isn't there yet. **/
	static function download(release:{file:String, sha256:String}):String {
		var file = Path.join([cacheDir(), release.file]);
		if (!FileSystem.exists(file)) {
			var url = '$RELEASES/release-$VERSION/${release.file}';
			Sys.println('  downloading $url');
			var partial = file + ".part";
			if (Sys.command("curl", ["-fL", "--progress-bar", "-o", partial, url]) != 0) {
				fail('Couldn\'t download $url');
			}
			FileSystem.rename(partial, file);
		}
		var sha256 = sha256(file);
		if (sha256 != release.sha256) {
			FileSystem.deleteFile(file);
			fail('${release.file} has SHA-256 $sha256, expected ${release.sha256}. Deleted it; run this again to download it again.');
		}
		return file;
	}

	/** Hashing a large file is slow in Haxe's interpreter, so this asks the system's own tool. **/
	static function sha256(file:String):String {
		var result = switch Sys.systemName() {
			case "Windows":
				// certutil prints a heading line, then the hash, with spaces between the bytes before Windows 10.
				var lines = output("certutil", ["-hashfile", file, "SHA256"]);
				lines == null ? null : StringTools.replace(lines.split("\n")[1], " ", "");
			case "Mac":
				output("shasum", ["-a", "256", file]);
			default:
				output("sha256sum", [file]);
		}
		if (result == null) {
			fail('Couldn\'t compute the SHA-256 of $file');
		}
		return StringTools.trim(result).split(" ")[0].toLowerCase();
	}

	static function cacheDir():String {
		var root = Sys.getEnv("LINC_CACHE");
		if (root == null) {
			var home = Sys.getEnv("HOME");
			root = switch Sys.systemName() {
				case "Windows": Path.join([Sys.getEnv("LOCALAPPDATA"), "linc"]);
				case "Mac": Path.join([home, "Library", "Caches", "linc"]);
				default: Path.join([Sys.getEnv("XDG_CACHE_HOME") ?? Path.join([home, ".cache"]), "linc"]);
			}
		}
		var dir = Path.join([root, "linc_sdl3", VERSION]);
		FileSystem.createDirectory(dir);
		return dir;
	}

	static function run(command:String, args:Array<String>) {
		if (Sys.command(command, args) != 0) {
			fail('$command failed.');
		}
	}

	/** What the command printed, or null if it couldn't start or failed. **/
	static function output(command:String, args:Array<String>):Null<String> {
		try {
			var process = new Process(command, args);
			var text = process.stdout.readAll().toString();
			var code = process.exitCode();
			process.close();
			return code == 0 ? text : null;
		} catch (e) {
			return null;
		}
	}

	static function copyTree(from:String, to:String) {
		FileSystem.createDirectory(to);
		for (name in FileSystem.readDirectory(from)) {
			var source = Path.join([from, name]);
			if (FileSystem.isDirectory(source)) {
				copyTree(source, Path.join([to, name]));
			} else {
				File.copy(source, Path.join([to, name]));
			}
		}
	}

	static function removeTree(path:String) {
		if (!FileSystem.exists(path)) {
			return;
		}
		if (FileSystem.isDirectory(path)) {
			for (name in FileSystem.readDirectory(path)) {
				removeTree(Path.join([path, name]));
			}
			FileSystem.deleteDirectory(path);
		} else {
			FileSystem.deleteFile(path);
		}
	}

	static function fail(message:String):Dynamic {
		Sys.println("Error: " + message);
		Sys.exit(1);
		return null;
	}
}

typedef ZipEntry = {name:String, data:() -> Bytes};

/**
	Reads a zip through its central directory, which lists every entry's sizes. haxe.zip.Reader walks the entries
	instead, and inflates the ones whose sizes come after their data in pure Haxe to find where they end, which is slow
	in Haxe's interpreter. This inflates each entry once, with zlib.
**/
private class Zip {
	public static function read(zip:Bytes):Array<ZipEntry> {
		var end = zip.length - 22;
		while (end >= 0 && zip.getInt32(end) != 0x06054b50) {
			end--;
		}
		if (end < 0) {
			throw "Not a zip file";
		}
		var count = zip.getUInt16(end + 10);
		var pos = zip.getInt32(end + 16);
		var entries = [];
		for (_ in 0...count) {
			if (zip.getInt32(pos) != 0x02014b50) {
				throw "Damaged zip directory";
			}
			var method = zip.getUInt16(pos + 10);
			var compressedSize = zip.getInt32(pos + 20);
			var size = zip.getInt32(pos + 24);
			var nameLength = zip.getUInt16(pos + 28);
			var name = zip.getString(pos + 46, nameLength);
			var header = zip.getInt32(pos + 42);
			var start = header + 30 + zip.getUInt16(header + 26) + zip.getUInt16(header + 28);
			entries.push({name: name, data: () -> method == 0 ? zip.sub(start, size) : inflate(zip.sub(start, compressedSize), size)});
			pos += 46 + nameLength + zip.getUInt16(pos + 30) + zip.getUInt16(pos + 32);
		}
		return entries;
	}

	static function inflate(data:Bytes, size:Int):Bytes {
		var out = Bytes.alloc(size);
		var inflater = new Uncompress(-15);
		var result = inflater.execute(data, 0, out, 0);
		inflater.close();
		if (!result.done || result.write != size) {
			throw "Damaged zip entry";
		}
		return out;
	}
}
