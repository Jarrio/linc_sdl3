// SDL's Java side (SDLActivity) starts the app by looking up SDL_main in libmain.so and running it
// through SDL_RunApp. hxcpp's Android build exports hxcpp_main instead, which starts Haxe's runtime
// every time it runs; this does what it does, but starts the runtime only once (linc_sdl3_start_haxe).
#include <hxcpp.h>
#include <android/log.h>
#include <mutex>

extern "C" void __hxcpp_main();
void __boot_all();

// Makes the calling thread known to Haxe's collector, with `top` its outermost Haxe stack frame, and starts Haxe's
// runtime (hx::Boot, and the classes' statics) if no thread has yet: SDL_main's, unless Haxe code ran before the window
// opened (simple's work while the app is closed starts the app without its window, and calls this). One thread at a
// time, waiting before it's known to the collector: a thread that waited after would hold up a collection during
// another's start, which waits for every thread it knows.
extern "C" __attribute__((visibility("default"))) void linc_sdl3_start_haxe(int *top) {
	static std::mutex starting;
	static bool started = false;
	std::lock_guard<std::mutex> lock(starting);
	hx::SetTopOfStack(top, false);
	if (!started) {
		hx::Boot();
		__boot_all();
		started = true;
	}
}

extern "C" __attribute__((visibility("default"))) int SDL_main(int argc, char *argv[]) {
	int top = 0;
	linc_sdl3_start_haxe(&top);
	try {
		__hxcpp_main();
	} catch (Dynamic e) {
		__hx_dump_stack();
		__android_log_print(ANDROID_LOG_ERROR, "Exception", "%s", e == null() ? "null" : e->toString().__CStr());
	}
	hx::SetTopOfStack((int *)0, true);
	return 0;
}
