package sdl3;

import cpp.ConstCharStar;
import cpp.Float32;
import cpp.UInt8;
import cpp.UInt32;
import cpp.UInt64;
import haxe.io.BytesData;

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.PointerType({type: "SDL_Window"})
extern class NativeWindow {}

/** SDL3's `SDL_GLContext` is a pointer to this opaque struct. **/
@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.PointerType({type: "SDL_GLContextState"})
extern class NativeGLContext {}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.PointerType({type: "SDL_Renderer"})
extern class NativeRenderer {}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.PointerType({type: "SDL_Texture"})
extern class NativeTexture {}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.PointerType({type: "SDL_Cursor"})
extern class NativeCursor {}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_Rect"})
extern class NativeRect {
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;

	function new();
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_KeyboardEvent"})
extern class NativeKeyboardEvent {
	var windowID:UInt32;
	var scancode:Int;
	var key:UInt32;
	var down:Bool;
	var repeat:Bool;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_TextInputEvent"})
extern class NativeTextInputEvent {
	var windowID:UInt32;
	var text:ConstCharStar;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_TextEditingEvent"})
extern class NativeTextEditingEvent {
	var windowID:UInt32;
	var text:ConstCharStar;
	var start:Int;
	var length:Int;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_MouseMotionEvent"})
extern class NativeMouseMotionEvent {
	var windowID:UInt32;
	var which:UInt32;
	var x:Float32;
	var y:Float32;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_MouseButtonEvent"})
extern class NativeMouseButtonEvent {
	var windowID:UInt32;
	var which:UInt32;
	var button:UInt8;
	var down:Bool;
	var clicks:UInt8;
	var x:Float32;
	var y:Float32;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_MouseWheelEvent"})
extern class NativeMouseWheelEvent {
	var windowID:UInt32;
	var which:UInt32;
	var x:Float32;
	var y:Float32;
	var direction:Int;
	var mouse_x:Float32;
	var mouse_y:Float32;
	var integer_x:Int;
	var integer_y:Int;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_UserEvent"})
extern class NativeUserEvent {
	var code:Int;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_WindowEvent"})
extern class NativeWindowEvent {
	var windowID:UInt32;
	var data1:Int;
	var data2:Int;
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_Event"})
extern class NativeEvent {
	var type:UInt32;
	var key:NativeKeyboardEvent;
	var text:NativeTextInputEvent;
	var edit:NativeTextEditingEvent;
	var motion:NativeMouseMotionEvent;
	var button:NativeMouseButtonEvent;
	var wheel:NativeMouseWheelEvent;
	var window:NativeWindowEvent;
	var user:NativeUserEvent;

	function new();
}

@:semantics(value)
@:include("linc_sdl3.h")
@:cpp.ValueType({type: "SDL_GLAttr"})
extern enum abstract NativeGLAttr(Int) {
	@:native("SDL_GL_RED_SIZE") var RedSize;
	@:native("SDL_GL_GREEN_SIZE") var GreenSize;
	@:native("SDL_GL_BLUE_SIZE") var BlueSize;
	@:native("SDL_GL_ALPHA_SIZE") var AlphaSize;
	@:native("SDL_GL_DOUBLEBUFFER") var DoubleBuffer;
	@:native("SDL_GL_STENCIL_SIZE") var StencilSize;
	@:native("SDL_GL_CONTEXT_MAJOR_VERSION") var ContextMajorVersion;
	@:native("SDL_GL_CONTEXT_MINOR_VERSION") var ContextMinorVersion;
	@:native("SDL_GL_CONTEXT_PROFILE_MASK") var ContextProfileMask;
}

/**
	Direct SDL3 calls. Host code only: cppia scripts can't call externs, so they go through `sdl3.SDL`.
	Value-type arguments (`NativeEvent`, `NativeRect`) are passed by address where SDL takes a pointer.
**/
@:keep
@:include("linc_sdl3.h")
@:build(linc.Linc.touch())
@:build(linc.Linc.xml("sdl3"))
extern class Native {
	@:native("SDL_Init")
	static function init(flags:UInt32):Bool;

	@:native("SDL_Quit")
	static function quit():Void;

	@:native("SDL_GetError")
	static function getError():ConstCharStar;

	@:native("SDL_GetVersion")
	static function getVersion():Int;

	@:native("SDL_GetCurrentVideoDriver")
	static function getCurrentVideoDriver():ConstCharStar;

	@:native("SDL_GetSystemTheme")
	static function getSystemTheme():Int;

	@:native("SDL_HasEvent")
	static function hasEvent(type:Int):Bool;

	@:native("SDL_GetTicks")
	static function getTicks():UInt64;

	@:native("SDL_SetHint")
	static function setHint(name:ConstCharStar, value:ConstCharStar):Bool;

	// Windows

	@:native("SDL_CreateWindow")
	static function createWindow(title:ConstCharStar, width:Int, height:Int, flags:UInt64):NativeWindow;

	@:native("SDL_DestroyWindow")
	static function destroyWindow(window:NativeWindow):Void;

	@:native("SDL_ShowWindow")
	static function showWindow(window:NativeWindow):Bool;

	@:native("SDL_GetWindowID")
	static function getWindowID(window:NativeWindow):UInt32;

	@:native("SDL_SetWindowSize")
	static function setWindowSize(window:NativeWindow, width:Int, height:Int):Bool;

	@:native("SDL_SetWindowPosition")
	static function setWindowPosition(window:NativeWindow, x:Int, y:Int):Bool;

	@:native("SDL_GetWindowDisplayScale")
	static function getWindowDisplayScale(window:NativeWindow):Float32;

	@:native("SDL_GetWindowPixelDensity")
	static function getWindowPixelDensity(window:NativeWindow):Float32;

	@:native("SDL_GetWindowSafeArea")
	static function getWindowSafeArea(window:NativeWindow, rect:NativeRect):Bool;

	@:native("SDL_GetDisplayForWindow")
	static function getDisplayForWindow(window:NativeWindow):UInt32;

	@:native("linc::sdl3::isPointOnDisplay")
	static function isPointOnDisplay(x:Int, y:Int):Bool;

	@:native("linc::sdl3::getWindowSize")
	static function getWindowSize(window:NativeWindow):Bool;

	@:native("linc::sdl3::getWindowSizeInPixels")
	static function getWindowSizeInPixels(window:NativeWindow):Bool;

	@:native("linc::sdl3::getCurrentDisplayMode")
	static function getCurrentDisplayMode(display:UInt32):Bool;

	// OpenGL

	@:native("SDL_GL_SetAttribute")
	static function glSetAttribute(attr:NativeGLAttr, value:Int):Bool;

	@:native("SDL_GL_CreateContext")
	static function glCreateContext(window:NativeWindow):NativeGLContext;

	@:native("SDL_GL_DestroyContext")
	static function glDestroyContext(context:NativeGLContext):Bool;

	@:native("SDL_GL_SetSwapInterval")
	static function glSetSwapInterval(interval:Int):Bool;

	@:native("SDL_GL_SwapWindow")
	static function glSwapWindow(window:NativeWindow):Bool;

	// Events

	@:native("SDL_PollEvent")
	static function pollEvent(event:NativeEvent):Bool;

	@:native("SDL_WaitEventTimeout")
	static function waitEventTimeout(event:NativeEvent, timeoutMs:Int):Bool;

	@:native("SDL_SetEventEnabled")
	static function setEventEnabled(type:UInt32, enabled:Bool):Void;

	@:native("linc::sdl3::pushUserEvent")
	static function pushUserEvent(code:Int):Bool;

	// Keyboard and clipboard

	@:native("SDL_StartTextInput")
	static function startTextInput(window:NativeWindow):Bool;

	@:native("SDL_StopTextInput")
	static function stopTextInput(window:NativeWindow):Bool;

	@:native("linc::sdl3::startTextInputWith")
	static function startTextInputWith(window:NativeWindow, type:Int, capitalization:Int, autocorrect:Bool, multiline:Bool):Bool;

	@:native("linc::sdl3::setTextInputArea")
	static function setTextInputArea(window:NativeWindow, x:Int, y:Int, w:Int, h:Int, cursor:Int):Bool;

	@:native("SDL_ScreenKeyboardShown")
	static function screenKeyboardShown(window:NativeWindow):Bool;

	@:native("linc::sdl3::androidInputTypeFor")
	static function androidInputType(type:Int, capitalization:Int, autocorrect:Bool, multiline:Bool):Int;

	@:native("linc::sdl3::sendAndroidMessage")
	static function sendAndroidMessage(command:Int, param:Int):Bool;

	@:native("SDL_SetClipboardText")
	static function setClipboardText(text:ConstCharStar):Bool;

	@:native("SDL_HasClipboardText")
	static function hasClipboardText():Bool;

	@:native("linc::sdl3::getClipboardText")
	static function getClipboardText():String;

	// Cursors

	@:native("linc::sdl3::createSystemCursor")
	static function createSystemCursor(id:Int):NativeCursor;

	@:native("SDL_SetCursor")
	static function setCursor(cursor:NativeCursor):Bool;

	@:native("SDL_DestroyCursor")
	static function destroyCursor(cursor:NativeCursor):Void;

	// 2D renderer (simple's CPU fallback)

	@:native("linc::sdl3::createRenderer")
	static function createRenderer(window:NativeWindow):NativeRenderer;

	@:native("SDL_DestroyRenderer")
	static function destroyRenderer(renderer:NativeRenderer):Void;

	@:native("SDL_SetRenderVSync")
	static function setRenderVSync(renderer:NativeRenderer, vsync:Int):Bool;

	@:native("linc::sdl3::getCurrentRenderOutputSize")
	static function getCurrentRenderOutputSize(renderer:NativeRenderer):Bool;

	@:native("linc::sdl3::createTexture")
	static function createTexture(renderer:NativeRenderer, format:Int, access:Int, width:Int, height:Int):NativeTexture;

	@:native("SDL_DestroyTexture")
	static function destroyTexture(texture:NativeTexture):Void;

	@:native("SDL_SetTextureBlendMode")
	static function setTextureBlendMode(texture:NativeTexture, mode:UInt32):Bool;

	@:native("linc::sdl3::setTextureScaleMode")
	static function setTextureScaleMode(texture:NativeTexture, mode:Int):Bool;

	@:native("linc::sdl3::updateTexture")
	static function updateTexture(texture:NativeTexture, pixels:BytesData, pitch:Int):Bool;

	@:native("SDL_RenderClear")
	static function renderClear(renderer:NativeRenderer):Bool;

	@:native("linc::sdl3::renderTexture")
	static function renderTexture(renderer:NativeRenderer, texture:NativeTexture):Bool;

	@:native("SDL_RenderPresent")
	static function renderPresent(renderer:NativeRenderer):Bool;

	#if android
	@:native("SDL_GetAndroidInternalStoragePath")
	static function getAndroidInternalStoragePath():ConstCharStar;
	#end

	// Out-values of the linc::sdl3 helpers above

	@:native("linc::sdl3::outW")
	static var outW:Int;

	@:native("linc::sdl3::outH")
	static var outH:Int;

	@:native("linc::sdl3::outRefreshRate")
	static var outRefreshRate:Float32;

	@:native("linc::sdl3::outPixelDensity")
	static var outPixelDensity:Float32;
}
