--------------------------------------------------------------------------------------------------------------------------------
--[[                                              Copyright © Inertia Lighting                                              ]]--
--------------------------------------------------------------------------------------------------------------------------------

local LuaAdditions = {}

---------------------------------------------------------------

LuaAdditions.version = 'v0.0.3-beta'

---------------------------------------------------------------

local srcFolder = script.Parent:WaitForChild('src')

LuaAdditions.Table = require(srcFolder.Table)

-- LuaAdditions.string is omitted.

LuaAdditions.Utility = require(srcFolder.Utility)

---------------------------------------------------------------

return LuaAdditions
