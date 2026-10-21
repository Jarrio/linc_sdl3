#pragma once

#ifndef HXCPP_H
#include <hxcpp.h>
#endif

#include <SDL3/SDL.h>

namespace linc {
	namespace sdl3 {
		// SDL reports sizes through int pointers. The Haxe side reads them back as extern vars rather
		// than passing a local by address, which the analyzer can't see writes through. SDL's window
		// and render calls run on the main thread only, so one set is enough.
		inline int outW = 0;
		inline int outH = 0;
		inline float outRefreshRate = 0;
		inline float outPixelDensity = 0;

		inline bool getWindowSize(SDL_Window *window) {
			return SDL_GetWindowSize(window, &outW, &outH);
		}

		inline bool getWindowSizeInPixels(SDL_Window *window) {
			return SDL_GetWindowSizeInPixels(window, &outW, &outH);
		}

		inline bool getCurrentRenderOutputSize(SDL_Renderer *renderer) {
			return SDL_GetCurrentRenderOutputSize(renderer, &outW, &outH);
		}

		inline bool getCurrentDisplayMode(SDL_DisplayID display) {
			const SDL_DisplayMode *mode = SDL_GetCurrentDisplayMode(display);
			if (!mode) {
				return false;
			}
			outW = mode->w;
			outH = mode->h;
			outRefreshRate = mode->refresh_rate;
			outPixelDensity = mode->pixel_density;
			return true;
		}

		// Wakes a thread blocked in SDL_WaitEvent(Timeout); safe to call from any thread.
		inline bool pushUserEvent(int code) {
			SDL_Event event;
			SDL_zero(event);
			event.type = SDL_EVENT_USER;
			event.user.code = code;
			return SDL_PushEvent(&event);
		}

		// SDL3 hands back a copy the caller frees.
		inline ::String getClipboardText() {
			char *text = SDL_GetClipboardText();
			::String result = ::String::create(text);
			SDL_free(text);
			return result;
		}

		// SDL_SystemCursor, SDL_PixelFormat and SDL_TextureAccess are enums, and C++ won't convert the ints
		// Haxe passes into them implicitly.
		inline SDL_Cursor *createSystemCursor(int id) {
			return SDL_CreateSystemCursor((SDL_SystemCursor)id);
		}

		inline SDL_Renderer *createRenderer(SDL_Window *window) {
			return SDL_CreateRenderer(window, NULL);
		}

		inline SDL_Texture *createTexture(SDL_Renderer *renderer, int format, int access, int width, int height) {
			return SDL_CreateTexture(renderer, (SDL_PixelFormat)format, (SDL_TextureAccess)access, width, height);
		}

		inline bool setTextureScaleMode(SDL_Texture *texture, int mode) {
			return SDL_SetTextureScaleMode(texture, (SDL_ScaleMode)mode);
		}

		inline bool updateTexture(SDL_Texture *texture, ::Array<unsigned char> pixels, int pitch) {
			return SDL_UpdateTexture(texture, NULL, pixels->getBase(), pitch);
		}

		inline bool renderTexture(SDL_Renderer *renderer, SDL_Texture *texture) {
			return SDL_RenderTexture(renderer, texture, NULL, NULL);
		}

		// SDL's capitalization when none is given: sentences for text, words for names, none for the rest.
		inline int defaultCapitalization(int type) {
			switch (type) {
				case SDL_TEXTINPUT_TYPE_TEXT: return SDL_CAPITALIZE_SENTENCES;
				case SDL_TEXTINPUT_TYPE_TEXT_NAME: return SDL_CAPITALIZE_WORDS;
				default: return SDL_CAPITALIZE_NONE;
			}
		}

		#ifdef __ANDROID__
		// android.text.InputType for the properties, as SDL's Android_ShowScreenKeyboard works it out.
		inline int androidInputType(int type, int capitalization, bool autocorrect, bool multiline) {
			const int CLASS_TEXT = 0x1, CLASS_NUMBER = 0x2;
			const int PERSON_NAME = 0x60, EMAIL = 0x20, PASSWORD = 0x80, VISIBLE_PASSWORD = 0x90, NUMBER_PASSWORD = 0x10;
			int t;
			switch (type) {
				case SDL_TEXTINPUT_TYPE_TEXT_NAME: t = CLASS_TEXT | PERSON_NAME; break;
				case SDL_TEXTINPUT_TYPE_TEXT_EMAIL: t = CLASS_TEXT | EMAIL; break;
				case SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN: t = CLASS_TEXT | PASSWORD; break;
				case SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_VISIBLE: t = CLASS_TEXT | VISIBLE_PASSWORD; break;
				case SDL_TEXTINPUT_TYPE_NUMBER: t = CLASS_NUMBER; break;
				case SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_HIDDEN: t = CLASS_NUMBER | NUMBER_PASSWORD; break;
				case SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_VISIBLE: t = CLASS_NUMBER; break;
				default: t = CLASS_TEXT; break;
			}
			switch (capitalization) {
				case SDL_CAPITALIZE_LETTERS: t |= 0x1000; break;
				case SDL_CAPITALIZE_WORDS: t |= 0x2000; break;
				case SDL_CAPITALIZE_SENTENCES: t |= 0x4000; break;
				default: break;
			}
			if (autocorrect) {
				t |= 0x8000 | 0x10000;
			}
			if (multiline) {
				t |= 0x20000;
			}
			return t;
		}

		#endif

		// SDL_StartTextInputWithProperties with the properties as arguments; capitalization < 0 for SDL's default.
		// On Android the type also goes as Android's own (androidInputType), the number an app gives SDL's
		// SDLActivity.showTextInput to change an open keyboard, which SDL itself doesn't do.
		inline bool startTextInputWith(SDL_Window *window, int type, int capitalization, bool autocorrect, bool multiline) {
			if (capitalization < 0) {
				capitalization = defaultCapitalization(type);
			}
			SDL_PropertiesID props = SDL_CreateProperties();
			SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_TYPE_NUMBER, type);
			SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_CAPITALIZATION_NUMBER, capitalization);
			SDL_SetBooleanProperty(props, SDL_PROP_TEXTINPUT_AUTOCORRECT_BOOLEAN, autocorrect);
			SDL_SetBooleanProperty(props, SDL_PROP_TEXTINPUT_MULTILINE_BOOLEAN, multiline);
			#ifdef __ANDROID__
			SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_ANDROID_INPUTTYPE_NUMBER, androidInputType(type, capitalization, autocorrect, multiline));
			#endif
			bool ok = SDL_StartTextInputWithProperties(window, props);
			SDL_DestroyProperties(props);
			return ok;
		}

		// androidInputType with SDL's default capitalization for capitalization < 0; 0 off Android.
		inline int androidInputTypeFor(int type, int capitalization, bool autocorrect, bool multiline) {
			#ifdef __ANDROID__
			return androidInputType(type, capitalization < 0 ? defaultCapitalization(type) : capitalization, autocorrect, multiline);
			#else
			return 0;
			#endif
		}

		inline bool sendAndroidMessage(int command, int param) {
			#ifdef __ANDROID__
			return SDL_SendAndroidMessage((Uint32)command, param);
			#else
			return false;
			#endif
		}

		constexpr bool sameString(const char *a, const char *b) {
			return *a == *b && (*a == 0 || sameString(a + 1, b + 1));
		}
	}
}

// sdl3/SDL.hx mirrors these as inline constants so cppia scripts can use them; fail the build if
// they drift from the headers.
static_assert(SDL_INIT_VIDEO == 0x20, "SDL.INIT_VIDEO");
static_assert(SDL_WINDOW_OPENGL == 0x2, "SDL.WINDOW_OPENGL");
static_assert(SDL_WINDOW_HIDDEN == 0x8, "SDL.WINDOW_HIDDEN");
static_assert(SDL_WINDOW_RESIZABLE == 0x20, "SDL.WINDOW_RESIZABLE");
static_assert(SDL_WINDOW_HIGH_PIXEL_DENSITY == 0x2000, "SDL.WINDOW_HIGH_PIXEL_DENSITY");
static_assert(SDL_GL_RED_SIZE == 0 && SDL_GL_GREEN_SIZE == 1 && SDL_GL_BLUE_SIZE == 2 && SDL_GL_ALPHA_SIZE == 3, "GLAttr colour sizes");
static_assert(SDL_GL_DOUBLEBUFFER == 5 && SDL_GL_STENCIL_SIZE == 7, "GLAttr buffers");
static_assert(SDL_GL_CONTEXT_MAJOR_VERSION == 0x11 && SDL_GL_CONTEXT_MINOR_VERSION == 0x12 && SDL_GL_CONTEXT_PROFILE_MASK == 0x14, "GLAttr context");
static_assert(SDL_GL_CONTEXT_PROFILE_CORE == 1 && SDL_GL_CONTEXT_PROFILE_COMPATIBILITY == 2 && SDL_GL_CONTEXT_PROFILE_ES == 4, "GLProfile");
static_assert(SDL_EVENT_QUIT == 0x100, "EventType.Quit");
static_assert(SDL_EVENT_WINDOW_SHOWN == 0x202 && SDL_EVENT_WINDOW_EXPOSED == 0x204 && SDL_EVENT_WINDOW_RESTORED == 0x20b, "EventType window shown");
static_assert(SDL_EVENT_WINDOW_RESIZED == 0x206 && SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED == 0x207, "EventType window size");
static_assert(SDL_EVENT_WINDOW_MOUSE_ENTER == 0x20c && SDL_EVENT_WINDOW_MOUSE_LEAVE == 0x20d, "EventType window mouse");
static_assert(SDL_EVENT_WINDOW_FOCUS_GAINED == 0x20e && SDL_EVENT_WINDOW_FOCUS_LOST == 0x20f, "EventType window focus");
static_assert(SDL_EVENT_WINDOW_CLOSE_REQUESTED == 0x210, "EventType.WindowCloseRequested");
static_assert(SDL_EVENT_WINDOW_DISPLAY_CHANGED == 0x213, "EventType.WindowDisplayChanged");
static_assert(SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED == 0x214 && SDL_EVENT_WINDOW_SAFE_AREA_CHANGED == 0x215, "EventType window scale");
static_assert(SDL_EVENT_KEY_DOWN == 0x300 && SDL_EVENT_KEY_UP == 0x301 && SDL_EVENT_TEXT_INPUT == 0x303, "EventType keyboard");
static_assert(SDL_EVENT_MOUSE_MOTION == 0x400 && SDL_EVENT_MOUSE_BUTTON_DOWN == 0x401 && SDL_EVENT_MOUSE_BUTTON_UP == 0x402 && SDL_EVENT_MOUSE_WHEEL == 0x403, "EventType mouse");
static_assert(SDL_EVENT_FINGER_DOWN == 0x700, "EventType.FingerDown");
static_assert(SDL_EVENT_POLL_SENTINEL == 0x7f00 && SDL_EVENT_USER == 0x8000, "EventType sentinel and user");
static_assert(SDLK_ESCAPE == 0x1b, "SDL.KEY_ESCAPE");
static_assert((Sint32)SDL_TOUCH_MOUSEID == -1 && (Sint32)SDL_PEN_MOUSEID == -2, "SDL.TOUCH_MOUSE_ID / PEN_MOUSE_ID");
static_assert(SDL_MOUSEWHEEL_NORMAL == 0, "SDL.WHEEL_NORMAL");
static_assert(SDL_PIXELFORMAT_ARGB8888 == 0x16362004, "SDL.PIXELFORMAT_ARGB8888");
static_assert(SDL_TEXTUREACCESS_STREAMING == 1, "SDL.TEXTUREACCESS_STREAMING");
static_assert(SDL_BLENDMODE_NONE == 0 && SDL_BLENDMODE_BLEND == 1, "SDL.BLENDMODE_");
static_assert(SDL_TEXTINPUT_TYPE_TEXT == 0 && SDL_TEXTINPUT_TYPE_TEXT_NAME == 1 && SDL_TEXTINPUT_TYPE_TEXT_EMAIL == 2 && SDL_TEXTINPUT_TYPE_TEXT_USERNAME == 3, "SDL.TEXTINPUT_TYPE_ 0-3");
static_assert(SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN == 4 && SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_VISIBLE == 5 && SDL_TEXTINPUT_TYPE_NUMBER == 6, "SDL.TEXTINPUT_TYPE_ 4-6");
static_assert(SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_HIDDEN == 7 && SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_VISIBLE == 8, "SDL.TEXTINPUT_TYPE_ 7-8");
static_assert(SDL_CAPITALIZE_NONE == 0 && SDL_CAPITALIZE_SENTENCES == 1 && SDL_CAPITALIZE_WORDS == 2 && SDL_CAPITALIZE_LETTERS == 3, "SDL.CAPITALIZE_");
static_assert(SDL_SCALEMODE_NEAREST == 0 && SDL_SCALEMODE_LINEAR == 1, "SDL.SCALEMODE_");
static_assert(SDL_SYSTEM_CURSOR_DEFAULT == 0 && SDL_SYSTEM_CURSOR_TEXT == 1 && SDL_SYSTEM_CURSOR_WAIT == 2 && SDL_SYSTEM_CURSOR_CROSSHAIR == 3, "SDL.SYSTEM_CURSOR_ 0-3");
static_assert(SDL_SYSTEM_CURSOR_PROGRESS == 4 && SDL_SYSTEM_CURSOR_NWSE_RESIZE == 5 && SDL_SYSTEM_CURSOR_NESW_RESIZE == 6 && SDL_SYSTEM_CURSOR_EW_RESIZE == 7, "SDL.SYSTEM_CURSOR_ 4-7");
static_assert(SDL_SYSTEM_CURSOR_NS_RESIZE == 8 && SDL_SYSTEM_CURSOR_MOVE == 9 && SDL_SYSTEM_CURSOR_NOT_ALLOWED == 10 && SDL_SYSTEM_CURSOR_POINTER == 11, "SDL.SYSTEM_CURSOR_ 8-11");
static_assert(linc::sdl3::sameString(SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS, "SDL_MOUSE_DOUBLE_CLICK_RADIUS"), "SDL.HINT_MOUSE_DOUBLE_CLICK_RADIUS");
static_assert(linc::sdl3::sameString(SDL_HINT_FRAMEBUFFER_ACCELERATION, "SDL_FRAMEBUFFER_ACCELERATION"), "SDL.HINT_FRAMEBUFFER_ACCELERATION");
static_assert(linc::sdl3::sameString(SDL_HINT_KEYCODE_OPTIONS, "SDL_KEYCODE_OPTIONS"), "SDL.HINT_KEYCODE_OPTIONS");
static_assert(linc::sdl3::sameString(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "SDL_MOUSE_FOCUS_CLICKTHROUGH"), "SDL.HINT_MOUSE_FOCUS_CLICKTHROUGH");
