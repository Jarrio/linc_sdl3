# linc_sdl3

hxcpp bindings for the parts of SDL3 that simple, a UI layer on Skia, uses: windows, OpenGL contexts, events, text input, the clipboard, cursors, display modes, the system's light or dark theme and the 2D renderer.

`sdl3.SDL` wraps the externs in `sdl3.Native` with ordinary static functions, so cppia scripts can call them through a `-D scriptable` host.

## Requirements

- Haxe 5 and hxcpp with the extern marshalling types (`@:cpp.PointerType`, `@:cpp.ValueType`): HaxeFoundation/haxe#11981 and HaxeFoundation/hxcpp#1189, from December 2025 on. Tested with Haxe `5.0.0-preview.1+35cbcb5` / hxcpp `90b879e`, and Haxe `5.0.0-preview.1+066bd83` / hxcpp `504403d`.
- SDL3 in `vendor/`: a static build for Linux x64, SDL's prebuilt DLL for Windows x64 and arm64, or SDL's prebuilt package for Android. `linc/linc_sdl3.xml` sets up those three so far. macOS isn't set up yet.

## Getting SDL3

`haxe --run Fetch` in this folder puts SDL 3.4.18 in `vendor/` for this computer. Name targets to get others: `haxe --run Fetch windows android`. It checks each download's SHA-256, skips targets that already have this version (`--force` redoes them), and keeps the downloads in a per-user cache for other projects: `LINC_CACHE`, or `~/.cache/linc`, `~/Library/Caches/linc`, `%LOCALAPPDATA%\linc`. In a simple project, `haxelib run simple setup` runs it.

- `linux-x64`: SDL has no prebuilt Linux library, so this builds a static one into `vendor/linux-x64/`, from a fresh copy of the source with the patches in `patches/` applied. It needs CMake, `patch`, a C compiler, and the X11 or Wayland development headers (without them SDL builds with no way to open a window); Ninja is used when it's installed. The build stays in the cache, so other projects copy it instead of building again. A new or changed patch makes it build again.
- `windows`: SDL's prebuilt `SDL3.dll` and its import library for x64 and arm64, in `vendor/windows/`. hxcpp copies `SDL3.dll` next to the exe, which needs it at runtime.
- `android`: SDL's Android package, unpacked into `vendor/android/`: the headers, `libSDL3.so` for each CPU type, and `SDL3.jar` with SDL's Java classes. The app's APK needs both of the last two. On Android, SDL's Java code calls `SDL_main`, which `linc/linc_sdl3_android.cpp` forwards to hxcpp's `hxcpp_main`.

The patches, which only the Linux build applies; each patch file explains its change at the top:

- `patches/x11-slave-button-focus.patch`: on X11 with XInput2, a click on an unfocused window under a click-to-focus window manager reached SDL twice (the physical device's press, then the window manager's replay).

## Usage

```sh
haxelib dev linc_sdl3 path/to/linc_sdl3
```

```hxml
--library linc_sdl3
```

```haxe
import sdl3.SDL;

class Main {
	static function main() {
		SDL.init(SDL.INIT_VIDEO);
		var window = SDL.createWindow("Hello", 640, 480, SDL.WINDOW_OPENGL | SDL.WINDOW_RESIZABLE);
		var gl = SDL.glCreateContext(window);
		var event = new Event();
		var running = true;
		while (running) {
			while (SDL.pollEvent(event)) {
				if (event.type == EventType.Quit) {
					running = false;
				}
			}
			SDL.glSwapWindow(window);
		}
		SDL.glDestroyContext(gl);
		SDL.destroyWindow(window);
		SDL.quit();
	}
}
```

For a cppia host, compile the package in with `--macro include("sdl3", true)`. Build the host with `--dce no` as well, or scripts can fail to link standard library functions the host itself never calls.

## Notes

- The constants in `sdl3.SDL` are plain numbers and strings, so scripts can use them. `linc/linc_sdl3.h` checks each one against SDL's headers with `static_assert`.
- SDL3 sends text input events only between `SDL.startTextInput(window)` and `SDL.stopTextInput(window)`.
- Key events carry layout-dependent key codes that Shift doesn't change, as in SDL2.
- On Android, `SDL.init` turns off SDL's poll sentinel event. In SDL 3.4, each pass of the Android event wait pushes one, which wakes the wait straight away, so `SDL_WaitEventTimeout` keeps a CPU core busy until it times out.
