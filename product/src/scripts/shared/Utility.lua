local TweenService = game:GetService('TweenService')

local Utility = {}

local templatesFolder = script.Parent.Parent.Parent.templates
local circleImage = templatesFolder:FindFirstChild('Circle')

local DEBUGGING_ENABLED = false

function Utility:HSLtoRGB(hue, saturation, lightness, alpha)
    local red, green, blue

    if saturation == 0 then
        red, green, blue = lightness, lightness, lightness
    else
        local function hue2rgb(prev, current, n)
            if n < 0 then n = n + 1 end
            if n > 1 then n = n - 1 end
            if n < 1/6 then return prev + (current - prev) * 6 * n end
            if n < 1/2 then return current end
            if n < 2/3 then return prev + (current - prev) * (2/3 - n) * 6 end
            return prev
        end

        local q
        if lightness < 0.5 then
            q = lightness * (1 + saturation)
        else
            q = lightness + saturation - lightness * saturation
        end
        local p = 2 * lightness - q

        red = hue2rgb(p, q, hue + 1/3)
        green = hue2rgb(p, q, hue)
        blue = hue2rgb(p, q, hue - 1/3)
    end

    return red, green, blue, alpha
end

function Utility:generateColorPicker(arguments)
    if not (
        arguments and
        arguments.sensor and
        arguments.pointer and
        arguments.callback and
        arguments.indicator
    ) then
        return
    end

    local self = {
        pickerDown = false,
        backPickerDown = false,
        sensor = arguments.sensor,
        pointer = arguments.pointer,
        backpointer = arguments.backpointer,
        sensorSize = arguments.sensor.AbsoluteSize,
        callback = arguments.callback,
        indicator = arguments.indicator
    }

    self.sensor.MouseButton1Down:Connect(function()
        self.pickerDown = true
    end)

    self.sensor.MouseButton1Up:Connect(function()
        self.pickerDown = false
    end)

    self.sensor.MouseButton2Down:Connect(function()
        self.backPickerDown = true
    end)

    self.sensor.MouseButton2Up:Connect(function()
        self.backPickerDown = false
    end)

    self.sensor.MouseLeave:Connect(function()
        self.pickerDown = false
        self.backPickerDown = false
    end)

    self.sensor.MouseMoved:Connect(function(x, y)
        local xOffset, yOffset = x - self.sensor.AbsolutePosition.X, y - self.sensor.AbsolutePosition.Y
        local color = Color3.new(Utility:HSLtoRGB(xOffset / self.sensorSize.X, 1, yOffset / self.sensorSize.Y, 1))
        local position = UDim2.new(xOffset / self.sensorSize.X, 0, yOffset / self.sensorSize.Y, 0)

        if self.pickerDown then
            self.pointer.Position = position
            self.indicator.BackgroundColor3 = color
            self.callback[1](color)
        end

        if self.backPickerDown then
            self.backpointer.Position = position
            self.indicator.BackgroundColor3 = color
            self.callback[2](color)
        end
    end)
end

local function getColorCallbacks()
    return {
        all = function(light, color)
            light:setValue('Color All', color[1])
            light.extras.lastSavedColor = color[1]
        end,
        even = function(light, color)
            if not light:isEven() then return end
            light:setValue('Color All', color[1])
            light.extras.lastSavedColor = color[1]
        end,
        odd = function(light, color)
            if light:isEven() then return end
            light:setValue('Color All', color[2])
            light.extras.lastSavedColor = color[2]
        end,
        evenOdd = function(light, color)
            if not light:isEven() then
                light:setValue('Color All', color[1])
                light.extras.lastSavedColor = color[1]
            else
                light:setValue('Color All', color[2])
                light.extras.lastSavedColor = color[2]
            end
        end
    }
end

function Utility:setColor(light, mode, arguments)
    if not (
        light and
        mode and
        arguments
    ) then
        return
    end

    local colorCallbacks = getColorCallbacks()
    return colorCallbacks[mode](light, arguments.colors)
end

function Utility:returnButtonInfo(frame)
    if not frame then
        return
    end

    return {
        {button = frame:FindFirstChild('Power'), name = 'Power', buttonToggle = {{'MouseButton1Down', true}, {'MouseButton2Down', false}}},
        {button = frame:FindFirstChild('Fade In'), name = 'Fade In', buttonToggle = {{'MouseButton1Down', true}}},
        {button = frame:FindFirstChild('Fade Out'), name = 'Fade Out', buttonToggle = {{'MouseButton1Down', false}}},
        {button = frame:FindFirstChild('Pulse A/B'), name = 'Pulse A/B', buttonToggle = {{'MouseButton1Down', false}, {'MouseButton2Down', false}}},
        {button = frame:FindFirstChild('Fade A/B'), name = 'Fade Hold A/B', buttonToggle = {{'MouseButton1Down', true}, {'MouseButton2Down', true}, {'MouseButton1Up', false}, {'MouseButton2Up', false}}},
        {button = frame:FindFirstChild('Hold A/B'), name = 'Hold A/B', buttonToggle = {{'MouseButton1Down', true}, {'MouseButton2Down', true}, {'MouseButton1Up', false}, {'MouseButton2Up', false}}},
        {button = frame:FindFirstChild('Hold L/R'), name = 'Hold L/R', buttonToggle = {{'MouseButton1Down', true}, {'MouseButton2Down', true}, {'MouseButton1Up', false}, {'MouseButton2Up', false}}},
        {button = frame:FindFirstChild('Hold Reg'), name = 'Power', buttonToggle = {{'MouseButton1Down', true}, {'MouseButton1Up', false}}},
    }
end

function Utility:setMasterIndicator(button)
    if not button then
        return
    end

    button.Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TweenService:Create(
        button.Frame,
        TweenInfo.new(
            0.45
        ),
        { BackgroundColor3 = Color3.new(1,1,1) }
    ):Play()
end

function Utility:registerDimmerButtons(buttons, eventsFolder)
    if not (
        buttons and
        eventsFolder
    ) then
        return
    end

    for _, container in self:returnButtonInfo(buttons) do
        if not container.button then
            continue
        end

        local hasDimmerAttribute = container.button:GetAttribute('dimmerButton') ~= nil
        local isDimmerButton = container.button:IsA('TextButton')

        if not hasDimmerAttribute or not isDimmerButton then
            continue
        end

        for _, buttonType in container.buttonToggle do
            local mouseClickType = buttonType[1]
            local setLightOn = buttonType[2]

            local data = {
                func = container.name,
                mouseButton = mouseClickType,
                lightOn = setLightOn
            }

            container.button[mouseClickType]:Connect(function()
                eventsFolder.Listener:FireServer('dimmer', data)
                self:setMasterIndicator(container.button)
            end)
        end
    end
end


function Utility:getFXArchetype(mode, info)
    if not (
        mode and
        info
    ) then
        return
    end

	local effectsTable = { effects = {} }

	for index, values in info do
		if mode == 'solo' and index > 1 then continue end
		local button, effectName, effectOn = values[1], values[2], values[3]

		local effectStruct = {
			effectName = effectName,
			buttonReference = button,
			on = effectOn
		}
		table.insert(effectsTable.effects, effectStruct)
	end

	return effectsTable
end

function Utility:round(number, decimalPlaces)
	local multiplier = 10 ^ (decimalPlaces or 0)
	return math.floor(number * multiplier + 0.5) / multiplier
end

function Utility:setTextColor3(mainInstance, instancesArray, targetColor, fallbackColor, duration)
    if not (
        mainInstance and
        instancesArray and
        targetColor and
        fallbackColor
    ) then
        return
    end

    local tweenDuration = duration or 0.25

    if #instancesArray == 0 then
        return
    end

    for _, instance in instancesArray do
        TweenService:Create(instance, TweenInfo.new(tweenDuration), {TextColor3 = fallbackColor}):Play()
    end

    TweenService:Create(mainInstance, TweenInfo.new(tweenDuration), {TextColor3 = targetColor}):Play()
end

function Utility:generateFader(data)
    if not (
        data and
        data.frame and
        data.sensorPos and
        data.sensorSize and
        data.connection and
        data.faderInstance
    ) then
        return
    end

    local self = {
        sensorPos = data.sensorPos,
        sensorSize = data.sensorSize,
        frame = data.frame,
        connection = data.connection,
        faderInstance = data.faderInstance,
        multiplier = tonumber(data.multiplier) or 1,
        valueLabel = data.valueLabel,
        faderScale = data.faderScale,
        heldDown = false
    }

	self.frame.MouseButton1Down:Connect(function()
		self.heldDown = true
	end)

	self.frame.MouseButton1Up:Connect(function()
		self.heldDown = false
	end)

	self.frame.MouseLeave:Connect(function()
		self.heldDown = false
	end)

	self.frame.MouseMoved:Connect(function(x, y)
        local adjustedY = y - self.sensorPos.Y

        if self.heldDown then
            local normalizedPositionY = adjustedY / self.sensorSize.Y

            if normalizedPositionY >= 0.97 then
                normalizedPositionY = 1
            end

            if normalizedPositionY <= 0.03 then
                normalizedPositionY = 0
            end

            self.faderInstance.Size = UDim2.new(1, 0, 1 - normalizedPositionY, 0)

            local values = {
                grandScale = (-normalizedPositionY * 2 * 90) + 180,
                zeroToOne = (((-normalizedPositionY * 2 * 90) + 180) * 0.1) / 18,
                zeroToPointFive = ((((-normalizedPositionY * 2 * 90) + 180) * 0.1) / 18) * 0.5,
            }

            local finalValue = values[self.faderScale] * self.multiplier
            self.valueLabel.Text = (self.faderScale == 'zeroToOne') and Utility:round(finalValue, 2) or tostring(math.floor(finalValue))

            self.connection(finalValue)
        end
	end)

    return self
end


function Utility:createEffectStructure(args, callback, extraInfo)
    if not (
        args and
        callback and
        extraInfo
    ) then
        return
    end

    local effect, engine = args.effect, args.engine

    return {
        personality = {
            name = effect.name,
            bpm = effect.bpm or 60,
            phase = effect.phase or 0.1,
            category = effect.category or 'dimmer',
            bounce = effect.bounce or false,
            parameter = effect.parameter or 'Intensity',
            phaseSelection = effect.phaseSelection or 'phase',
            editable = {
                bpm = effect.editableByBPM or false,
                phase = effect.editableByPhase or false,
                limit = effect.editableByLimit or false,
            },
            limits = {
                pan = 1,
                tilt = 1
            },

            direction = effect.direction or 1,
            colorSwitch = Color3.new(1, 1, 1),
            bpmMult = effect.bpmMult or 1,
            phaseMult = effect.phaseMult or 0.05
        },
        engine = {
            waveform = engine.waveform,
            callback = (callback or error("no callback for effect to reference to"))
        },
        extras = {
            instances = extraInfo.instances,
        }
    }
end

local function ripple(button, xCord, yCord)
    coroutine.resume(
            coroutine.create(function()
            button.ClipsDescendants = true

            local circle = circleImage:Clone()
            circle.Parent = button

            local newX = xCord - circle.AbsolutePosition.X
            local newY = yCord - circle.AbsolutePosition.Y

            circle.Position = UDim2.new(0, newX, 0, newY)

            local size = 0

            if button.AbsoluteSize.X > button.AbsoluteSize.Y then
                size = button.AbsoluteSize.X * 1.5
            elseif button.AbsoluteSize.X < button.AbsoluteSize.Y then
                size = button.AbsoluteSize.Y * 1.5
            elseif button.AbsoluteSize.X == button.AbsoluteSize.Y then
                size = button.AbsoluteSize.X * 1.5
            end

            local duration = 0.5

            circle:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, -size / 2, 0.5, -size / 2), 'Out', 'Quad', duration, false, nil)
            for _ = 1, 10 do
                circle.ImageTransparency = circle.ImageTransparency + 0.01

                task.wait(duration / 10)
            end
            circle:Destroy()
        end)
    )
end

function Utility:registerRippleListener(button)
    button.MouseButton1Down:Connect(function(x, y)
        ripple(button, x, y)
    end)
    button.MouseButton2Down:Connect(function(x, y)
        ripple(button, x, y)
    end)
end

function Utility:handleColorChange(arguments, colorTable)
    if not (
        arguments and
        colorTable
    ) then
        return
    end

    local targetColorIndex = 2

    local colorModeSet = {
        all = function()
            if #colorTable.colors == targetColorIndex then
                table.remove(colorTable.colors, targetColorIndex)
            end
        end,
        even = function()
            if #colorTable.colors ~= targetColorIndex then
                colorTable.colors = { colorTable.colors[1], Color3.new(1, 1, 1) }
            end
        end,
        odd = function()
            if #colorTable.colors ~= targetColorIndex then
                colorTable.colors = { colorTable.colors[1], Color3.new(1, 1, 1) }
            end
        end,
        evenOdd = function()
            colorTable.colors = { arguments.colors[1], arguments.colors[2] }
        end
    }

    local setColors = {
        all = function()
            colorTable.colors[1] = arguments.color
        end,
        even = function()
            colorTable.colors[1] = arguments.color
        end,
        odd = function()
            colorTable.colors[targetColorIndex] = arguments.color
        end,
        evenOdd = function()
            colorTable.colors[1] = arguments.color[1]
            colorTable.colors[targetColorIndex] = arguments.color[2]
        end
    }

    if not arguments.ignore then
        colorTable.colorMode = arguments.colorMode
        colorModeSet[arguments.colorMode]()

        if arguments.setBoth then
            task.wait()
            setColors[arguments.colorMode]()
        end
    end

    if arguments.changing and not arguments.ignore then
        colorTable.colorMode = arguments.colorMode
        colorModeSet[arguments.colorMode]()
    else
        setColors[arguments.colorMode]()
    end

    if arguments.setBoth then
        colorTable.colorMode = arguments.colorMode
        colorModeSet[arguments.colorMode]()
        task.wait()
        setColors[arguments.colorMode]()
    end

    return colorTable
end


return Utility

