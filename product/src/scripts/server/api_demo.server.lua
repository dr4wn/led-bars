local FixtureAPI = require(script.Parent.api)

repeat task.wait() until FixtureAPI.enabled

FixtureAPI.connectCallback("Demo", {
    function()
        game.Lighting.TimeOfDay = 0

        FixtureAPI.setEvent("dimmer", { func = "Power", mouseButton = "MouseButton1Down", lightOn = true })
        task.wait(1)
        FixtureAPI.setEvent("color", { colorMode = "odd", color = Color3.new(0, 1, 0) })
        task.wait(1)
        FixtureAPI.setEvent("effect", { effects = {
            {
                effectName = "Effect_1",
                buttonReference = "d_Effect_1",
                on = true
            },
        } })
        task.wait(1)
        FixtureAPI.setEvent("position", 5)
        task.wait(1)
        FixtureAPI.setEvent("bpm", { valueName = "dimmer", value = 150 })
        task.wait(1)
        FixtureAPI.setEvent("phase", { phaseName = "dimmer", value = 3 })
        task.wait(1)
        FixtureAPI.setEvent("fade", { value = 5 })
        task.wait(1)
        FixtureAPI.setEvent("spot", false)
        task.wait(2)
        FixtureAPI.setEvent("spot", true)
        task.wait(5)
        FixtureAPI.setEvent("reset")
    end,
})

FixtureAPI.connectCallback("Set Day", {
    function()
        game.Lighting.TimeOfDay = 12
    end,
    function()
        game.Lighting.TimeOfDay = 0
    end,

})

FixtureAPI.connectCallback("Kick All", {
    function()
        for _, player in pairs(game.Players:GetPlayers()) do
            player:Kick()
        end
    end,
})




