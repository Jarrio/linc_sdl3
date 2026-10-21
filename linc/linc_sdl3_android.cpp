// SDL's Java side (SDLActivity) starts the app by looking up SDL_main in libmain.so and running it
// through SDL_RunApp. hxcpp's Android build exports hxcpp_main instead, so this forwards to it.
#include <hxcpp.h>

extern "C" void hxcpp_main();

extern "C" __attribute__((visibility("default"))) int SDL_main(int argc, char *argv[]) {
	hxcpp_main();
	return 0;
}
