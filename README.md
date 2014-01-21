# LiveVars (WIP)

LiveVars is an implementation of Unity-like live variable editing in FlashPunk. I'd like to eventually make this more extendable so people can easily subclass it to support other engines.

I wanted to get this out before Ludum Dare, but you should be aware that, although it is working, this is still a work-in-progress.

## Demo

Check out a brief demo [here](http://tasteofmoonlight.com/uploads/livevars-demo.html).

---

Variable names and values are written in a [toml][toml] file, which you specify *relative to the directory that holds your .swf, not the project directory*.

You can have **world** variables and **static** variables.

#### World Variables
World variables are instance variables that belong to the current World (`FP.world`). They are placed in an object with the same name as the world itself.

#### Static Variables
Static variables are placed in objects with a name other than the current World, corresponding to the class name that holds the static variables. These are not instance variables, but they can still be modified in real-time.

> ### A Note on Packages
> If a Class or World is inside a package, you cannot refer to it directly by name without the corresponding package information. Packages are referred to with a double colon syntax. (This is automatically converted to an ActionScript-friendly syntax.) For instance, `com::example::Class`.

## Example
	
	# current world
	[worlds::Game]
	points = 0

		[worlds::Game.player]
		name = "P1"
		powers = ["jump", "smash"]
		
		[worlds::Game.player.speed]
		x = 0
		y = -40

	[entities::Player]
	# static variable
	color = 0xff0000

	[Globals]
	currentLevel = 3

## Implementation

Using LiveVars is as easy as calling `LiveVars.init("livevars.toml")` at any point (presumably at launch, though) in your game.

[toml]: https://github.com/mojombo/toml
