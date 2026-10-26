import cpp.cppia.Host;
import haxe.io.Path;
import sys.FileSystem;

class Main {
	static var loaded = 0.0;

	static function main() {
		var script = Sys.args()[0] ?? Path.join([Path.directory(Sys.programPath()), "script.cppia"]);
		App.run(() -> {
			var modified = FileSystem.stat(script).mtime.getTime();
			if (modified > loaded) {
				loaded = modified;
				Host.runFile(script);
			}
		});
	}
}
