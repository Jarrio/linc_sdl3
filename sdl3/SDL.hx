package sdl3;

import haxe.io.BytesData;
import sdl3.Native;

typedef Size = {w:Int, h:Int};
typedef Area = {x:Int, y:Int, w:Int, h:Int};

/**
	A window handle. Scripts hold and pass it; only host code reads the pointer.

	The handles' pointers are set after construction: a constructor argument of a `cpp.PointerType` to
	an opaque C struct fails to compile, because the generated reflection constructor (`__Create`)
	converts it from Dynamic through a box that needs the full struct.
**/
class Window {
	@:allow(sdl3.SDL) var native:NativeWindow;

	@:allow(sdl3.SDL) public var id(default, null):Int;

	function new() {}
}

class GLContext {
	@:allow(sdl3.SDL) var native:NativeGLContext;

	function new() {}
}

/** A 2D renderer, which simple uses when it can't get a GL context. **/
class Renderer {
	@:allow(sdl3.SDL) var native:NativeRenderer;

	function new() {}
}

class Texture {
	@:allow(sdl3.SDL) var native:NativeTexture;

	function new() {}
}

class Cursor {
	@:allow(sdl3.SDL) var native:NativeCursor;

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
	var TextInput = 0x303;
	var MouseMotion = 0x400;
	var MouseButtonDown = 0x401;
	var MouseButtonUp = 0x402;
	var MouseWheel = 0x403;
	var FingerDown = 0x700;
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

	/** `TextInput`: the UTF-8 text typed. **/
	public var text:String = null;

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

	public static inline var TOUCH_MOUSE_ID = -1;
	public static inline var PEN_MOUSE_ID = -2;
	public static inline var WHEEL_NORMAL = 0;

	public static inline var PIXELFORMAT_ARGB8888 = 0x16362004;
	public static inline var TEXTUREACCESS_STREAMING = 1;

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

	public static function init(flags:Int):Bool {
		return Native.init(flags);
	}

	public static function quit():Void {
		Native.quit();
	}

	public static function getError():String {
		return Native.getError().toString();
	}

	/** The linked SDL version, e.g. "3.4.18". **/
	public static function getVersion():String {
		var v = Native.getVersion();
		return '${Std.int(v / 1000000)}.${Std.int(v / 1000) % 1000}.${v % 1000}';
	}

	public static function getCurrentVideoDriver():String {
		var driver = Native.getCurrentVideoDriver();
		return driver == null ? null : driver.toString();
	}

	/** Milliseconds since `init`, as a Float so it crosses into cppia without a 64-bit type. **/
	public static function getTicks():Float {
		var ticks:Float = cast Native.getTicks();
		return ticks;
	}

	/** `name` takes the `HINT_` constants. **/
	public static function setHint(name:String, value:String):Bool {
		return Native.setHint(name, value);
	}

	// Windows

	/** `flags` takes the `WINDOW_` constants. Returns null on failure; see `getError`. **/
	public static function createWindow(title:String, width:Int, height:Int, flags:Int):Null<Window> {
		var native = Native.createWindow(title, width, height, flags);
		if (native == null) {
			return null;
		}
		var window = @:privateAccess new Window();
		window.native = native;
		window.id = Native.getWindowID(native);
		return window;
	}

	public static function destroyWindow(window:Window):Void {
		Native.destroyWindow(window.native);
	}

	public static function showWindow(window:Window):Bool {
		return Native.showWindow(window.native);
	}

	/** In window units. **/
	public static function setWindowSize(window:Window, width:Int, height:Int):Bool {
		return Native.setWindowSize(window.native, width, height);
	}

	/** In window units, from the top-left of the desktop. **/
	public static function setWindowPosition(window:Window, x:Int, y:Int):Bool {
		return Native.setWindowPosition(window.native, x, y);
	}

	/** Size in window units: points on macOS and iOS, pixels elsewhere. **/
	public static function getWindowSize(window:Window):Size {
		Native.getWindowSize(window.native);
		return {w: Native.outW, h: Native.outH};
	}

	/** Size of the drawable area in pixels. **/
	public static function getWindowSizeInPixels(window:Window):Size {
		Native.getWindowSizeInPixels(window.native);
		return {w: Native.outW, h: Native.outH};
	}

	/**
		How much to scale content in this window, in pixels per dp: the display's content scale (the
		user's 125% or 150%) times the pixel density. 2 on a Retina Mac, 1.5 for 150% on Windows.
	**/
	public static function getWindowDisplayScale(window:Window):Float {
		return Native.getWindowDisplayScale(window.native);
	}

	/** Pixels per window unit: 2 on a Retina Mac, 1 where window units are pixels. **/
	public static function getWindowPixelDensity(window:Window):Float {
		return Native.getWindowPixelDensity(window.native);
	}

	/** The part of the window not covered by notches, rounded corners or system bars, in window units. **/
	public static function getWindowSafeArea(window:Window):Area {
		var rect = new NativeRect();
		Native.getWindowSafeArea(window.native, rect);
		return {x: rect.x, y: rect.y, w: rect.w, h: rect.h};
	}

	/** The display the window is mostly on, or 0 on failure. **/
	public static function getDisplayForWindow(window:Window):Int {
		return cast Native.getDisplayForWindow(window.native);
	}

	/** The display's current mode, or null on failure. **/
	public static function getCurrentDisplayMode(display:Int):Null<DisplayMode> {
		if (!Native.getCurrentDisplayMode(display)) {
			return null;
		}
		var mode = new DisplayMode();
		mode.w = Native.outW;
		mode.h = Native.outH;
		mode.refreshRate = Native.outRefreshRate;
		mode.pixelDensity = Native.outPixelDensity;
		return mode;
	}

	// OpenGL

	/** `attr` takes the `GL_` constants. Call before creating the window. **/
	public static function glSetAttribute(attr:Int, value:Int):Bool {
		return Native.glSetAttribute(cast attr, value);
	}

	/** Creates the context and makes it current. Returns null on failure; see `getError`. **/
	public static function glCreateContext(window:Window):Null<GLContext> {
		var native = Native.glCreateContext(window.native);
		if (native == null) {
			return null;
		}
		var context = @:privateAccess new GLContext();
		context.native = native;
		return context;
	}

	public static function glDestroyContext(context:GLContext):Bool {
		return Native.glDestroyContext(context.native);
	}

	public static function glSetSwapInterval(interval:Int):Bool {
		return Native.glSetSwapInterval(interval);
	}

	public static function glSwapWindow(window:Window):Bool {
		return Native.glSwapWindow(window.native);
	}

	// Events

	/** Fills `event` with the next pending event. Returns false when there are none. **/
	public static function pollEvent(event:Event):Bool {
		var e = new NativeEvent();
		if (!Native.pollEvent(e)) {
			return false;
		}
		fillEvent(event, e);
		return true;
	}

	/** Waits up to `timeoutMs` for an event and fills `event` with it. Returns false on timeout. **/
	public static function waitEventTimeout(event:Event, timeoutMs:Int):Bool {
		var e = new NativeEvent();
		if (!Native.waitEventTimeout(e, timeoutMs)) {
			return false;
		}
		fillEvent(event, e);
		return true;
	}

	/** Queues a `User` event carrying `code`, which wakes `waitEventTimeout`. Safe from any thread. **/
	public static function pushUserEvent(code:Int):Bool {
		return Native.pushUserEvent(code);
	}

	// Inlined into the two functions above, so no generated wrapper has to pass a NativeEvent around.
	extern inline static function fillEvent(event:Event, e:NativeEvent):Void {
		event.type = cast e.type;
		switch (event.type) {
			case KeyDown | KeyUp:
				event.windowID = cast e.key.windowID;
				event.key = cast e.key.key;
				event.scancode = e.key.scancode;
				event.down = e.key.down;
				event.repeat = e.key.repeat;
			case TextInput:
				event.windowID = cast e.text.windowID;
				event.text = e.text.text.toString();
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
				event.direction = e.wheel.direction;
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
		return Native.startTextInput(window.native);
	}

	public static function stopTextInput(window:Window):Bool {
		return Native.stopTextInput(window.native);
	}

	public static function setClipboardText(text:String):Bool {
		return Native.setClipboardText(text);
	}

	public static function hasClipboardText():Bool {
		return Native.hasClipboardText();
	}

	/** The clipboard's text, or "" when there's none. **/
	public static function getClipboardText():String {
		return Native.getClipboardText();
	}

	// Cursors

	/** `id` takes the `SYSTEM_CURSOR_` constants. Returns null on failure. **/
	public static function createSystemCursor(id:Int):Null<Cursor> {
		var native = Native.createSystemCursor(id);
		if (native == null) {
			return null;
		}
		var cursor = @:privateAccess new Cursor();
		cursor.native = native;
		return cursor;
	}

	/** Shows `cursor`. SDL doesn't take ownership: destroy the one it replaces when it's no longer shown. **/
	public static function setCursor(cursor:Cursor):Bool {
		return Native.setCursor(cursor.native);
	}

	public static function destroyCursor(cursor:Cursor):Void {
		Native.destroyCursor(cursor.native);
	}

	// 2D renderer

	/** Returns null on failure; see `getError`. **/
	public static function createRenderer(window:Window):Null<Renderer> {
		var native = Native.createRenderer(window.native);
		if (native == null) {
			return null;
		}
		var renderer = @:privateAccess new Renderer();
		renderer.native = native;
		return renderer;
	}

	public static function destroyRenderer(renderer:Renderer):Void {
		Native.destroyRenderer(renderer.native);
	}

	/** 1 to present in step with the display, 0 for no vsync. **/
	public static function setRenderVSync(renderer:Renderer, vsync:Int):Bool {
		return Native.setRenderVSync(renderer.native, vsync);
	}

	/** The renderer's output size in pixels. **/
	public static function getCurrentRenderOutputSize(renderer:Renderer):Size {
		Native.getCurrentRenderOutputSize(renderer.native);
		return {w: Native.outW, h: Native.outH};
	}

	/** `format` takes `PIXELFORMAT_ARGB8888`, `access` the `TEXTUREACCESS_` constants. Returns null on failure. **/
	public static function createTexture(renderer:Renderer, format:Int, access:Int, width:Int, height:Int):Null<Texture> {
		var native = Native.createTexture(renderer.native, format, access, width, height);
		if (native == null) {
			return null;
		}
		var texture = @:privateAccess new Texture();
		texture.native = native;
		return texture;
	}

	public static function destroyTexture(texture:Texture):Void {
		Native.destroyTexture(texture.native);
	}

	/** Replaces the whole texture with `pixels`, `pitch` bytes per row. **/
	public static function updateTexture(texture:Texture, pixels:BytesData, pitch:Int):Bool {
		return Native.updateTexture(texture.native, pixels, pitch);
	}

	public static function renderClear(renderer:Renderer):Bool {
		return Native.renderClear(renderer.native);
	}

	/** Draws the whole texture over the whole output. **/
	public static function renderTexture(renderer:Renderer, texture:Texture):Bool {
		return Native.renderTexture(renderer.native, texture.native);
	}

	public static function renderPresent(renderer:Renderer):Bool {
		return Native.renderPresent(renderer.native);
	}
}
