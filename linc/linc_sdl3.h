#pragma once

#ifndef HXCPP_H
#include <hxcpp.h>
#endif

#include <SDL3/SDL.h>

#include <deque>
#include <mutex>
#include <string>
#include <vector>

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

		// SDL_GetDisplayForPoint returns the closest display when the point is on none, so check its bounds too.
		inline bool isPointOnDisplay(int x, int y) {
			SDL_Point point = {x, y};
			SDL_Rect bounds;
			SDL_DisplayID display = SDL_GetDisplayForPoint(&point);
			return display != 0 && SDL_GetDisplayBounds(display, &bounds) && SDL_PointInRect(&point, &bounds);
		}

		// Wakes a thread blocked in SDL_WaitEvent(Timeout); safe to call from any thread.
		inline bool pushUserEvent(int code) {
			SDL_Event event;
			SDL_zero(event);
			event.type = SDL_EVENT_USER;
			event.user.code = code;
			return SDL_PushEvent(&event);
		}

		// A file dialog, from being shown to its answer being read. SDL may answer on a thread of its own, where Haxe
		// can't run, so the answer waits here and a user event tells the main thread. Filters must last until then.
		struct FileDialog {
			int id;
			int code;
			std::vector<std::string> filterText;
			std::vector<SDL_DialogFileFilter> filters;
			std::string location;
			std::vector<std::string> paths;
			bool failed = false;
			std::string error;
		};

		inline std::mutex fileDialogLock;
		inline std::deque<FileDialog *> answeredFileDialogs;
		inline FileDialog *readingFileDialog = nullptr;

		inline void SDLCALL fileDialogAnswered(void *userdata, const char *const *filelist, int filter) {
			FileDialog *dialog = (FileDialog *)userdata;
			if (filelist) {
				for (; *filelist; filelist++) {
					dialog->paths.push_back(*filelist);
				}
			} else {
				dialog->failed = true;
				dialog->error = SDL_GetError();
			}
			{
				std::lock_guard<std::mutex> lock(fileDialogLock);
				answeredFileDialogs.push_back(dialog);
			}
			pushUserEvent(dialog->code);
		}

		// `kind`: 0 open, 1 save, 2 folder. `filters`: each filter's name and pattern, a line each. An empty `location`
		// lets the system choose.
		inline void showFileDialog(int kind, int id, int code, SDL_Window *window, const char *filters, const char *location, bool many) {
			FileDialog *dialog = new FileDialog();
			dialog->id = id;
			dialog->code = code;
			dialog->location = location;
			const char *start = filters;
			while (*start) {
				const char *end = SDL_strchr(start, '\n');
				if (!end) {
					end = start + SDL_strlen(start);
				}
				dialog->filterText.emplace_back(start, end);
				start = *end ? end + 1 : end;
			}
			for (size_t i = 0; i + 1 < dialog->filterText.size(); i += 2) {
				dialog->filters.push_back({dialog->filterText[i].c_str(), dialog->filterText[i + 1].c_str()});
			}
			const SDL_DialogFileFilter *list = dialog->filters.empty() ? NULL : dialog->filters.data();
			int count = (int)dialog->filters.size();
			const char *from = dialog->location.empty() ? NULL : dialog->location.c_str();
			if (kind == 0) {
				SDL_ShowOpenFileDialog(fileDialogAnswered, dialog, window, list, count, from, many);
			} else if (kind == 1) {
				SDL_ShowSaveFileDialog(fileDialogAnswered, dialog, window, list, count, from);
			} else {
				SDL_ShowOpenFolderDialog(fileDialogAnswered, dialog, window, from, many);
			}
		}

		// Takes the next answer to read, and returns its dialog's id, or -1 for none. The one before it goes.
		inline int nextFileDialog() {
			delete readingFileDialog;
			readingFileDialog = nullptr;
			std::lock_guard<std::mutex> lock(fileDialogLock);
			if (answeredFileDialogs.empty()) {
				return -1;
			}
			readingFileDialog = answeredFileDialogs.front();
			answeredFileDialogs.pop_front();
			return readingFileDialog->id;
		}

		inline bool fileDialogFailed() {
			return readingFileDialog->failed;
		}

		inline const char *fileDialogError() {
			return readingFileDialog->error.c_str();
		}

		inline int fileDialogPathCount() {
			return (int)readingFileDialog->paths.size();
		}

		inline const char *fileDialogPath(int index) {
			return readingFileDialog->paths[index].c_str();
		}

		// A whole file's bytes, or null. SDL takes a path or, on Android, a content:// address. A slow file doesn't hold up
		// other threads' collections.
		inline ::Array<unsigned char> loadFile(const char *file) {
			std::string path(file);
			size_t size = 0;
			hx::EnterGCFreeZone();
			void *data = SDL_LoadFile(path.c_str(), &size);
			hx::ExitGCFreeZone();
			if (!data) {
				return null();
			}
			::Array<unsigned char> bytes = ::Array_obj<unsigned char>::__new((int)size, (int)size);
			if (size > 0) {
				SDL_memcpy(bytes->getBase(), data, size);
			}
			SDL_free(data);
			return bytes;
		}

		inline bool saveFile(const char *file, ::Array<unsigned char> bytes, int length) {
			std::string path(file);
			hx::EnterGCFreeZone();
			bool saved = SDL_SaveFile(path.c_str(), bytes->getBase(), (size_t)length);
			hx::ExitGCFreeZone();
			return saved;
		}

		// SDL3 hands back a copy the caller frees.
		inline ::String getClipboardText() {
			char *text = SDL_GetClipboardText();
			::String result = ::String::create(text);
			SDL_free(text);
			return result;
		}

		// What setClipboardTexts offers, each text under its MIME types. SDL asks for one when another app pastes
		// (or as it's set, on Windows), and drops it through clipboardTextsDone once something else is put there.
		struct ClipboardTexts {
			std::vector<std::string> types;
			std::vector<size_t> textOf;
			std::vector<std::string> texts;
		};

		inline const void *clipboardTextFor(void *userdata, const char *type, size_t *size) {
			ClipboardTexts *offered = (ClipboardTexts *)userdata;
			for (size_t i = 0; i < offered->types.size(); i++) {
				if (offered->types[i] == type) {
					const std::string &text = offered->texts[offered->textOf[i]];
					*size = text.size();
					return text.data();
				}
			}
			*size = 0;
			return nullptr;
		}

		inline void clipboardTextsDone(void *userdata) {
			delete (ClipboardTexts *)userdata;
		}

		// Puts `texts` on the clipboard at once, each under the MIME type at the same place in `types`. Plain text
		// ("text/plain;charset=utf-8") also goes under the other names the system knows text by, as SDL's own text does.
		inline bool setClipboardTexts(::Array<::String> types, ::Array<::String> texts) {
			#if defined(__APPLE__)
			static const char *const plainNames[] = {"text/plain;charset=utf-8"};
			#else
			static const char *const plainNames[] = {"text/plain;charset=utf-8", "UTF8_STRING", "text/plain", "TEXT", "STRING"};
			#endif
			ClipboardTexts *offered = new ClipboardTexts();
			for (int i = 0; i < types->length && i < texts->length; i++) {
				std::string type = types->__get(i).utf8_str();
				offered->texts.push_back(std::string(texts->__get(i).utf8_str()));
				if (type == "text/plain;charset=utf-8") {
					for (const char *name : plainNames) {
						offered->types.push_back(name);
						offered->textOf.push_back(offered->texts.size() - 1);
					}
				} else {
					offered->types.push_back(type);
					offered->textOf.push_back(offered->texts.size() - 1);
				}
			}
			std::vector<const char *> names;
			for (const std::string &type : offered->types) {
				names.push_back(type.c_str());
			}
			return SDL_SetClipboardData(clipboardTextFor, clipboardTextsDone, offered, names.data(), names.size());
		}

		// The clipboard's data of MIME type `type` as text, or null when there's none. UTF-8, or UTF-16 after a
		// byte order mark (Firefox has put HTML on the clipboard so).
		inline ::String getClipboardData(::String type) {
			size_t size = 0;
			void *data = SDL_GetClipboardData(type.utf8_str(), &size);
			if (!data) {
				return null();
			}
			const unsigned char *bytes = (const unsigned char *)data;
			std::string text;
			if (size >= 2 && ((bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
				bool little = bytes[0] == 0xFF;
				for (size_t i = 2; i + 1 < size; i += 2) {
					uint32_t c = little ? (bytes[i] | (bytes[i + 1] << 8)) : ((bytes[i] << 8) | bytes[i + 1]);
					if (c >= 0xD800 && c < 0xDC00 && i + 3 < size) {
						uint32_t low = little ? (bytes[i + 2] | (bytes[i + 3] << 8)) : ((bytes[i + 2] << 8) | bytes[i + 3]);
						if (low >= 0xDC00 && low < 0xE000) {
							c = 0x10000 + ((c - 0xD800) << 10) + (low - 0xDC00);
							i += 2;
						}
					}
					if (c < 0x80) {
						text += (char)c;
					} else if (c < 0x800) {
						text += (char)(0xC0 | (c >> 6));
						text += (char)(0x80 | (c & 0x3F));
					} else if (c < 0x10000) {
						text += (char)(0xE0 | (c >> 12));
						text += (char)(0x80 | ((c >> 6) & 0x3F));
						text += (char)(0x80 | (c & 0x3F));
					} else {
						text += (char)(0xF0 | (c >> 18));
						text += (char)(0x80 | ((c >> 12) & 0x3F));
						text += (char)(0x80 | ((c >> 6) & 0x3F));
						text += (char)(0x80 | (c & 0x3F));
					}
				}
			} else {
				text.assign((const char *)data, size);
			}
			SDL_free(data);
			return ::String::create(text.c_str(), (int)text.size());
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

		// Number pads SDL has no type for: Android's flags give them, and SDL hears its plain number type.
		const int TEXTINPUT_TYPE_NUMBER_DECIMAL = 100, TEXTINPUT_TYPE_NUMBER_SIGNED = 101, TEXTINPUT_TYPE_NUMBER_SIGNED_DECIMAL = 102;

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
				case TEXTINPUT_TYPE_NUMBER_DECIMAL: t = CLASS_NUMBER | 0x2000; break;
				case TEXTINPUT_TYPE_NUMBER_SIGNED: t = CLASS_NUMBER | 0x1000; break;
				case TEXTINPUT_TYPE_NUMBER_SIGNED_DECIMAL: t = CLASS_NUMBER | 0x3000; break;
				default: t = CLASS_TEXT; break;
			}
			switch (capitalization) {
				case SDL_CAPITALIZE_LETTERS: t |= 0x1000; break;
				case SDL_CAPITALIZE_WORDS: t |= 0x2000; break;
				case SDL_CAPITALIZE_SENTENCES: t |= 0x4000; break;
				default: break;
			}
			// TYPE_TEXT_FLAG_AUTO_CORRECT alone. SDL's own adds AUTO_COMPLETE, which says the app shows its own suggestions,
			// and a keyboard that takes it at its word, such as SwiftKey, hides its suggestion row.
			if (autocorrect) {
				t |= 0x8000;
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
		// The area of the window, in window units, where text is being entered, and the caret's offset in it.
		inline bool setTextInputArea(SDL_Window *window, int x, int y, int w, int h, int cursor) {
			SDL_Rect rect = {x, y, w, h};
			return SDL_SetTextInputArea(window, &rect, cursor);
		}

		inline bool startTextInputWith(SDL_Window *window, int type, int capitalization, bool autocorrect, bool multiline) {
			if (capitalization < 0) {
				capitalization = defaultCapitalization(type);
			}
			SDL_PropertiesID props = SDL_CreateProperties();
			SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_TYPE_NUMBER, type >= TEXTINPUT_TYPE_NUMBER_DECIMAL ? SDL_TEXTINPUT_TYPE_NUMBER : type);
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
static_assert(SDL_EVENT_TEXT_EDITING == 0x302, "EventType.TextEditing");
static_assert(SDL_EVENT_SCREEN_KEYBOARD_SHOWN == 0x308 && SDL_EVENT_SCREEN_KEYBOARD_HIDDEN == 0x309, "EventType screen keyboard");
static_assert(SDL_EVENT_MOUSE_MOTION == 0x400 && SDL_EVENT_MOUSE_BUTTON_DOWN == 0x401 && SDL_EVENT_MOUSE_BUTTON_UP == 0x402 && SDL_EVENT_MOUSE_WHEEL == 0x403, "EventType mouse");
static_assert(SDL_EVENT_FINGER_DOWN == 0x700 && SDL_EVENT_FINGER_UP == 0x701 && SDL_EVENT_FINGER_MOTION == 0x702, "EventType.Finger");
static_assert(SDL_EVENT_PINCH_BEGIN == 0x710 && SDL_EVENT_PINCH_UPDATE == 0x711 && SDL_EVENT_PINCH_END == 0x712, "EventType pinch");
static_assert(SDL_EVENT_DROP_FILE == 0x1000 && SDL_EVENT_DROP_TEXT == 0x1001 && SDL_EVENT_DROP_BEGIN == 0x1002, "EventType drop");
static_assert(SDL_EVENT_DROP_COMPLETE == 0x1003 && SDL_EVENT_DROP_POSITION == 0x1004, "EventType drop end");
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
static_assert(linc::sdl3::sameString(SDL_HINT_IME_IMPLEMENTED_UI, "SDL_IME_IMPLEMENTED_UI"), "SDL.HINT_IME_IMPLEMENTED_UI");
