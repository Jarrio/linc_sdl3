package sdl3;

import haxe.io.BytesData;
import interop.Sdl;

typedef Size = {w:Int, h:Int};
typedef Area = {x:Int, y:Int, w:Int, h:Int};

/**
	A window handle. Scripts hold and pass it; only host code reads the pointer.

	The handles' pointers are set after construction: a constructor argument of a `cpp.PointerType` to
	an opaque C struct fails to compile, because the generated reflection constructor (`__Create`)
	converts it from Dynamic through a box that needs the full struct.
**/
class Window {
	@:allow(sdl3.SDL) var native:SDL_Window;

	@:allow(sdl3.SDL) public var id(default, null):Int;

	function new() {}
}

class GLContext {
	@:allow(sdl3.SDL) var native:SDL_GLContext;

	function new() {}
}

/** A 2D renderer, which simple uses when it can't get a GL context. **/
class Renderer {
	@:allow(sdl3.SDL) var native:SDL_Renderer;

	function new() {}
}

class Texture {
	@:allow(sdl3.SDL) var native:SDL_Texture;

	function new() {}
}

class Cursor {
	@:allow(sdl3.SDL) var native:SDL_Cursor;

	function new() {}
}

class DisplayMode {
	public var w:Int;
	public var h:Int;

	/** In Hz; 0 when the display doesn't say. **/
	public var refreshRate:Float;

	public var pixelDensity:Float;

	public function new() {}
}

enum abstract EventType(Int) from Int to Int {
	var Quit = 0x100;
	/** The system switched between light and dark; `getSystemTheme` says which. **/
	var SystemThemeChanged = 0x108;
	var WindowShown = 0x202;
	var WindowExposed = 0x204;
	var WindowResized = 0x206;
	var WindowPixelSizeChanged = 0x207;
	var WindowRestored = 0x20b;
	var WindowMouseEnter = 0x20c;
	var WindowMouseLeave = 0x20d;
	var WindowFocusGained = 0x20e;
	var WindowFocusLost = 0x20f;
	var WindowCloseRequested = 0x210;
	var WindowDisplayChanged = 0x213;
	var WindowDisplayScaleChanged = 0x214;
	var WindowSafeAreaChanged = 0x215;
	var KeyDown = 0x300;
	var KeyUp = 0x301;
	/** An input method's text being composed, not yet committed: `text`, with `editStart` and `editLength`. **/
	var TextEditing = 0x302;
	var TextInput = 0x303;
	/** The on-screen keyboard came up or went away. SDL sends these on Android, iOS, X11 and OpenVR. **/
	var ScreenKeyboardShown = 0x308;
	var ScreenKeyboardHidden = 0x309;
	var MouseMotion = 0x400;
	var MouseButtonDown = 0x401;
	var MouseButtonUp = 0x402;
	var MouseWheel = 0x403;
	var FingerDown = 0x700;
	/**
		The system took a touch over (Android's edge back gesture, palm rejection). SDL ends the mouse press it made
		from the touch with an ordinary button release, queued just before this.
	**/
	var FingerCanceled = 0x703;
	/** Ends each batch of events SDL pumps. It isn't input. **/
	var PollSentinel = 0x7f00;
	/** Sent by `SDL.pushUserEvent`. **/
	var User = 0x8000;
}

/**
	One event, filled in by `SDL.pollEvent` or `SDL.waitEventTimeout`. Fields the current type doesn't
	use keep their old values.
**/
class Event {
	public var type:EventType = 0;
	public var windowID:Int = 0;

	/** Key events: the key code (layout-dependent, unaffected by Shift), the scan code, and whether the key is held down or repeating. **/
	public var key:Int = 0;

	public var scancode:Int = 0;
	public var down:Bool = false;
	public var repeat:Bool = false;

	/** `TextInput`: the UTF-8 text typed. `TextEditing`: the text being composed, empty when the composition ends. **/
	public var text:String = null;

	/**
		`TextEditing`: the input method's cursor in `text` (in characters, -1 if it gave none) and the length of the
		part it marked, if any (-1 if none).
	**/
	public var editStart:Int = -1;

	public var editLength:Int = -1;

	/** Mouse events: the mouse that sent it. `TOUCH_MOUSE_ID` marks events SDL made from touches. **/
	public var which:Int = 0;

	/** Mouse events: the position in window units. For `MouseWheel`, where the pointer was. **/
	public var x:Float = 0;

	public var y:Float = 0;

	/** Mouse button events: the button and the clicks in a row (2 for a double click). **/
	public var button:Int = 0;

	public var clicks:Int = 0;

	/** `MouseWheel`: the scroll amount, fractional for touchpads. **/
	public var scrollX:Float = 0;

	public var scrollY:Float = 0;

	/** `MouseWheel`: the scroll amount in whole wheel steps, accumulated from fractional scrolling. **/
	public var wheelX:Int = 0;

	public var wheelY:Int = 0;

	/** `MouseWheel`: `WHEEL_NORMAL` (0), or flipped when the system inverts scrolling. **/
	public var direction:Int = 0;

	/** Window events: for `WindowResized` and `WindowPixelSizeChanged`, the new width and height. **/
	public var data1:Int = 0;

	public var data2:Int = 0;

	/** `User`: the code passed to `SDL.pushUserEvent`. **/
	public var code:Int = 0;

	public function new() {}
}

/**
	The SDL3 calls simple needs. Every function is a real static function, so a `-D scriptable` host
	compiles it and cppia scripts can call it. Constants are inline, so scripts get the values.
**/
class SDL {
	public static inline var INIT_VIDEO = 0x20;

	public static inline var WINDOW_OPENGL = 0x2;
	public static inline var WINDOW_HIDDEN = 0x8;
	public static inline var WINDOW_RESIZABLE = 0x20;
	public static inline var WINDOW_HIGH_PIXEL_DENSITY = 0x2000;

	public static inline var GL_RED_SIZE = 0;
	public static inline var GL_GREEN_SIZE = 1;
	public static inline var GL_BLUE_SIZE = 2;
	public static inline var GL_ALPHA_SIZE = 3;
	public static inline var GL_DOUBLEBUFFER = 5;
	public static inline var GL_STENCIL_SIZE = 7;
	public static inline var GL_CONTEXT_MAJOR_VERSION = 0x11;
	public static inline var GL_CONTEXT_MINOR_VERSION = 0x12;
	public static inline var GL_CONTEXT_PROFILE_MASK = 0x14;
	public static inline var GL_CONTEXT_PROFILE_ES = 0x4;

	public static inline var HINT_MOUSE_DOUBLE_CLICK_RADIUS = "SDL_MOUSE_DOUBLE_CLICK_RADIUS";
	public static inline var HINT_FRAMEBUFFER_ACCELERATION = "SDL_FRAMEBUFFER_ACCELERATION";
	public static inline var HINT_KEYCODE_OPTIONS = "SDL_KEYCODE_OPTIONS";
	public static inline var HINT_MOUSE_FOCUS_CLICKTHROUGH = "SDL_MOUSE_FOCUS_CLICKTHROUGH";
	/**
		The input method UI the app draws itself, set before `init`: "composition" when it draws the text being composed
		from `TextEditing` events (IBus and Fcitx then send it rather than showing it in their own window).
	**/
	public static inline var HINT_IME_IMPLEMENTED_UI = "SDL_IME_IMPLEMENTED_UI";

	public static inline var TOUCH_MOUSE_ID = -1;
	public static inline var PEN_MOUSE_ID = -2;
	public static inline var WHEEL_NORMAL = 0;

	public static inline var PIXELFORMAT_ARGB8888 = 0x16362004;
	public static inline var TEXTUREACCESS_STREAMING = 1;

	public static inline var BLENDMODE_NONE = 0;
	public static inline var BLENDMODE_BLEND = 1;

	public static inline var TEXTINPUT_TYPE_TEXT = 0;
	public static inline var TEXTINPUT_TYPE_TEXT_NAME = 1;
	public static inline var TEXTINPUT_TYPE_TEXT_EMAIL = 2;
	public static inline var TEXTINPUT_TYPE_TEXT_USERNAME = 3;
	public static inline var TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN = 4;
	public static inline var TEXTINPUT_TYPE_TEXT_PASSWORD_VISIBLE = 5;
	public static inline var TEXTINPUT_TYPE_NUMBER = 6;
	public static inline var TEXTINPUT_TYPE_NUMBER_PASSWORD_HIDDEN = 7;
	public static inline var TEXTINPUT_TYPE_NUMBER_PASSWORD_VISIBLE = 8;

	public static inline var CAPITALIZE_NONE = 0;
	public static inline var CAPITALIZE_SENTENCES = 1;
	public static inline var CAPITALIZE_WORDS = 2;
	public static inline var CAPITALIZE_LETTERS = 3;

	public static inline var SCALEMODE_NEAREST = 0;
	public static inline var SCALEMODE_LINEAR = 1;

	public static inline var SYSTEM_CURSOR_DEFAULT = 0;
	public static inline var SYSTEM_CURSOR_TEXT = 1;
	public static inline var SYSTEM_CURSOR_WAIT = 2;
	public static inline var SYSTEM_CURSOR_CROSSHAIR = 3;
	public static inline var SYSTEM_CURSOR_PROGRESS = 4;
	public static inline var SYSTEM_CURSOR_NWSE_RESIZE = 5;
	public static inline var SYSTEM_CURSOR_NESW_RESIZE = 6;
	public static inline var SYSTEM_CURSOR_EW_RESIZE = 7;
	public static inline var SYSTEM_CURSOR_NS_RESIZE = 8;
	public static inline var SYSTEM_CURSOR_MOVE = 9;
	public static inline var SYSTEM_CURSOR_NOT_ALLOWED = 10;
	public static inline var SYSTEM_CURSOR_POINTER = 11;

	public static inline var KEY_ESCAPE = 0x1b;

	public static inline var SYSTEM_THEME_UNKNOWN = 0;
	public static inline var SYSTEM_THEME_LIGHT = 1;
	public static inline var SYSTEM_THEME_DARK = 2;

	public static function init(flags:Int):Bool {
		if (!SDL_Native.SDL_Init(flags)) {
			return false;
		}
		#if android
		// SDL 3.4's Android event wait pushes a poll sentinel on every pass, and pushing any event wakes the
		// wait, so SDL_WaitEventTimeout spins a CPU core until it times out. Without sentinels it sleeps.
		SDL_Native.setEventEnabled(EventType.PollSentinel, false);
		#end
		return true;
	}

	public static function quit():Void {
		SDL_Native.SDL_Quit();
	}

	public static function getError():String {
		return cast(SDL_Native.SDL_GetError(), String);
	}

	/** The linked SDL version, e.g. "3.4.18". **/
	public static function getVersion():String {
		var v = SDL_Native.SDL_GetVersion();
		return '${Std.int(v / 1000000)}.${Std.int(v / 1000) % 1000}.${v % 1000}';
	}

	/**
		Whether the system is set to light or dark: one of the `SYSTEM_THEME_` constants, `SYSTEM_THEME_UNKNOWN` where
		the platform doesn't say (a Linux desktop whose portal has no preference). `SystemThemeChanged` comes when it
		changes. Needs the video subsystem.
	**/
	public static function getSystemTheme():Int {
		return cast SDL_Native.SDL_GetSystemTheme();
	}

	public static function getCurrentVideoDriver():String {
		var driver = cast SDL_Native.SDL_GetCurrentVideoDriver();
		return driver == null ? null : driver;
	}

	/** Milliseconds since `init`, as a Float so it crosses into cppia without a 64-bit type. **/
	public static function getTicks():Float {
		var ticks:Float = cast SDL_Native.SDL_GetTicks();
		return ticks;
	}

	/** `name` takes the `HINT_` constants. **/
	public static function setHint(name:String, value:String):Bool {
		return SDL_Native.SDL_SetHint(name, value);
	}

	// Windows

	/** `flags` takes the `WINDOW_` constants. Returns null on failure; see `getError`. **/
	public static function createWindow(title:String, width:Int, height:Int, flags:Int):Null<Window> {
		var native = SDL_Native.SDL_CreateWindow(title, width, height, flags);
		if (native == null) {
			return null;
		}
		var window = @:privateAccess new Window();
		window.native = native;
		window.id = SDL_Native.SDL_GetWindowID(native);
		return window;
	}

	public static function destroyWindow(window:Window):Void {
		SDL_Native.SDL_DestroyWindow(window.native);
	}

	public static function showWindow(window:Window):Bool {
		return SDL_Native.SDL_ShowWindow(window.native);
	}

	/** In window units. **/
	public static function setWindowSize(window:Window, width:Int, height:Int):Bool {
		return SDL_Native.SDL_SetWindowSize(window.native, width, height);
	}

	/** In window units, from the top-left of the desktop. **/
	public static function setWindowPosition(window:Window, x:Int, y:Int):Bool {
		return SDL_Native.SDL_SetWindowPosition(window.native, x, y);
	}

	/** Size in window units: points on macOS and iOS, pixels elsewhere. **/
	public static function getWindowSize(window:Window):Size {
		var w = 0, h = 0;
		SDL_Native.SDL_GetWindowSize(window.native, w, h);
		return {w: w, h: h};
	}

	/** Size of the drawable area in pixels. **/
	public static function getWindowSizeInPixels(window:Window):Size {
		var w = 0, h = 0;
		SDL_Native.SDL_GetWindowSizeInPixels(window.native, w, h);
		return {w: w, h: h};
	}

	/**
		How much to scale content in this window, in pixels per dp: the display's content scale (the
		user's 125% or 150%) times the pixel density. 2 on a Retina Mac, 1.5 for 150% on Windows.
	**/
	public static function getWindowDisplayScale(window:Window):Float {
		return SDL_Native.SDL_GetWindowDisplayScale(window.native);
	}

	/** Pixels per window unit: 2 on a Retina Mac, 1 where window units are pixels. **/
	public static function getWindowPixelDensity(window:Window):Float {
		return SDL_Native.SDL_GetWindowPixelDensity(window.native);
	}

	/** The part of the window not covered by notches, rounded corners or system bars, in window units. **/
	public static function getWindowSafeArea(window:Window):Area {
		var rect = new SDL_Rect();
		SDL_Native.SDL_GetWindowSafeArea(window.native, rect);
		return {x: rect.x, y: rect.y, w: rect.w, h: rect.h};
	}

	/** The display the window is mostly on, or 0 on failure. **/
	public static function getDisplayForWindow(window:Window):Int {
		return cast SDL_Native.SDL_GetDisplayForWindow(window.native);
	}

	/** Whether the point, in desktop coordinates, is on any connected display. **/
	public static function isPointOnDisplay(x:Int, y:Int):Bool {
		var point = new SDL_Point();
		point.x = x;
		point.y = y;
		var bounds = new SDL_Rect();
		var display = SDL_Native.SDL_GetDisplayForPoint(point);
		return display != 0 && SDL_Native.SDL_GetDisplayBounds(display, bounds);
	}

	/** The display's current mode, or null on failure. **/
	public static function getCurrentDisplayMode(display:Int):Null<DisplayMode> {
		var mode = new SDL_DisplayMode();
		mode = SDL_Native.SDL_GetCurrentDisplayMode(display);
		if(mode == null) {
			return null;
		}

		var display = new DisplayMode();
		display.h = mode.h;
		display.w = mode.w;
		display.refreshRate = mode.refresh_rate;
		display.pixelDensity = mode.pixel_density;
		return display;
	}

	// OpenGL

	/** `attr` takes the `GL_` constants. Call before creating the window. **/
	public static function glSetAttribute(attr:Int, value:Int):Bool {
		return SDL_Native.SDL_GL_SetAttribute(cast attr, value);
	}

	/** Creates the context and makes it current. Returns null on failure; see `getError`. **/
	public static function glCreateContext(window:Window):Null<GLContext> {
		var native = SDL_Native.SDL_GL_CreateContext(window.native);
		if (native == null) {
			return null;
		}
		var context = @:privateAccess new GLContext();
		context.native = native;
		return context;
	}

	public static function glDestroyContext(context:GLContext):Bool {
		return SDL_Native.SDL_GL_DestroyContext(context.native);
	}

	public static function glSetSwapInterval(interval:Int):Bool {
		return SDL_Native.SDL_GL_SetSwapInterval(interval);
	}

	public static function glSwapWindow(window:Window):Bool {
		return SDL_Native.SDL_GL_SwapWindow(window.native);
	}

	// Events

	/** Fills `event` with the next pending event. Returns false when there are none. **/
	public static function pollEvent(event:Event):Bool {
		var e = new SDL_Event();
		if (!SDL_Native.SDL_PollEvent(e)) {
			return false;
		}
		fillEvent(event, e);
		return true;
	}

	/** Waits up to `timeoutMs` for an event and fills `event` with it. Returns false on timeout. **/
	public static function waitEventTimeout(event:Event, timeoutMs:Int):Bool {
		var e = new SDL_Event();
		if (!SDL_Native.SDL_WaitEventTimeout(e, timeoutMs)) {
			return false;
		}
		fillEvent(event, e);
		return true;
	}

	/** Whether an event of `type` is waiting in the queue, without taking it out or pumping new ones. **/
	public static function hasEvent(type:EventType):Bool {
		return SDL_Native.SDL_HasEvent(type);
	}

	/** Queues a `User` event carrying `code`, which wakes `waitEventTimeout`. Safe from any thread. **/
	public static function pushUserEvent(code:Int):Bool {
		trace("This might not work.");
		var event = new SDL_Event();
		// SDL_zero is a define hence, no binding.
		// This might not work.
		// var e = cast cpp.RawPointer.addressOf(event);
		// SDL_Native.SDL_memset(cast(e, cpp.UInt32), 0, cpp.Stdlib.sizeof(SDL_Event));
		event.type = cast SDL_EVENT_USER;
		event.user.code = code;
		return SDL_Native.SDL_PushEvent(event);
	}

	// Inlined into the two functions above, so no generated wrapper has to pass a SDL_NativeEvent around.
	extern inline static function fillEvent(event:Event, e:SDL_Event):Void {
		event.type = cast e.type;
		switch (event.type) {
			case KeyDown | KeyUp:
				event.windowID = cast e.key.windowID;
				event.key = cast e.key.key;
				event.scancode = cast e.key.scancode;
				event.down = e.key.down;
				event.repeat = e.key.repeat;
			case TextInput:
				event.windowID = cast e.text.windowID;
				event.text = cast e.text.text;
			case TextEditing:
				event.windowID = cast e.edit.windowID;
				event.text = cast e.edit.text;
				event.editStart = e.edit.start;
				event.editLength = e.edit.length;
			case MouseMotion:
				event.windowID = cast e.motion.windowID;
				event.which = cast e.motion.which;
				event.x = e.motion.x;
				event.y = e.motion.y;
			case MouseButtonDown | MouseButtonUp:
				event.windowID = cast e.button.windowID;
				event.which = cast e.button.which;
				event.button = e.button.button;
				event.down = e.button.down;
				event.clicks = e.button.clicks;
				event.x = e.button.x;
				event.y = e.button.y;
			case MouseWheel:
				event.windowID = cast e.wheel.windowID;
				event.which = cast e.wheel.which;
				event.scrollX = e.wheel.x;
				event.scrollY = e.wheel.y;
				event.wheelX = e.wheel.integer_x;
				event.wheelY = e.wheel.integer_y;
				event.direction = cast e.wheel.direction;
				event.x = e.wheel.mouse_x;
				event.y = e.wheel.mouse_y;
			case User:
				event.code = e.user.code;
			case WindowShown | WindowExposed | WindowResized | WindowPixelSizeChanged | WindowRestored | WindowMouseEnter | WindowMouseLeave | WindowFocusGained | WindowFocusLost | WindowCloseRequested | WindowDisplayChanged | WindowDisplayScaleChanged | WindowSafeAreaChanged:
				event.windowID = cast e.window.windowID;
				event.data1 = e.window.data1;
				event.data2 = e.window.data2;
			case _:
		}
	}

	// Keyboard and clipboard

	/** Starts text input (and an on-screen keyboard or IME where there is one) for the window. Off until called. **/
	public static function startTextInput(window:Window):Bool {
		return SDL_Native.SDL_StartTextInput(window.native);
	}

	public static function stopTextInput(window:Window):Bool {
		return SDL_Native.SDL_StopTextInput(window.native);
	}

	inline static function defaultCapitalization(type:SDL_TextInputType) {
		switch(type) {
			case SDL_TEXTINPUT_TYPE_TEXT:
				return SDL_CAPITALIZE_SENTENCES;
			case SDL_TEXTINPUT_TYPE_TEXT_NAME:
				return SDL_CAPITALIZE_WORDS;
			default:
				return SDL_CAPITALIZE_NONE;
		}
	}

	/**
		`startTextInput` for a particular kind of text, which picks the on-screen keyboard: `type` takes the
		`TEXTINPUT_TYPE_` constants, `capitalization` the `CAPITALIZE_` ones (-1 for SDL's default for the type),
		`autocorrect` turns suggestions and corrections on, and `multiline` lets Return start a new line. SDL gives
		these to the keyboard when it shows it; one that's already up keeps the type it had (see `androidInputType`).
	**/
	public static function startTextInputWith(window:Window, type:Int, capitalization:Int, autocorrect:Bool, multiline:Bool):Bool {
		if (capitalization < 0) {
			capitalization = cast defaultCapitalization(cast type);
		}

		trace("Hey, if this causes issues refer: https://github.com/libsdl-org/SDL/blob/main/include/SDL3/SDL_keyboard.h#L496");
		var props = SDL_Native.SDL_CreateProperties();
		SDL_Native.SDL_SetNumberProperty(props, "SDL.textinput.type", type);
		SDL_Native.SDL_SetNumberProperty(props, "SDL.textinput.capitalization", capitalization);
		SDL_Native.SDL_SetBooleanProperty(props, "SDL.textinput.autocorrect", autocorrect);
		SDL_Native.SDL_SetBooleanProperty(props, "SDL.textinput.multiline", multiline);
		SDL_Native.SDL_SetNumberProperty(props, "SDL.textinput.android.inputtype", androidInputType(type, capitalization, autocorrect, multiline));
		var ok = SDL_Native.SDL_StartTextInputWithProperties(window.native, props);
		SDL_Native.SDL_DestroyProperties(props);
		return ok;
	}

	/**
		Where text is being entered, in window units, with the caret `cursor` window units from the area's left: input
		methods put their candidate window by it. On Android SDL moves its hidden text view there.
	**/
	public static function setTextInputArea(window:Window, x:Int, y:Int, w:Int, h:Int, cursor:Int):Bool {
		var rect = new SDL_Rect();
		rect.x = x;
		rect.y = y;
		rect.w = w;
		rect.h = h;
		return SDL_Native.SDL_SetTextInputArea(window.native, rect, cursor);
	}

	/** Whether the on-screen keyboard is showing for the window. **/
	public static function screenKeyboardShown(window:Window):Bool {
		return SDL_Native.SDL_ScreenKeyboardShown(window.native);
	}

	/** Drops the input method's composition (the `TextEditing` text) without committing it. **/
	public static function clearComposition(window:Window):Bool {
		return SDL_Native.SDL_ClearComposition(window.native);
	}

	/**
		The `android.text.InputType` that `startTextInputWith` gives Android's keyboard for these arguments; 0 off
		Android. An app that wants an open keyboard to change type passes it to SDLActivity's `showTextInput`.
	**/
	public static function androidInputType(type:Int, capitalization:Int, autocorrect:Bool, multiline:Bool):Int {
		var CLASS_TEXT = 0x1, CLASS_NUMBER = 0x2;
		var PERSON_NAME = 0x60, EMAIL = 0x20, PASSWORD = 0x80, VISIBLE_PASSWORD = 0x90, NUMBER_PASSWORD = 0x10;
		var t = 0;
		switch(cast(type, SDL_TextInputType)) {
			case SDL_TEXTINPUT_TYPE_TEXT_NAME: 
				t = CLASS_TEXT | PERSON_NAME; 
			case SDL_TEXTINPUT_TYPE_TEXT_EMAIL: 
				t = CLASS_TEXT | EMAIL; 
			case SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN: 
				t = CLASS_TEXT | PASSWORD; 
			case SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_VISIBLE: 
				t = CLASS_TEXT | VISIBLE_PASSWORD; 
			case SDL_TEXTINPUT_TYPE_NUMBER: 
				t = CLASS_NUMBER; 
			case SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_HIDDEN: 
				t = CLASS_NUMBER | NUMBER_PASSWORD; 
			case SDL_TEXTINPUT_TYPE_NUMBER_PASSWORD_VISIBLE: 
				t = CLASS_NUMBER; 
			default: 
				t = CLASS_TEXT; 
		}
		switch(cast(capitalization, SDL_Capitalization)) {
			case SDL_CAPITALIZE_LETTERS: 
				t |= 0x1000; 
			case SDL_CAPITALIZE_WORDS: 
				t |= 0x2000; 
			case SDL_CAPITALIZE_SENTENCES: 
				t |= 0x4000; 
			default: 
		}
		if (autocorrect) {
			t |= 0x8000 | 0x10000;
		}
		if (multiline) {
			t |= 0x20000;
		}
		return t;
	}

	/**
		Sends SDLActivity a command (0x8000 and up), which it hands to its `onUnhandledMessage` on the UI thread,
		with `param` as an Integer. False off Android.
	**/
	public static function sendAndroidMessage(command:Int, param:Int):Bool {
		#if __ANDROID__
		return SDL_Native.SDL_SendAndroidMessage(command,param);
		#else
		return false;
		#end
	}

	public static function setClipboardText(text:String):Bool {
		return SDL_Native.SDL_SetClipboardText(text);
	}

	public static function hasClipboardText():Bool {
		return SDL_Native.SDL_HasClipboardText();
	}

	/** The clipboard's text, or "" when there's none. **/
	public static function getClipboardText():String {
		return cast SDL_Native.SDL_GetClipboardText();
	}

	// Cursors

	/** `id` takes the `SYSTEM_CURSOR_` constants. Returns null on failure. **/
	public static function createSystemCursor(id:Int):Null<Cursor> {
		var native = SDL_Native.SDL_CreateSystemCursor(cast id);
		if (native == null) {
			return null;
		}
		var cursor = @:privateAccess new Cursor();
		cursor.native = native;
		return cursor;
	}

	/** Shows `cursor`. SDL doesn't take ownership: destroy the one it replaces when it's no longer shown. **/
	public static function setCursor(cursor:Cursor):Bool {
		return SDL_Native.SDL_SetCursor(cursor.native);
	}

	public static function destroyCursor(cursor:Cursor):Void {
		SDL_Native.SDL_DestroyCursor(cursor.native);
	}

	#if android
	/** The app's private files folder (Android's Context.getFilesDir()), or null on failure. **/
	public static function getAndroidInternalStoragePath():Null<String> {
		var path = SDL_Native.getAndroidInternalStoragePath();
		return path == null ? null : path.toString();
	}
	#end

	// 2D renderer

	/** Returns null on failure; see `getError`. **/
	public static function createRenderer(window:Window):Null<Renderer> {
		var native = SDL_Native.SDL_CreateRenderer(window.native, null);
		if (native == null) {
			return null;
		}
		var renderer = @:privateAccess new Renderer();
		renderer.native = native;
		return renderer;
	}

	public static function destroyRenderer(renderer:Renderer):Void {
		SDL_Native.SDL_DestroyRenderer(renderer.native);
	}

	/** 1 to present in step with the display, 0 for no vsync. **/
	public static function setRenderVSync(renderer:Renderer, vsync:Int):Bool {
		return SDL_Native.SDL_SetRenderVSync(renderer.native, vsync);
	}

	/** The renderer's output size in pixels. **/
	public static function getCurrentRenderOutputSize(renderer:Renderer):Size {
		var w = 0, h = 0;
		SDL_Native.SDL_GetCurrentRenderOutputSize(renderer.native, w, h);
		return {w: w, h: h};
	}

	/** `format` takes `PIXELFORMAT_ARGB8888`, `access` the `TEXTUREACCESS_` constants. Returns null on failure. **/
	public static function createTexture(renderer:Renderer, format:SDL_PixelFormat, access:SDL_TextureAccess, width:Int, height:Int):Null<Texture> { 
		var texture = @:privateAccess new Texture();
		texture.native = SDL_Native.SDL_CreateTexture(renderer.native, format, access, width, height);
		return texture;
	}

	public static function destroyTexture(texture:Texture):Void {
		SDL_Native.SDL_DestroyTexture(texture.native);
	}

	/**
		How the texture is drawn over what's under it: `BLENDMODE_NONE` or `BLENDMODE_BLEND`. A texture with an
		alpha channel starts as `BLENDMODE_BLEND` in SDL3 (SDL2 started with none).
	**/
	public static function setTextureBlendMode(texture:Texture, mode:Int):Bool {
		return SDL_Native.SDL_SetTextureBlendMode(texture.native, mode);
	}

	/** How the texture is sampled when drawn at another size: `SCALEMODE_NEAREST` or `SCALEMODE_LINEAR` (the default). **/
	public static function setTextureScaleMode(texture:Texture, mode:Int):Bool {
		return SDL_Native.SDL_SetTextureScaleMode(texture.native, cast mode);
	}

	/** Replaces the whole texture with `pixels`, `pitch` bytes per row. **/
	public static function updateTexture(texture:Texture, pixels:BytesData, pitch:Int):Bool {
		return SDL_Native.SDL_UpdateTexture(texture.native, null, pixels, pitch);
	}

	public static function renderClear(renderer:Renderer):Bool {
		return SDL_Native.SDL_RenderClear(renderer.native);
	}

	/** Draws the whole texture over the whole output. **/
	public static function renderTexture(renderer:Renderer, texture:Texture):Bool {
		return SDL_Native.SDL_RenderTexture(renderer.native, texture.native, null, null);
	}

	public static function renderPresent(renderer:Renderer):Bool {
		return SDL_Native.SDL_RenderPresent(renderer.native);
	}
}
