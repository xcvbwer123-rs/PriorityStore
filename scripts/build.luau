-- scripts/build.luau

local multitarget = require("../lune_packages/multitarget")

multitarget.build(
	"pesde.toml",
	{
		luau = true;
		lune = true;
		roblox = true;
	},
	"dist",
	{
		"src";
	},
	"LUA_ENV"
)