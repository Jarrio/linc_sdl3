import sdl3.SDL;

class Start {
	var background = 0x1d2b53;
	var stripes = 0x29366f;
	var stripeWidth = 6;
	var speed = 10.0;
	var circle = 0x000000;
	var radius = 5;

	public function new() {
		App.onEvent = onEvent;
		App.onFrame = onFrame;
	}

	function onEvent(event:Event) {
		if (event.type == EventType.TextInput) {
			trace(event.text);
		}
	}

	function onFrame() {
		var scroll = Std.int(SDL.getTicks() / 1000 * speed);
		for (y in 0...App.HEIGHT) {
			for (x in 0...App.WIDTH) {
				var dx = x - App.mouseX;
				var dy = y - App.mouseY;
				var color = Std.int((x + y + scroll) / stripeWidth) % 2 == 0 ? background : stripes;
				if (dx * dx + dy * dy < radius * radius) {
					color = circle;
				}
				App.setPixel(x, y, color);
			}
		}
	}
}
