import haxe.io.Bytes;
import sdl3.SDL;

class App {
	public static inline var WIDTH = 80;
	public static inline var HEIGHT = 60;

	public static var mouseX = 0;
	public static var mouseY = 0;
	public static var onEvent:Event->Void = event -> {};
	public static var onFrame:Void->Void = () -> {};

	static var pixels = Bytes.alloc(WIDTH * HEIGHT * 4);

	public static function setPixel(x:Int, y:Int, color:Int) {
		pixels.setInt32((y * WIDTH + x) * 4, 0xff000000 | color);
	}

	public static function run(?reload:Void->Void) {
		SDL.init(SDL.INIT_VIDEO);
		var window = SDL.createWindow("Demo", WIDTH * 8, HEIGHT * 8, SDL.WINDOW_RESIZABLE);
		var renderer = SDL.createRenderer(window);
		var texture = SDL.createTexture(renderer, SDL.PIXELFORMAT_ARGB8888, SDL.TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
		SDL.setTextureScaleMode(texture, SDL.SCALEMODE_NEAREST);
		SDL.setRenderVSync(renderer, 1);
		SDL.startTextInput(window);

		var event = new Event();
		var running = true;
		while (running) {
			if (reload != null) {
				reload();
			}
			while (SDL.pollEvent(event)) {
				switch (event.type) {
					case Quit:
						running = false;
					case KeyDown if (event.key == SDL.KEY_ESCAPE):
						running = false;
					case MouseMotion:
						var size = SDL.getWindowSize(window);
						mouseX = Std.int(event.x * WIDTH / size.w);
						mouseY = Std.int(event.y * HEIGHT / size.h);
					case _:
				}
				onEvent(event);
			}
			onFrame();
			SDL.updateTexture(texture, pixels.getData(), WIDTH * 4);
			SDL.renderClear(renderer);
			SDL.renderTexture(renderer, texture);
			SDL.renderPresent(renderer);
		}

		SDL.destroyTexture(texture);
		SDL.destroyRenderer(renderer);
		SDL.destroyWindow(window);
		SDL.quit();
	}
}
