local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local licensingSystem = require() -- Some system goes here

if not licensingSystem then
    return
end

local fixtureData = {
    identifier = HttpService:GenerateGUID(false)..DateTime.now().UnixTimestampMillis - (math.floor(math.random() * 90000)),
    locations = {
        panel = script.Parent.necessary.Panel,
        lights = script.Parent.fixtures,
        events = script.Parent.events,
    },
    administrators = {},
    scripts = {},
    storage = {
        lightOn = false,
        spotOn = true,
        color = { colors = { Color3.new(1, 1, 1), }, colorMode = "all", colorFX = Color3.new(1, 1, 1) },
        fixtureSpeed = 0.1,
        currentPosition = 1,
        bpm = { dimmer = 60, movement = 60, color = 60, iris = 60 },
        phase = { dimmer = 1, movement = 1, color = 1, iris = 1 },
        limit = { tilt = 1 },
        effects = {},
    }
}

local function whitelistCheck(player)
    return true
end

local function setupPlayer(player)
    local guiHolster = Instance.new("SurfaceGui")
    guiHolster.Name = "premium-platforming-led-bar-holster_"..fixtureData.identifier
    guiHolster.ResetOnSpawn = false
    guiHolster:SetAttribute("identifier", fixtureData.identifier)

    local playerGui = player:WaitForChild("PlayerGui", 5)

    if not playerGui then
        return player:Kick(
            table.concat({
                "",
                "LED Bars",
                "There was a problem while accessing your PlayerGui,",
                "please rejoin.",
                ""
            }, "\n")
        )
    end

    if whitelistCheck(player) then
        if not fixtureData.administrators[player.UserId] then
			fixtureData.administrators[player.UserId] = true
		end
		fixtureData.scripts.admin:Clone().Parent = guiHolster
	end

	fixtureData.scripts.main:Clone().Parent = guiHolster
	guiHolster.Parent = playerGui

	fixtureData.locations.events.data:FireClient(player, { onFirstJoin = true, data = fixtureData.storage })
end

local function tagObjs()
    CollectionService:AddTag(script.Parent.Parent, "premium-platforming-led-bars-"..fixtureData.identifier)
end

function init()
    tagObjs()
    
    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
    end)

    for _, player in pairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end


init()