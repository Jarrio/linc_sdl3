# Demo

Moving stripes and a circle that follows the mouse. Typed text is traced, and Escape quits.

Run `haxe --run Fetch` in the folder above first. Then, from this folder:

- Native: `haxe hxcpp.hxml`, then run `Main-debug` from `bin/cpp`.
- cppia: `haxe cppia.hxml` builds the host into `bin/cppia`, and `haxe script.hxml` builds `bin/cppia/script.cppia`. Run `bin/cppia/Main-debug`, which loads `script.cppia` from its own folder, or the script given as its first argument.

The host owns the window and the loop in `project/App.hx`, and reloads the script when `script.cppia` changes. While it runs, change the values at the top of `project/Start.hx` and run `haxe script.hxml` again to see them change.
