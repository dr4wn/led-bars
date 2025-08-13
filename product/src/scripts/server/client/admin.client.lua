local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local instanceIdentifier = script.Parent:GetAttribute("identifier")
if not instanceIdentifier then
    return
end

local baseProductString = "dr4wn-led-bars-"
local prefix = '[LED Bars: Admin]'

print(prefix..' '..tostring(script.Name)..' file given to client.')

local productFolder = CollectionService:GetTagged(baseProductString..instanceIdentifier)[1]
if not productFolder then
    return error(prefix..' Could not find "productFolder".')
end

local eventsFolder = productFolder:FindFirstChild("events")
if not eventsFolder then
    return error(prefix..' Could not find "eventsFolder".')
end

local sharedFolder = productFolder.scripts:FindFirstChild("shared")
if not sharedFolder then
    return error(prefix..' Could not find "sharedFolder".')
end

local panelsFolder = productFolder:FindFirstChild("panels")
if not panelsFolder then
    return error(prefix..' Could not find "panelsFolder". ')
end

local Utility = require(
    sharedFolder:FindFirstChild("Utility", true)
)()

local configurationPath = productFolder.configuration:FindFirstChild("configuration")

if not configurationPath then
    return error(prefix..' Could not find "configurationPath".')
end

local Configuration = require(configurationPath)

local storage = {
    effects = {},
    colorMode = "all",

    cursor = { ["local"] = "fader", global = "main" },
    globalPages = { main =  true, cuepool = true, about = true },
    localPages = { position = true, fader = true }
}

local FADE_TIME = 0.25
local DEFAULT_TEXT_TRANSPARENCY = 0.17
local DEFAULT_STROKE_TRANSPARENCY = 0.94
local DEFAULT_TEXT_COLOR = Color3.fromRGB(166, 166, 166)
local DEFAULT_STROKE_COLOR = Color3.new(1, 1, 1)

local CURRENT_PAGE = 1
local BUTTONS_PER_PAGE = 12

local buttonOrder = {
    "a_Random Strobe", "b_Random Fade", "c_Strobe", "d_Effect_1",
    "e_Effect_2", "f_Effect_3", "g_Effect_4", "h_Effect_5",
    "i_Effect_6", "j_Effect_7", "k_Effect_8", "l_Effect_9",
    "m_Effect_10", "n_Effect_11", "o_Effect_12", "p_Effect_13",
    "q_Effect_14", "r_Effect_15", "s_Effect_16", "t_Effect_17",
    "u_Effect_18", "v_Effect_19", "w_Effect_20", "x_Effect_21",
    "y_Effect_22", "z_Effect_23"
}

local function changePage(mode, newPage, frames)
    local pages = frames[mode]

    if pages then
        for page, frame in pages do
            frame.Visible = page == newPage
            if frame:IsA("CanvasGroup") then
                local tweenInfo = TweenInfo.new(
                    0.25,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.In
                )

                TweenService:Create(
                    frame,
                    tweenInfo,
                    { GroupTransparency = frame.Visible and 0 or 1 }
                ):Play()
            end
        end
    end
end

local function handlePageChange(mode, newPage, frames)
    local isValidPage = storage[mode .. "Pages"][newPage]

    if isValidPage and storage.cursor[mode] ~= newPage then
        storage.cursor[mode] = newPage
        changePage(mode, newPage, frames)
    end
end

function changeEffectStatus(arguments)
    local on = arguments.on
    local effectName = arguments.effectName
    local buttonReference = arguments.buttonReference

    local info = on and {
        color = Color3.new(0, 1, 0),
        data = {
            effectName = effectName,
            buttonReference = buttonReference,
            effectType = ""
        }
    } or {
        color = Color3.new(1, 0, 0)
    }

    local effectFrame = buttonReference.Frame

    TweenService:Create(
        effectFrame,
        TweenInfo.new(
            0.25
        ),
        { BackgroundColor3 = info.color }
    ):Play()


    if (on and not storage.effects[effectName]) then
        storage.effects[effectName] = info.data
    elseif (not on and storage.effects[effectName]) then
        storage.effects[effectName] = nil
    end
end

local function updateEffectLabels(effectFrame)
    for i, effectName in buttonOrder do
        local button = effectFrame:FindFirstChild(effectName)

        if button then
            button.effectLabel.Text = tostring(i)
        end
    end
end

function updateVisibility(effectFrame)
    for _, button in effectFrame:GetChildren() do
        if button:IsA("TextButton") then
            button.Visible = false
        end
    end

    local startIndex = (CURRENT_PAGE - 1) * BUTTONS_PER_PAGE + 1
    local endIndex = math.min(CURRENT_PAGE * BUTTONS_PER_PAGE, #buttonOrder)

    for i = startIndex, endIndex do
        local effectName = buttonOrder[i]
        local button = effectFrame:FindFirstChild(effectName)

        if not button then
            continue
        end

        if button.Name == effectName then
            button.Visible = true
        end
    end
end

function advanceCarousel(effectFrame)
    CURRENT_PAGE = CURRENT_PAGE + 1

    if CURRENT_PAGE > math.ceil(#buttonOrder / BUTTONS_PER_PAGE) then
        CURRENT_PAGE = 1
    end

    updateVisibility(effectFrame)
end

function reverseCarousel(effectFrame)
    CURRENT_PAGE = CURRENT_PAGE - 1
    if CURRENT_PAGE < 1 then
        CURRENT_PAGE = math.ceil(#buttonOrder / BUTTONS_PER_PAGE)
    end

    updateVisibility(effectFrame)
end

function initializeCarousel(effectFrame)
    CURRENT_PAGE = 1
    updateVisibility(effectFrame)
end

function initializeUIElements(screen)
    local interface = screen:FindFirstChildWhichIsA("SurfaceGui")
    local holster = interface:FindFirstChild("holster")

    interface.Enabled = true

    local elements = {
        canvas = {
            main = holster.main,
            cuepool = holster.cuepool,
            about = holster.about
        },
        templates = holster.templates,
        header = holster.Header,
        headerButtons = {
            global = holster.Header.globalButtons,
            localized = holster.Header.localizedButtons
        },
        stats = {
            debug = holster.about.debugStats,
            fixture = holster.about.fixtureStats
        },
        frames = {
            ["local"] = {
                position = holster.main.position,
                fader = holster.main.fader
            },
            global = {
                main = holster.main,
                cuepool = holster.cuepool,
                about = holster.about
            }
        },
        frameButtons = {
            main = holster.main_,
            cuepool = holster.Header.globalButtons.cuepool,
            about = holster.Header.globalButtons.about,
            position = holster.Header.localizedButtons.position,
            fader = holster.Header.localizedButtons.fader
        }
    }

    return elements
end

function getInterface(screen)
    return screen:FindFirstChildWhichIsA("SurfaceGui")
end

function setupAboutLabels(elements)
    local function formatLabelText(label, value)
        return ("%s: %s"):format(label, value)
    end

    local function updateElementText(elementsTable, isDisabled)
        for _, element in elementsTable do
            if not element:IsA("TextLabel") then continue end
            element.Text = formatLabelText(element.Name, isDisabled and "disabled" or "")
        end
    end

    if not Configuration.dev.complexStats then
        updateElementText(elements.stats.fixture:GetChildren(), true)
    end

    if not Configuration.dev.debug then
        updateElementText(elements.stats.debug:GetChildren(), true)
    end

    if Configuration.dev.extraInfo then
        elements.stats.fixture.apiEnabled.Text = formatLabelText("apiEnabled", tostring(Configuration.usingApi))
        elements.stats.fixture.fixtureCount.Text = formatLabelText("fixtureCount", tostring(#productFolder.fixtures:GetChildren()))
        elements.stats.fixture.customCueCount.Text = formatLabelText("customCueCount", tostring(#Configuration.customButtons))
        elements.stats.fixture.fadeFrame.Text = formatLabelText("fadeFrame", "disabled by default")
        elements.stats.fixture.kickTamperingUsers.Text = formatLabelText("kickTamperingUsers", tostring(Configuration.kickTamperingUsers))
        elements.stats.fixture.positionCount.Text = formatLabelText("positionCount", tostring(#Configuration.positions))
        elements.stats.fixture.effectCount.Text = formatLabelText("effectCount", "24")
        elements.stats.fixture.whitelistEnabled.Text = formatLabelText("whitelistEnabled", tostring(Configuration.whitelistEnabled))
    end

    if Configuration.dev.debug then
        RunService.Heartbeat:Connect(function(deltaTime)
            elements.stats.debug.GetTotalMemoryUsageMb.Text = formatLabelText("GetTotalMemoryUsageMB", tostring(Stats:GetTotalMemoryUsageMb()))
            elements.stats.debug.DataRecieve.Text = formatLabelText("DataRecieve", tostring((Stats.DataReceiveKbps * deltaTime) * 150))
            elements.stats.debug.DataSendKbps.Text = formatLabelText("DataSendKbps", tostring((Stats.DataSendKbps * deltaTime) * 150))
            elements.stats.debug.HeartbeatTimeMs.Text = formatLabelText("HeartbeatTimeMs", tostring((Stats.HeartbeatTimeMs * deltaTime) * 80))
        end)
    end
end

local function generatePositionButtons(elements)
    for i in Configuration.positions do
        if i > 15 then
            break
        end

        local positionButton = elements.templates.position:Clone()
        positionButton.Parent = elements.canvas.main.position
        positionButton.Visible = true
        positionButton.index.Text = i

        positionButton.MouseButton1Click:Connect(function()
            eventsFolder.Listener:FireServer("position", i)
        end)
    end
end

function setupCustomCueButtons(elements)
    local isApiEnabled = Configuration.usingApi
    local noCustomButtonsDefined = #Configuration.customButtons == 0

    local shouldHideNoCueLabel = not (isApiEnabled and not noCustomButtonsDefined)
    elements.canvas.cuepool.noCueLabel.Visible = shouldHideNoCueLabel

    if isApiEnabled and not noCustomButtonsDefined then
        local cueTemplate = elements.templates.cueButton

        for i, cue in Configuration.customButtons do
            local clone = cueTemplate:Clone()

            local name = cue.name or "cue"
            local link = cue.link or "cuelink"
            local onClick = cue.onClick or {"MouseButton1Click"}
            local textColor = cue.textColor or DEFAULT_TEXT_COLOR
            local strokeColor = cue.strokeColor or DEFAULT_STROKE_COLOR
            local textTransparency = cue.textTransparency or DEFAULT_TEXT_TRANSPARENCY
            local strokeTransparency = cue.strokeTransparency or DEFAULT_STROKE_TRANSPARENCY

            clone.Parent = elements.canvas.cuepool.master
            clone.Name = ("custom-cue: %s"):format(name)
            clone.Text = name
            local cueIndex = clone:FindFirstChild("cueIndex", true)
            cueIndex.Text = i

            clone.TextColor3 = textColor
            clone.TextTransparency = textTransparency
            clone.Visible = true

            local stroke = clone:FindFirstChild("UIStroke", true)
            stroke.Color = strokeColor
            stroke.Transparency = strokeTransparency

            for index, _name in onClick do
                clone[_name]:Connect(function()
                    eventsFolder.Listener:FireServer("customCallback", { callbackName = link, index = index })
                end)
            end
        end
    end
end

local function initButtonAnimation(buttons)
    local objects = {}

    for _, element in buttons:GetDescendants() do
        if element:IsA("TextButton") then
            if element:GetAttribute("ignore") then continue end
           objects[#objects + 1] = element
        end

        if element:IsA("ImageButton") then
            if element:GetAttribute("ignore") then continue end
            objects[#objects + 1] = element
        end
    end

    for _, element in objects do
        local object = element:IsA("ImageButton") and element or element:FindFirstChild("UIStroke")
        local dictionary = element:IsA("ImageButton") and "ImageColor3" or "Thickness"
        local value = element:IsA("ImageButton") and Color3.new(0.533333, 0.533333, 0.533333) or 3.2
        local returnValue = element:IsA("ImageButton") and Color3.new(1, 1, 1) or 6.1

        FADE_TIME = .65

        element.MouseEnter:Connect(function()
            TweenService:Create(object,
                TweenInfo.new(
                    FADE_TIME, Enum.EasingStyle.Quint
                ),
                { [dictionary] = value }
            ):Play()
        end)

        element.MouseLeave:Connect(function()
            TweenService:Create(object,
                TweenInfo.new(
                    FADE_TIME, Enum.EasingStyle.Quint
                ),
                { [dictionary] = returnValue }
            ):Play()
        end)
    end
end

local function linkFrameButtons(elements)
    for frameName, button in elements.frameButtons do
        button.MouseButton1Click:Connect(function()
            handlePageChange(button:GetAttribute("mode"), frameName, elements.frames)
        end)
    end
end

local function setupColorPicker(elements)
    Utility:generateColorPicker({
        sensor = elements.canvas.main.color.picker.sensor,
        pointer = elements.canvas.main.color.picker.pointer,
        backpointer = elements.canvas.main.color.picker.backpointer,
        indicator = elements.canvas.main.color.indicator,
        callback = {
            function(color)
                eventsFolder.Listener:FireServer("color", {
                    color = color,
                    colorMode = storage.colorMode
                })
            end,
            function(color)
                eventsFolder.Listener:FireServer("colorFX", color)
            end
        }
    })
end

local function setupFaderConnections(elements)
    local faderConnections = {
        ["bpm"] = function(arguments)
            return eventsFolder.Listener:FireServer("bpm", {
                valueName = arguments.faderName,
                value = arguments.value
            })
        end,
        ["phase"] = function(arguments)
            local functionalityOfPhase = arguments.faderName:sub(0, -7)

            return eventsFolder.Listener:FireServer("phase", {
                phaseName = functionalityOfPhase,
                value = arguments.value
            })
        end,
        ["fade"] = function(arguments)
            return eventsFolder.Listener:FireServer("fade", {
                value = arguments.value
            })
        end
    }

    local faders = elements.canvas.main.fader:GetChildren()

    for _, fader in faders do
        if not fader:IsA("Frame") then
            continue
        end

        Utility:generateFader({
            sensorPos = fader.Fader.AbsolutePosition,
            sensorSize = fader.Fader.AbsoluteSize,
            frame = fader.Fader,
            typeOfFader = fader:GetAttribute("typeOfFader"),
            faderScale = fader:GetAttribute("faderScale") or "grandScale",
            multiplier = fader:GetAttribute("multiplier") or 1,
            valueLabel = fader.Fader["Fader Value"],
            connection = function(value)
                local loweredFaderName = string.lower(fader.Name)
                local typeOfFader = fader:GetAttribute("typeOfFader")

                faderConnections[typeOfFader]({
                    value = value,
                    faderName = loweredFaderName
                })
            end,
            faderInstance = fader.Fader.Frame
        })
    end
end

local function initializeEffectButtons(elements)
    local indicator = elements.templates.Indicator:Clone()
    local effectButtons = elements.canvas.main.effect:GetChildren()

    for _, button in effectButtons do
        if not button:IsA("TextButton") then
            continue
        end

        button.MouseButton1Click:Connect(function()
            local effectName = button:GetAttribute("effectName")
            if not effectName then
                return
            end

            local on = not storage.effects[effectName]
            local data = Utility:getFXArchetype("solo", { { button, effectName, on } })
            eventsFolder.Listener:FireServer("effect", data)
        end)

        button.MouseButton2Click:Connect(function()
            indicator.Parent = button
            storage.currentButton = button

            if not indicator.Visible then
                indicator.Visible = true
            end
        end)
    end
end

local function setupMiscButtons(elements)
    elements.canvas.main.master.Reset.MouseButton1Down:Connect(function()
        eventsFolder.Listener:FireServer("reset")
    end)

    elements.canvas.main.carousel.pushRight.MouseButton1Down:Connect(function()
        advanceCarousel(elements.canvas.main.effect)
    end)

    elements.canvas.main.carousel.pushLeft.MouseButton1Down:Connect(function()
        reverseCarousel(elements.canvas.main.effect)
    end)

    elements.canvas.main.master["Hold Effect"].MouseButton1Down:Connect(function()
        if storage.currentButton == nil then return end
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { storage.currentButton, storage.currentButton:GetAttribute("effectName"), true } }
        ))
    end)

    elements.canvas.main.master["Hold Effect"].MouseButton1Up:Connect(function()
        if storage.currentButton == nil then return end
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { storage.currentButton, storage.currentButton:GetAttribute("effectName"), false } }
        ))
    end)

    elements.canvas.main.master["Hold Effect"].MouseButton2Down:Connect(function()
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { elements.canvas.main.effect["c_Strobe"], "Strobe", true } }
        ))
    end)

    elements.canvas.main.master["Hold Effect"].MouseButton2Up:Connect(function()
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { elements.canvas.main.effect["c_Strobe"], "Strobe", false } }
        ))
    end)

    elements.canvas.main.master["Hold Strobe"].MouseButton1Down:Connect(function()
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { elements.canvas.main.effect["c_Strobe"], "Strobe", true } }
        ))
    end)

    elements.canvas.main.master["Hold Strobe"].MouseButton1Up:Connect(function()
        eventsFolder.Listener:FireServer("effect", Utility:getFXArchetype(
            "solo",
            { { elements.canvas.main.effect["c_Strobe"], "Strobe", false } }
        ))
    end)

    elements.canvas.main.master.Spotlight.MouseButton1Click:Connect(function()
        eventsFolder.Listener:FireServer("spot", true)
    end)

    elements.canvas.main.master.Spotlight.MouseButton2Click:Connect(function()
        eventsFolder.Listener:FireServer("spot", false)
    end)
end

local function setupColorButtons(elements)
    local colorButtons =  elements.canvas.main.color.buttons

    local function setColorMode(mode)
        storage.colorMode = mode
        Utility:setTextColor3(
            colorButtons[mode], {colorButtons.all, colorButtons.even, colorButtons.odd},
            Color3.new(0, 1, 0),Color3.new(1, 1, 1)
        )

        eventsFolder.Listener:FireServer("color", { changing = true, colorMode = storage.colorMode })
    end

    colorButtons.all.MouseButton1Click:Connect(function()
        setColorMode("all")
    end)
    colorButtons.even.MouseButton1Click:Connect(function()
        setColorMode("even")
    end)
    colorButtons.odd.MouseButton1Click:Connect(function()
        setColorMode("odd")
    end)
end

local function initializeRipple(screen, enabled)
    if not enabled then
        return
    end

    for _, button in screen:GetDescendants() do
        if button:IsA("TextButton") then
            if button:GetAttribute("ignore") then
                continue
            end

            Utility:registerRippleListener(button)
        end
    end
end

function initializeElements()
    local screen = panelsFolder:FindFirstChildWhichIsA("Part")
    local elements = initializeUIElements(screen)

    generatePositionButtons(elements)
    setupCustomCueButtons(elements)

    initializeCarousel(elements.canvas.main.effect)
    updateEffectLabels(elements.canvas.main.effect)
    initializeEffectButtons(elements)

    setupColorPicker(elements)
    setupFaderConnections(elements)
    setupColorButtons(elements)

    linkFrameButtons(elements)
    setupAboutLabels(elements)
    setupMiscButtons(elements)

    initializeRipple(screen, Configuration.stylistic.ripple)
    Utility:registerDimmerButtons(elements.canvas.main.master, eventsFolder)

    if not Configuration.stylistic.strokeAnimations then
        return
    end

    initButtonAnimation(getInterface(screen).holster)
end

function listenToEvents()
    eventsFolder.Data.Event:Connect(function(arguments)
        for _, effectData in arguments.effects do
            local data = { effectName = effectData.effectName, buttonReference = effectData.buttonReference, on = effectData.on }
            changeEffectStatus(data)
        end
    end)
end

function main()
    initializeElements()
    listenToEvents()
end

main()

