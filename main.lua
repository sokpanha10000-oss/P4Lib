-- BTUI Library (Dark Green Nexus Theme v3 - Fixed Slider Knob & TopBar Layout)
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local function IsExploit()
    return request and true or false
end

local function Get(url)
    if IsExploit() then
        return game:HttpGet(url)
    else
        local Success, Result = pcall(function() return HttpService:GetAsync(url) end)
        if Success then return Result else return ReplicatedStorage:WaitForChild("Request", 9999):InvokeServer({ Url = url }) end
    end
end

local function Loadstring(src)
    if not IsExploit() and ReplicatedStorage:WaitForChild("Loadstring", 9999) then
        return function() return ReplicatedStorage:WaitForChild("Loadstring", 9999):InvokeServer(src) end
    else
        return loadstring(src)
    end
end

-- [ Start: Integrated IconModule ] --
local IconModule = {
    IconsType = "lucide",
    New = nil,
    IconThemeTag = nil,
    Icons = {},
}

pcall(function()
    IconModule.Icons.lucide = IsExploit() and Loadstring(
        Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua")
    )() or require("./lucide/dist/Icons")
end)

local function parseIconString(iconString)
    if type(iconString) == "string" then
        local splitIndex = iconString:find(":")
        if splitIndex then
            return iconString:sub(1, splitIndex - 1), iconString:sub(splitIndex + 1)
        end
    end
    return nil, iconString
end

function IconModule.AddIcons(packName, iconsData)
    if type(packName) ~= "string" or type(iconsData) ~= "table" then return end
    if not IconModule.Icons[packName] then IconModule.Icons[packName] = { Icons = {}, Spritesheets = {} } end
    for iconName, iconValue in pairs(iconsData) do
        if type(iconValue) == "number" or (type(iconValue) == "string" and iconValue:match("^rbxassetid://")) then
            local imageId = type(iconValue) == "number" and "rbxassetid://" .. tostring(iconValue) or iconValue
            IconModule.Icons[packName].Icons[iconName] = { Image = imageId, ImageRectSize = Vector2.new(0, 0), ImageRectPosition = Vector2.new(0, 0), Parts = nil }
            IconModule.Icons[packName].Spritesheets[imageId] = imageId
        elseif type(iconValue) == "table" and iconValue.Image and iconValue.ImageRectSize and iconValue.ImageRectPosition then
            local imageId = type(iconValue.Image) == "number" and "rbxassetid://" .. tostring(iconValue.Image) or iconValue.Image
            IconModule.Icons[packName].Icons[iconName] = { Image = imageId, ImageRectSize = iconValue.ImageRectSize, ImageRectPosition = iconValue.ImageRectPosition, Parts = iconValue.Parts }
            if not IconModule.Icons[packName].Spritesheets[imageId] then IconModule.Icons[packName].Spritesheets[imageId] = imageId end
        end
    end
end

function IconModule.Init(New, IconThemeTag)
    IconModule.New = New
    IconModule.IconThemeTag = IconThemeTag
    return IconModule
end

function IconModule.Icon(Icon, Type, DefaultFormat)
    DefaultFormat = DefaultFormat ~= false
    local iconType, iconName = parseIconString(Icon)
    local targetType = iconType or Type or IconModule.IconsType
    local iconSet = IconModule.Icons[targetType]
    if iconSet and iconSet.Icons and iconSet.Icons[iconName] then
        return { iconSet.Spritesheets[tostring(iconSet.Icons[iconName].Image)], iconSet.Icons[iconName] }
    elseif iconSet and iconSet[iconName] and string.find(iconSet[iconName], "rbxassetid://") then
        return DefaultFormat and { iconSet[iconName], { ImageRectSize = Vector2.new(0, 0), ImageRectPosition = Vector2.new(0, 0) } } or iconSet[iconName]
    end
    return nil
end

function IconModule.Icon2(Icon, Type, DefaultFormat) return IconModule.Icon(Icon, Type, true) end

function IconModule.Image(IconConfig)
    local Icon = {
        Icon = IconConfig.Icon or nil, Type = IconConfig.Type,
        Colors = IconConfig.Colors or { (IconModule.IconThemeTag or Color3.new(1, 1, 1)), Color3.new(1, 1, 1) },
        Size = IconConfig.Size or UDim2.new(0, 24, 0, 24), IconFrame = nil,
    }
    local Colors = {}
    for _, color in next, Icon.Colors do
        Colors[_] = { ThemeTag = typeof(color) == "string" and color, Color = typeof(color) == "Color3" and color }
    end
    local IconLabel = IconModule.Icon2(Icon.Icon, Icon.Type)
    local isrbxassetid = typeof(IconLabel) == "string" and string.find(IconLabel, "rbxassetid://")
    
    if IconModule.New then
        local New = IconModule.New
        local IconFrame = New("ImageLabel", {
            Size = Icon.Size, BackgroundTransparency = 1,
            ImageColor3 = Colors[1] and Colors[1].Color or nil,
            Image = isrbxassetid and IconLabel or (IconLabel and IconLabel[1]),
            ImageRectSize = isrbxassetid and nil or (IconLabel and IconLabel[2].ImageRectSize),
            ImageRectOffset = isrbxassetid and nil or (IconLabel and IconLabel[2].ImageRectPosition),
        })
        if not isrbxassetid and IconLabel and IconLabel[2].Parts then
            for _, part in next, IconLabel[2].Parts do
                local IconPartLabel = IconModule.Icon(part, Icon.Type)
                New("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = IconFrame,
                    ImageColor3 = Colors[1 + _] and Colors[1 + _].Color or nil,
                    Image = IconPartLabel[1], ImageRectSize = IconPartLabel[2].ImageRectSize,
                    ImageRectOffset = IconPartLabel[2].ImageRectPosition,
                })
            end
        end
        Icon.IconFrame = IconFrame
    else
        local IconFrame = Instance.new("ImageLabel")
        IconFrame.Size = Icon.Size; IconFrame.BackgroundTransparency = 1
        IconFrame.ImageColor3 = Colors[1] and Colors[1].Color
        IconFrame.Image = isrbxassetid and IconLabel or (IconLabel and IconLabel[1])
        IconFrame.ImageRectSize = isrbxassetid and nil or (IconLabel and IconLabel[2].ImageRectSize)
        IconFrame.ImageRectOffset = isrbxassetid and nil or (IconLabel and IconLabel[2].ImageRectPosition)
        if not isrbxassetid and IconLabel and IconLabel[2].Parts then
            for _, part in next, IconLabel[2].Parts do
                local IconPartLabel = IconModule.Icon(part, Icon.Type)
                local IconPart = Instance.new("ImageLabel")
                IconPart.Size = UDim2.new(1, 0, 1, 0); IconPart.BackgroundTransparency = 1
                IconPart.ImageColor3 = Colors[1 + _] and Colors[1 + _].Color
                IconPart.Image = IconPartLabel[1]; IconPart.ImageRectSize = IconPartLabel[2].ImageRectSize
                IconPart.ImageRectOffset = IconPartLabel[2].ImageRectPosition
                IconPart.Parent = IconFrame
            end
        end
        Icon.IconFrame = IconFrame
    end
    return Icon
end
-- [ End: Integrated IconModule ] --

local BTUI = {}

-- Theme Colors
local Theme = {
    BgDark = Color3.fromRGB(20, 20, 23),
    BgDarker = Color3.fromRGB(15, 15, 18),
    TopBar = Color3.fromRGB(25, 25, 28),
    Stroke = Color3.fromRGB(45, 45, 50),
    GreenAccent = Color3.fromRGB(0, 255, 128),
    GreenDark = Color3.fromRGB(30, 60, 45),
    TextWhite = Color3.fromRGB(220, 220, 230),
    TextGrey = Color3.fromRGB(140, 140, 150),
    Hover = Color3.fromRGB(35, 35, 40)
}

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

IconModule.Init(Create, nil)

-- Smart icon handler
local function SmartIcon(iconStr, iconType, size, color, parent, position)
    local inst = nil
    if type(iconStr) == "number" or (type(iconStr) == "string" and iconStr:match("^%d+$")) then
        inst = Create("ImageLabel", {
            Parent = parent, BackgroundTransparency = 1, Size = size, Position = position,
            Image = "rbxassetid://" .. tostring(iconStr), ImageColor3 = color or Color3.new(1,1,1)
        })
    elseif type(iconStr) == "string" and iconStr:match("^rbxassetid://") then
        inst = Create("ImageLabel", {
            Parent = parent, BackgroundTransparency = 1, Size = size, Position = position,
            Image = iconStr, ImageColor3 = color or Color3.new(1,1,1)
        })
    else
        local success, iconObj = pcall(function()
            return IconModule.Image({
                Icon = iconStr, Type = iconType or "lucide",
                Size = size, Colors = { color or Color3.fromRGB(255, 255, 255) }
            })
        end)
        if success and iconObj and iconObj.IconFrame then
            inst = iconObj.IconFrame
            inst.Parent = parent
            inst.Position = position or UDim2.new(0, 0, 0, 0)
            if color then inst.ImageColor3 = color end
        else
            inst = Create("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Size = size, Position = position, Image = "" })
        end
    end
    return inst
end

local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

function BTUI:CreateWindow(config)
    local ScreenGui = Create("ScreenGui", { Name = "BTUI_" .. tostring(math.random(1000, 9999)), Parent = CoreGui, ResetOnSpawn = false })

    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = ScreenGui, BackgroundColor3 = Theme.BgDark, BackgroundTransparency = 0.1,
        Size = UDim2.new(0, 550, 0, 340), Position = UDim2.new(0.5, -275, 0.5, -170), Active = true
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    Create("UIStroke", { Color = Theme.Stroke, Thickness = 1.5, Parent = MainFrame })
    MakeDraggable(MainFrame)

    local TopBar = Create("Frame", {
        Name = "TopBar", Parent = MainFrame, BackgroundColor3 = Theme.TopBar, BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TopBar })
    Create("Frame", { Parent = TopBar, BackgroundColor3 = Theme.Stroke, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0 })

    SmartIcon(config.Image, "lucide", UDim2.new(0, 20, 0, 20), Theme.GreenAccent, TopBar, UDim2.new(0, 10, 0.5, -10))
    
    -- Title now takes dynamic width but stops before the search bar
    Create("TextLabel", {
        Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1, -240, 0, 20), Position = UDim2.new(0, 35, 0.5, -10),
        Font = Enum.Font.GothamBold, Text = config.Title or "Script Hub", TextColor3 = Theme.TextWhite,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
    })

    if config.Subtitle then
        Create("TextLabel", {
            Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1, -240, 0, 12), Position = UDim2.new(0, 35, 0.5, 2),
            Font = Enum.Font.Gotham, Text = config.Subtitle, TextColor3 = Theme.TextGrey,
            TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
        })
    end

    local SearchBar
    if config.SearchBar then
        SearchBar = Create("TextBox", {
            Parent = TopBar, BackgroundColor3 = Theme.BgDarker, Size = UDim2.new(0, 150, 0, 25), Position = UDim2.new(1, -220, 0.5, -12.5),
            PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextColor3 = Theme.TextWhite,
            TextSize = 12, PlaceholderColor3 = Theme.TextGrey, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBar })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 30), Parent = SearchBar })
        local SIcon = SmartIcon("search", "lucide", UDim2.new(0, 15, 0, 15), Theme.TextGrey, SearchBar, UDim2.new(0, 8, 0.5, -7.5))
        if SIcon then SIcon.ZIndex = 3 end
    end

    local CloseBtn = Create("TextButton", {
        Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -35, 0.5, -12.5),
        Text = "", AutoButtonColor = false, ZIndex = 2
    })
    local CloseIcon = SmartIcon("x", "lucide", UDim2.new(0, 18, 0, 18), Theme.TextGrey, CloseBtn, UDim2.new(0.5, -9, 0.5, -9))
    if CloseIcon then CloseIcon.ZIndex = 3 end
    CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 50, 50)}):Play() end)
    CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseIcon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextGrey}):Play() end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local TabContainer = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = Theme.TopBar, BackgroundTransparency = 0,
        Size = UDim2.new(0, 140, 1, -50), Position = UDim2.new(0, 10, 0, 45), BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabContainer })
    
    local TabList = Create("ScrollingFrame", {
        Parent = TabContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, BorderSizePixel = 0
    })
    Create("UIListLayout", { Parent = TabList, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

    local ElementContainer = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = Theme.BgDark, BackgroundTransparency = 0,
        Size = UDim2.new(1, -170, 1, -50), Position = UDim2.new(0, 160, 0, 45), BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ElementContainer })
    local Pages = Create("Folder", { Parent = ElementContainer })

    local Window = {}
    local Tabs = {}

    function Window:CreateMinimizeBtn(btnConfig)
        local FloatBtn = Create("TextButton", {
            Parent = ScreenGui, BackgroundColor3 = Theme.BgDark, Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0, 50, 0, 50), Text = "", Active = true
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = FloatBtn })
        Create("UIStroke", { Color = Theme.GreenDark, Thickness = 1.5, Parent = FloatBtn })
        local FIcon = SmartIcon(btnConfig.Image or "home", "lucide", UDim2.new(0, 25, 0, 25), Theme.GreenAccent, FloatBtn, UDim2.new(0.5, -12.5, 0.5, -12.5))
        
        MakeDraggable(FloatBtn)
        local isMinimized = false
        FloatBtn.MouseButton1Click:Connect(function()
            isMinimized = not isMinimized
            if isMinimized then
                MainFrame.Size = UDim2.new(0, 550, 0, 340)
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
                }):Play()
                task.wait(0.3)
                MainFrame.Visible = false
            else
                MainFrame.Visible = true
                MainFrame.Size = UDim2.new(0, 0, 0, 0)
                MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 550, 0, 340), Position = UDim2.new(0.5, -275, 0.5, -170)
                }):Play()
            end
        end)
        return FloatBtn
    end

    function Window:CreateTab(tabConfig)
        local tabName = tabConfig[1]
        local iconName = tabConfig[2] or "home"
        
        local TabBtn = Create("TextButton", {
            Parent = TabList, BackgroundColor3 = Theme.Hover, BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 0, 0), Text = "", AutoButtonColor = false
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TabBtn })
        
        local Icon = SmartIcon(iconName, "lucide", UDim2.new(0, 16, 0, 16), Theme.TextGrey, TabBtn, UDim2.new(0, 8, 0.5, -8))
        local Label = Create("TextLabel", {
            Parent = TabBtn, BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0),
            Font = Enum.Font.GothamSemibold, Text = tabName, TextColor3 = Theme.TextGrey,
            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
        })

        local Page = Create("ScrollingFrame", {
            Parent = Pages, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10),
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, Visible = false, BorderSizePixel = 0
        })
        Create("UIListLayout", { Parent = Page, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

        if #Tabs == 0 then
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            Page.Visible = true
            Label.TextColor3 = Theme.GreenAccent
            if Icon then Icon.ImageColor3 = Theme.GreenAccent end
        end

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                t.Page.Visible = false
                t.Label.TextColor3 = Theme.TextGrey
                if t.Icon then t.Icon.ImageColor3 = Theme.TextGrey end
            end
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            Page.Visible = true
            Label.TextColor3 = Theme.GreenAccent
            if Icon then Icon.ImageColor3 = Theme.GreenAccent end
            
            if SearchBar then SearchBar.Text = "" end
            for _, child in pairs(Page:GetChildren()) do
                if child:IsA("Frame") then child.Visible = true end
            end
        end)

        if SearchBar then
            SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
                if Page.Visible then
                    local search = string.lower(SearchBar.Text)
                    for _, elem in pairs(Page:GetChildren()) do
                        if elem:IsA("Frame") and elem:FindFirstChild("Title") then
                            elem.Visible = string.find(string.lower(elem.Title.Text), search) ~= nil
                        end
                    end
                end
            end)
        end

        local Tab = {}
        table.insert(Tabs, {Button = TabBtn, Page = Page, Label = Label, Icon = Icon})

        function Tab:CreateButton(bConfig)
            local BtnFrame = Create("Frame", { Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35) })
            Create("TextLabel", {
                Name = "Title", Parent = BtnFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                Font = Enum.Font.GothamSemibold, Text = bConfig.Title or "Button", TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
            })
            local Btn = Create("TextButton", {
                Parent = BtnFrame, BackgroundColor3 = Theme.Hover, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })
            Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play() end)
            Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end)
            Btn.MouseButton1Click:Connect(function()
                if not bConfig.Locked then
                    TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.GreenDark, BackgroundTransparency = 0}):Play()
                    task.wait(0.1)
                    TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 1}):Play()
                    if bConfig.Callback then bConfig.Callback() end
                end
            end)
        end

        function Tab:CreateToggle(tConfig)
            local ToggleFrame = Create("Frame", { Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35) })
            local Title = Create("TextLabel", {
                Name = "Title", Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                Font = Enum.Font.GothamSemibold, Text = tConfig.Title or "Toggle", TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
            })
            local Switch = Create("TextButton", {
                Parent = ToggleFrame, BackgroundColor3 = Theme.Hover, Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10), Text = "", AutoButtonColor = false
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })
            local Knob = Create("Frame", { Parent = Switch, BackgroundColor3 = Theme.TextGrey, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 2, 0.5, -8) })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
            
            local state = tConfig.Value or false
            local function UpdateToggle(anim)
                local info = anim and TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out) or TweenInfo.new(0)
                if state then
                    TweenService:Create(Switch, info, {BackgroundColor3 = Theme.GreenAccent}):Play()
                    TweenService:Create(Knob, info, {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
                else
                    TweenService:Create(Switch, info, {BackgroundColor3 = Theme.Hover}):Play()
                    TweenService:Create(Knob, info, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Theme.TextGrey}):Play()
                end
            end
            UpdateToggle(false)
            Switch.MouseButton1Click:Connect(function() state = not state; UpdateToggle(true); if tConfig.Callback then tConfig.Callback(state) end end)
        end

        function Tab:CreateSlider(sConfig)
            local SliderFrame = Create("Frame", { Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45) })
            local Title = Create("TextLabel", {
                Name = "Title", Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 5),
                Font = Enum.Font.GothamSemibold, Text = sConfig.Title or "Slider", TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
            })
            local ValLabel = Create("TextLabel", {
                Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -60, 0, 5),
                Font = Enum.Font.Gotham, Text = tostring(sConfig.Value.Default), TextColor3 = Theme.GreenAccent,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right
            })
            
            -- Hitbox for easier dragging
            local Hitbox = Create("TextButton", {
                Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 25),
                Text = "", AutoButtonColor = false
            })
            
            local Track = Create("Frame", { Parent = Hitbox, BackgroundColor3 = Theme.Hover, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), ZIndex = 2 })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
            local Fill = Create("Frame", { Parent = Track, BackgroundColor3 = Theme.GreenAccent, Size = UDim2.new(0, 0, 1, 0), ZIndex = 3 })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
            
            -- Added Slider Knob (Handle)
            local Knob = Create("Frame", { 
                Parent = Track, BackgroundColor3 = Color3.fromRGB(255, 255, 255), 
                Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), ZIndex = 4 
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
            
            local dragging = false
            local min, max, step = sConfig.Value.Min, sConfig.Value.Max, sConfig.Step or 1
            
            local function update(input)
                local perc = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * perc
                if step >= 1 then val = math.floor(val / step) * step end
                val = math.clamp(val, min, max)
                
                -- Recalculate percentage based on the snapped value
                local steppedPerc = (val - min) / (max - min)
                Fill.Size = UDim2.new(steppedPerc, 0, 1, 0)
                Knob.Position = UDim2.new(steppedPerc, -7, 0.5, -7) -- Center knob on the line
                
                ValLabel.Text = string.format(step < 1 and "%.1f" or "%d", val)
                if sConfig.Callback then sConfig.Callback(val) end
            end
            
            Hitbox.InputBegan:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    -- Scale up knob on drag
                    TweenService:Create(Knob, TweenInfo.new(0.2), {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(Knob.Position.X.Scale, -9, 0.5, -9)}):Play()
                    update(input) 
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        -- Scale down knob on release
                        TweenService:Create(Knob, TweenInfo.new(0.2), {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(Knob.Position.X.Scale, -7, 0.5, -7)}):Play()
                    end
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
        end

        function Tab:CreateInput(iConfig)
            local InputFrame = Create("Frame", { Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35) })
            local Title = Create("TextLabel", {
                Name = "Title", Parent = InputFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                Font = Enum.Font.GothamSemibold, Text = iConfig.Title or "Input", TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
            })
            local Box = Create("TextBox", {
                Parent = InputFrame, BackgroundColor3 = Theme.BgDarker, Size = UDim2.new(1, -120, 0, 25), Position = UDim2.new(0, 110, 0.5, -12.5),
                Text = iConfig.Value or "", PlaceholderText = iConfig.Placeholder or "Enter...", Font = Enum.Font.Gotham,
                TextColor3 = Theme.TextWhite, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 5), Parent = Box })
            Box.FocusLost:Connect(function() if iConfig.Callback then iConfig.Callback(Box.Text) end end)
        end

        function Tab:CreateDropdown(dConfig)
            local DropFrame = Create("Frame", { Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35) })
            local Title = Create("TextLabel", {
                Name = "Title", Parent = DropFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                Font = Enum.Font.GothamSemibold, Text = dConfig.Title or "Dropdown", TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
            })
            local ValBtn = Create("TextButton", {
                Parent = DropFrame, BackgroundColor3 = Theme.BgDarker, Size = UDim2.new(1, -120, 0, 25), Position = UDim2.new(0, 110, 0.5, -12.5),
                Text = dConfig.Value or "Select...", Font = Enum.Font.Gotham, TextColor3 = Theme.GreenAccent,
                TextSize = 12, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ValBtn })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 5), Parent = ValBtn })

            local Dropdown = {}
            local isOpen = false
            local currentValues = dConfig.Values or {}

            local DropBg = Create("TextButton", {
                Parent = ScreenGui, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, Visible = false, ZIndex = 5
            })

            local DropGUI = Create("Frame", {
                Parent = ScreenGui, BackgroundColor3 = Theme.BgDark, BackgroundTransparency = 0.05,
                Size = UDim2.new(0, 250, 0, 250), Position = UDim2.new(0.5, -125, 0.5, -125), Visible = false, ZIndex = 6
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropGUI })
            Create("UIStroke", { Color = Theme.GreenDark, Thickness = 1, Parent = DropGUI })
            
            local Search = Create("TextBox", {
                Parent = DropGUI, BackgroundColor3 = Theme.BgDarker, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 10),
                PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextColor3 = Theme.TextWhite,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Search })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 30), Parent = Search })
            local SIcon2 = SmartIcon("search", "lucide", UDim2.new(0, 15, 0, 15), Theme.TextGrey, Search, UDim2.new(0, 8, 0.5, -7.5))
            if SIcon2 then SIcon2.ZIndex = 8 end
            
            local List = Create("ScrollingFrame", {
                Parent = DropGUI, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -50), Position = UDim2.new(0, 10, 0, 50),
                CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, BorderSizePixel = 0, ZIndex = 7
            })
            Create("UIListLayout", { Parent = List, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

            local function Populate(val)
                for _, v in pairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, v in pairs(val) do
                    local Btn = Create("TextButton", {
                        Parent = List, BackgroundColor3 = Theme.BgDarker, Size = UDim2.new(1, 0, 0, 30),
                        Text = "", AutoButtonColor = false, ZIndex = 7
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })
                    Create("TextLabel", {
                        Parent = Btn, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                        Text = v, Font = Enum.Font.Gotham, TextColor3 = Theme.TextWhite,
                        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8
                    })
                    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Hover}):Play() end)
                    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.BgDarker}):Play() end)
                    Btn.MouseButton1Click:Connect(function()
                        ValBtn.Text = v
                        if dConfig.Callback then dConfig.Callback(v) end
                        ToggleDropdown(false)
                    end)
                end
            end

            function ToggleDropdown(state)
                isOpen = state
                if isOpen then
                    DropGUI.Visible = true
                    DropBg.Visible = true
                    DropGUI.Size = UDim2.new(0, 0, 0, 0)
                    DropGUI.Position = UDim2.new(0.5, 0, 0.5, 0)
                    TweenService:Create(DropBg, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
                    TweenService:Create(DropGUI, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 250, 0, 250), Position = UDim2.new(0.5, -125, 0.5, -125)
                    }):Play()
                    Populate(currentValues)
                else
                    TweenService:Create(DropBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(DropGUI, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                        Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
                    }):Play()
                    task.wait(0.2)
                    DropGUI.Visible = false
                    DropBg.Visible = false
                end
            end

            ValBtn.MouseButton1Click:Connect(function() ToggleDropdown(not isOpen) end)
            DropBg.MouseButton1Click:Connect(function() ToggleDropdown(false) end)
            
            Search:GetPropertyChangedSignal("Text"):Connect(function()
                local filtered = {}
                for _, v in pairs(currentValues) do
                    if string.find(string.lower(v), string.lower(Search.Text)) then table.insert(filtered, v) end
                end
                Populate(filtered)
            end)

            function Dropdown:Refresh(newValues)
                currentValues = newValues
                if isOpen then Populate(currentValues) end
            end

            Populate(currentValues)
            return Dropdown
        end

        return Tab
    end

    return Window
end

return BTUI
