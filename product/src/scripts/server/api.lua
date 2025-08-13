local FixtureAPI = { enabled = false }

local DEUBGGING_ENABLED = false

function debug(msg, callback)
    if not DEUBGGING_ENABLED then return end
    return callback(msg)
end

local prefix = "[LED Bars: FixtureAPI.lua]"

local rawHandlers = {}
local callbacks = {}

local scopedFixtureApi = {
    eventHandlers = {
        dimmer = function(arguments)
            assert(arguments ~= 'nil', '"arguments" is not present.')
            assert(type(arguments) == 'table', '"arguments" is not a table.')
            assert(arguments.func ~= 'nil', '"arguments.func" is not present.')
            assert(arguments.mouseButton ~= 'nil', '"arguments.mouseButton" is not present.')
            assert(arguments.lightOn ~= 'nil', '"arguments.lightOn" is not present.')
            assert(type(arguments.func) == 'string', '"arguments.func" is not a string.')
            assert(type(arguments.mouseButton) == 'string', '"arguments.func" is not a string.')
            assert(type(arguments.lightOn) == 'boolean', '"arguments.lightOn" is not a boolean.')

            local handlerFunction = rawHandlers.dimmer
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        color = function(arguments)
            assert(arguments ~= 'nil', '"arguments" is not present.')
            assert(type(arguments) == 'table', '"arguments" is not a table.')
            assert(arguments.colorMode ~= 'nil', '"arguments.colorMode" is not present.')
            assert(arguments.color ~= 'nil', '"arguments.color" is not present.')
            assert(type(arguments.colorMode) == 'string', '"arguments.colorMode" is not a string.')
            assert(typeof(arguments.color) == 'Color3', '"arguments.color" is not a Color3 value.')

            local handlerFunction = rawHandlers.color
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        colorfx = function(color)
            assert(color ~= 'nil', '"color" is not present.')
            assert(typeof(color) == 'Color3', '"color" is not a Color3 value.')

            local handlerFunction = rawHandlers.colorFX
            if handlerFunction then
                handlerFunction(color)
            end
        end,
        position = function(positionIndex)
            assert(positionIndex ~= nil, '"positionIndex" is not present.')
            assert(type(positionIndex) == "number", prefix..'  "positionIndex" is not a number.')

            local handlerFunction = rawHandlers.position
            if handlerFunction then
                handlerFunction(positionIndex)
            end
        end,
        effect = function(arguments)
            assert(type(arguments) == "table", prefix..'  "arguments" is not a table.')

            local handlerFunction = rawHandlers.effect
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        bpm = function(arguments)
            assert(arguments ~= 'nil', '"arguments" is not present.')
            assert(type(arguments) == 'table', prefix..'  "arguments" is not a table.')
            assert(arguments.valueName ~= 'nil', '"arguments.valueName" is not present.')
            assert(arguments.value ~= 'nil', '"arguments.value" is not present.')
            assert(type(arguments.valueName) == "string", prefix..'  "valueName" is not a string.')
            assert(type(arguments.value) == "number", prefix..'  "value" is not a number.')

            local handlerFunction = rawHandlers.bpm
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        spot = function(isOn)
            assert(isOn ~= 'nil', '"isOn" is not present.')
            assert(type(isOn) == "boolean", prefix..'  "isOn" is not a boolean.')

            local handlerFunction = rawHandlers.spot
            if handlerFunction then
                handlerFunction(isOn)
            end
        end,
        phase = function(arguments)
            assert(arguments ~= 'nil', prefix..' "arguments" is not present.')
            assert(type(arguments) == "table", prefix..' "arguments" is not a table.')
            assert(arguments.phaseName ~= 'nil', prefix..' "arguments.phaseName" is not present.')
            assert(arguments.value ~= 'nil', prefix..' "arguments.value" is not present.')
            assert(type(arguments.phaseName) == "string", prefix..' "phaseName" is not a string.')
            assert(type(arguments.value) == "number", prefix..' "value" is not a number.')

            local handlerFunction = rawHandlers.phase
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        fade = function(arguments)
            assert(arguments ~= 'nil', prefix..' "arguments" is not present.')
            assert(type(arguments) == "table", prefix..' "arguments" is not a table.')
            assert(type(arguments.value) == "number", prefix..' "value" is not a number.')

            local handlerFunction = rawHandlers.fade
            if handlerFunction then
                handlerFunction(arguments)
            end
        end,
        reset = function()
            local handlerFunction = rawHandlers.reset
            if handlerFunction then
                handlerFunction()
            end
        end
    },
}

function FixtureAPI.setEvent(eventName, eventData)
    assert(type(eventName) == "string", prefix..' "eventName is not a string.')
    assert(type(eventData) ~= "function", prefix..' "eventData" cannot be a function.')

    local event = scopedFixtureApi.eventHandlers[eventName]

    if event then
        scopedFixtureApi.eventHandlers[eventName](eventData)
    else
        return error(prefix..' event does not exist for event {eventName}.')
    end
end

function FixtureAPI.connectCallback(name, _callbacks)
    if callbacks[name] then
        return error(prefix..' a callback under this name already exists')
    end

    callbacks[name] = _callbacks
end

function FixtureAPI.deleteCallback(name)
    if not callbacks[name] then
        return error(prefix..' this callback does not exist.')
    end

    callbacks[name] = nil
end

function FixtureAPI.runCallback(name, index)
    if not callbacks[name] then
        return error(prefix..' this callback does not exist. have you tried running .connectCallback()?')
    end

    if not callbacks[name][index] then
        return error(prefix..' this callback is missing a function. did you check the index in position {index} in your callbacks?')
    end

    callbacks[name][index]()
end

function FixtureAPI.connectEvent(eventName, handlerFunction)
    assert(type(eventName) == "string", prefix..' "eventName is not a string.')
    assert(type(handlerFunction) == "function", prefix..' "handlerFunction" is not a function.')
    assert(handlerFunction ~= nil, prefix..' removing handler functions is not supported')

    if rawHandlers[eventName] then
        return error(prefix..' attempt to edit immovable properties')
    end

    debug(
        prefix..' {eventName} registered.',
    warn)

    rawHandlers[eventName] = handlerFunction
end

function FixtureAPI.init()
    -- *used to hold verification logic here
    FixtureAPI.enabled = true
end

return FixtureAPI
