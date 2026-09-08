--//========================================================
--// DarkyUI
--// Clean Single-File UI Library
--//========================================================
--//
--// Features:
--// • 550x340 main window
--// • PC + Mobile dragging
--// • Draggable floating minimize button
--// • Minimize / Restore
--// • Close / Destroy
--// • Square corners
--// • Search bar
--// • Profile + Username
--// • Lucide icons
--// • Asset ID icons
--// • Tabs
--// • Auto-sized sections
--// • Multiple sections
--// • Automatic scrolling
--// • Button
--// • Toggle
--// • Slider
--// • Input
--// • Dropdown
--// • Dropdown search
--// • Dropdown scrolling
--// • Dropdown Refresh
--// • Key System
--// • Key validation
--// • SaveKey
--// • Get Key clipboard
--// • Thumbnail
--//
--//========================================================

local DarkyUI = {}

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

--========================================================
-- CONSTANTS
--========================================================

local UI_NAME = "DarkyUI"

local DEFAULT_WINDOW_SIZE =
    UDim2.fromOffset(550, 340)

local COLORS = {
    Background = Color3.fromRGB(18, 18, 21),
    Background2 = Color3.fromRGB(23, 23, 27),

    Panel = Color3.fromRGB(29, 29, 34),
    Panel2 = Color3.fromRGB(35, 35, 41),

    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(160, 160, 170),
    Muted = Color3.fromRGB(105, 105, 115),

    Border = Color3.fromRGB(52, 52, 61),

    Accent = Color3.fromRGB(70, 125, 255),
    Accent2 = Color3.fromRGB(95, 150, 255),

    Danger = Color3.fromRGB(235, 75, 85),
    Warning = Color3.fromRGB(245, 185, 70),

    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local TWEEN_FAST = TweenInfo.new(
    0.14,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

local TWEEN_MED = TweenInfo.new(
    0.22,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

--========================================================
-- BASIC HELPERS
--========================================================

local function New(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function Tween(object, info, properties)
    if not object or not object.Parent then
        return
    end

    local tween = TweenService:Create(
        object,
        info,
        properties
    )

    tween:Play()

    return tween
end

local function AddStroke(parent, color, thickness)
    return New("UIStroke", {
        Parent = parent,
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function AddPadding(
    parent,
    left,
    right,
    top,
    bottom
)
    return New("UIPadding", {
        Parent = parent,

        PaddingLeft =
            UDim.new(0, left or 0),

        PaddingRight =
            UDim.new(0, right or 0),

        PaddingTop =
            UDim.new(0, top or 0),

        PaddingBottom =
            UDim.new(0, bottom or 0),
    })
end

local function IsAssetId(value)
    if typeof(value) ~= "string" then
        return false
    end

    return value:match("^rbxassetid://")
        or value:match("^%d+$")
end

local function NormalizeAssetId(value)
    if typeof(value) ~= "string" then
        return nil
    end

    if value:match("^rbxassetid://") then
        return value
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

--========================================================
-- HTTP
--========================================================

local function GetHttp(url)

    local methods = {

        function()
            return game:HttpGet(url)
        end,

        function()
            return request({
                Url = url,
                Method = "GET",
            }).Body
        end,

        function()
            return http_request({
                Url = url,
                Method = "GET",
            }).Body
        end,
    }

    for _, method in ipairs(methods) do

        local success, result =
            pcall(method)

        if success
            and result
            and result ~= "" then

            return result
        end
    end

    return nil
end

--========================================================
-- LOADSTRING
--========================================================

local function GetLoadstring()

    if typeof(loadstring) == "function" then
        return loadstring
    end

    if typeof(load) == "function" then
        return load
    end

    return nil
end

--========================================================
-- LUCIDE ICONS
--========================================================

local LUCIDE_URL =
    "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

local function LoadLucide()

    -- Supports the user's loader environment.
    local env = {}

    pcall(function()

        if typeof(getgenv) == "function" then
            env = getgenv()
        end

    end)

    if env.IsUI
        and env.Loadstring
        and env.Get then

        local success, result =
            pcall(function()

                return env.Loadstring(
                    env.Get(LUCIDE_URL)
                )()

            end)

        if success
            and type(result) == "table" then

            return result
        end
    end

    -- Fallback loader.
    local source =
        GetHttp(LUCIDE_URL)

    if not source then
        return {}
    end

    local loader =
        GetLoadstring()

    if not loader then
        return {}
    end

    local success, result =
        pcall(function()

            return loader(source)()

        end)

    if success
        and type(result) == "table" then

        return result
    end

    return {}
end

local Icons = {
    lucide = LoadLucide(),
}

DarkyUI.Icons = Icons

--========================================================
-- ICON RESOLVER
--========================================================

local function ResolveIcon(icon)

    if icon == nil then
        return nil
    end

    -- Number = asset ID
    if typeof(icon) == "number" then
        return "rbxassetid://" ..
            tostring(icon)
    end

    if typeof(icon) ~= "string" then
        return nil
    end

    -- Numeric asset ID
    if IsAssetId(icon) then
        return NormalizeAssetId(icon)
    end

    -- URL
    if icon:match("^https?://") then
        return icon
    end

    if icon:match("^rbxasset") then
        return icon
    end

    -- Exact Lucide name
    if Icons.lucide[icon] then

        return NormalizeAssetId(
            tostring(
                Icons.lucide[icon]
            )
        )
    end

    -- Case-insensitive search
    local lower =
        icon:lower()

    for name, value in pairs(
        Icons.lucide
    ) do

        if tostring(name):lower()
            == lower then

            return NormalizeAssetId(
                tostring(value)
            )
        end
    end

    return nil
end

local function CreateIcon(
    parent,
    icon,
    size,
    position,
    zIndex
)

    local asset =
        ResolveIcon(icon)

    if not asset then
        return nil
    end

    return New(
        "ImageLabel",
        {
            Parent = parent,

            BackgroundTransparency = 1,

            Position =
                position,

            Size =
                UDim2.fromOffset(
                    size,
                    size
                ),

            Image = asset,

            ImageColor3 =
                COLORS.Text,

            ScaleType =
                Enum.ScaleType.Fit,

            ZIndex =
                zIndex or 10,
        }
    )
end

--========================================================
-- PLAYER THUMBNAIL
--========================================================

local function GetProfileImage()

    local image = ""

    pcall(function()

        local content =
            Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )

        image = content or ""

    end)

    return image
end

--========================================================
-- REMOVE OLD GUI
--========================================================

pcall(function()

    local old =
        CoreGui:FindFirstChild(
            UI_NAME
        )

    if old then
        old:Destroy()
    end

end)

--========================================================
-- WINDOW
--========================================================

function DarkyUI:CreateWindow(config)

    config = config or {}

    local Window = {}

    Window.Title =
        config.Title or "DarkyUI"

    Window.Subtitle =
        config.Subtitle or ""

    Window.Image =
        config.Image

    Window.SearchEnabled =
        config.SearchBar == true

    Window.UserConfig =
        config.User or {}

    Window.Tabs = {}
    Window.Elements = {}

    Window.ActiveTab = nil

    Window.Minimized = false
    Window.Destroyed = false

    --====================================================
    -- SCREEN GUI
    --====================================================

    local ScreenGui =
        New(
            "ScreenGui",
            {
                Name = UI_NAME,

                Parent = CoreGui,

                IgnoreGuiInset = true,

                ResetOnSpawn = false,

                ZIndexBehavior =
                    Enum.ZIndexBehavior.Sibling,

                DisplayOrder = 999999,
            }
        )

    Window.Gui =
        ScreenGui

    --====================================================
    -- FLOATING BUTTON
    --====================================================

    local FloatingButton =
        New(
            "TextButton",
            {
                Parent =
                    ScreenGui,

                Name =
                    "FloatingButton",

                AnchorPoint =
                    Vector2.new(
                        0,
                        0.5
                    ),

                Position =
                    UDim2.new(
                        0,
                        18,
                        0.5,
                        0
                    ),

                Size =
                    UDim2.fromOffset(
                        52,
                        52
                    ),

                BackgroundColor3 =
                    COLORS.Panel,

                BorderSizePixel = 0,

                AutoButtonColor = false,

                Active = true,

                Text = "",

                Visible = false,

                ZIndex = 500,
            }
        )

    AddStroke(
        FloatingButton,
        COLORS.Border,
        1
    )

    local FloatingIcon =
        CreateIcon(
            FloatingButton,
            Window.Image
                or "layout-dashboard",
            24,
            UDim2.new(
                0.5,
                -12,
                0.5,
                -12
            ),
            501
        )

    if not FloatingIcon then

        New(
            "TextLabel",
            {
                Parent =
                    FloatingButton,

                BackgroundTransparency = 1,

                Size =
                    UDim2.fromScale(
                        1,
                        1
                    ),

                Text =
                    string.sub(
                        Window.Title,
                        1,
                        1
                    ):upper(),

                TextColor3 =
                    COLORS.Text,

                TextSize = 20,

                Font =
                    Enum.Font.GothamBold,

                ZIndex = 501,
            }
        )
    end

    --====================================================
    -- MAIN
    --====================================================

    local Main =
        New(
            "Frame",
            {
                Parent =
                    ScreenGui,

                Name = "Main",

                AnchorPoint =
                    Vector2.new(
                        0.5,
                        0.5
                    ),

                Position =
                    UDim2.fromScale(
                        0.5,
                        0.5
                    ),

                Size =
                    DEFAULT_WINDOW_SIZE,

                BackgroundColor3 =
                    COLORS.Background,

                BorderSizePixel = 0,

                ClipsDescendants = true,

                ZIndex = 10,
            }
        )

    Window.Main =
        Main

    AddStroke(
        Main,
        COLORS.Border,
        1
    )

    --====================================================
    -- TOP BAR
    --====================================================

    local TopBar =
        New(
            "Frame",
            {
                Parent =
                    Main,

                Name = "TopBar",

                Size =
                    UDim2.new(
                        1,
                        0,
                        0,
                        58
                    ),

                BackgroundColor3 =
                    COLORS.Background2,

                BorderSizePixel = 0,

                ZIndex = 20,
            }
        )

    AddStroke(
        TopBar,
        COLORS.Border,
        1
    )

    --====================================================
    -- MAIN DRAG
    --====================================================

    do

        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        local function UpdateDrag(input)

            if not dragging then
                return
            end

            local delta =
                input.Position
                - dragStart

            Main.Position =
                UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset
                        + delta.X,

                    startPosition.Y.Scale,
                    startPosition.Y.Offset
                        + delta.Y
                )
        end

        TopBar.InputBegan:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.MouseButton1
                    or input.UserInputType ==
                    Enum.UserInputType.Touch then

                    dragging = true

                    dragStart =
                        input.Position

                    startPosition =
                        Main.Position

                    dragInput = input

                    input.Changed:Connect(
                        function()

                            if input.UserInputState ==
                                Enum.UserInputState.End then

                                dragging = false
                            end

                        end
                    )
                end

            end
        )

        TopBar.InputChanged:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                    or input.UserInputType ==
                    Enum.UserInputType.Touch then

                    dragInput = input
                end

            end
        )

        UserInputService.InputChanged:Connect(
            function(input)

                if input == dragInput then
                    UpdateDrag(input)
                end

            end
        )
    end

    --====================================================
    -- WINDOW ICON
    --====================================================

    local WindowIconHolder =
        New(
            "Frame",
            {
                Parent =
                    TopBar,

                BackgroundTransparency = 1,

                Position =
                    UDim2.fromOffset(
                        11,
                        9
                    ),

                Size =
                    UDim2.fromOffset(
                        40,
                        40
                    ),

                ZIndex = 21,
            }
        )

    local WindowIcon =
        CreateIcon(
            WindowIconHolder,
            Window.Image
                or "layout-dashboard",
            24,
            UDim2.new(
                0.5,
                -12,
                0.5,
                -12
            ),
            22
        )

    if not WindowIcon then

        New(
            "TextLabel",
            {
                Parent =
                    WindowIconHolder,

                BackgroundTransparency = 1,

                Size =
                    UDim2.fromScale(
                        1,
                        1
                    ),

                Text =
                    string.sub(
                        Window.Title,
                        1,
                        1
                    ):upper(),

                TextColor3 =
                    COLORS.Text,

                TextSize = 19,

                Font =
                    Enum.Font.GothamBold,

                ZIndex = 22,
            }
        )
    end

    --====================================================
    -- TITLE
    --====================================================

    local TitleLabel =
        New(
            "TextLabel",
            {
                Parent =
                    TopBar,

                BackgroundTransparency = 1,

                Position =
                    UDim2.fromOffset(
                        58,
                        7
                    ),

                Size =
                    UDim2.new(
                        1,
                        -225,
                        0,
                        23
                    ),

                Text =
                    Window.Title,

                TextColor3 =
                    COLORS.Text,

                TextSize = 15,

                Font =
                    Enum.Font.GothamBold,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

                TextTruncate =
                    Enum.TextTruncate.AtEnd,

                ZIndex = 22,
            }
        )

    local SubtitleLabel =
        New(
            "TextLabel",
            {
                Parent =
                    TopBar,

                BackgroundTransparency = 1,

                Position =
                    UDim2.fromOffset(
                        58,
                        30
                    ),

                Size =
                    UDim2.new(
                        1,
                        -225,
                        0,
                        17
                    ),

                Text =
                    Window.Subtitle,

                TextColor3 =
                    COLORS.SubText,

                TextSize = 10,

                Font =
                    Enum.Font.Gotham,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

                TextTruncate =
                    Enum.TextTruncate.AtEnd,

                ZIndex = 22,
            }
        )

    --====================================================
    -- SEARCH BAR
    --====================================================

    local SearchBox

    if Window.SearchEnabled then

        local SearchFrame =
            New(
                "Frame",
                {
                    Parent =
                        TopBar,

                    Position =
                        UDim2.new(
                            1,
                            -205,
                            0,
                            11
                        ),

                    Size =
                        UDim2.fromOffset(
                            125,
                            36
                        ),

                    BackgroundColor3 =
                        COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 25,
                }
            )

        AddStroke(
            SearchFrame,
            COLORS.Border,
            1
        )

        CreateIcon(
            SearchFrame,
            "search",
            15,
            UDim2.fromOffset(
                9,
                10
            ),
            26
        )

        SearchBox =
            New(
                "TextBox",
                {
                    Parent =
                        SearchFrame,

                    BackgroundTransparency = 1,

                    Position =
                        UDim2.fromOffset(
                            30,
                            0
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -35,
                            1,
                            0
                        ),

                    PlaceholderText =
                        "Search",

                    PlaceholderColor3 =
                        COLORS.Muted,

                    Text = "",

                    TextColor3 =
                        COLORS.Text,

                    TextSize = 10,

                    Font =
                        Enum.Font.Gotham,

                    ClearTextOnFocus = false,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    ZIndex = 26,
                }
            )

        Window.SearchBox =
            SearchBox
    end

    --====================================================
    -- MINIMIZE
    --====================================================

    local MinimizeButton =
        New(
            "TextButton",
            {
                Parent =
                    TopBar,

                Position =
                    UDim2.new(
                        1,
                        -75,
                        0,
                        9
                    ),

                Size =
                    UDim2.fromOffset(
                        30,
                        38
                    ),

                BackgroundTransparency = 1,

                BorderSizePixel = 0,

                AutoButtonColor = false,

                Text = "",

                ZIndex = 30,
            }
        )

    CreateIcon(
        MinimizeButton,
        "minus",
        17,
        UDim2.new(
            0.5,
            -8,
            0.5,
            -8
        ),
        31
    )

    --====================================================
    -- CLOSE
    --====================================================

    local CloseButton =
        New(
            "TextButton",
            {
                Parent =
                    TopBar,

                Position =
                    UDim2.new(
                        1,
                        -40,
                        0,
                        9
                    ),

                Size =
                    UDim2.fromOffset(
                        30,
                        38
                    ),

                BackgroundTransparency = 1,

                BorderSizePixel = 0,

                AutoButtonColor = false,

                Text = "",

                ZIndex = 30,
            }
        )

    local CloseIcon =
        CreateIcon(
            CloseButton,
            "x",
            18,
            UDim2.new(
                0.5,
                -9,
                0.5,
                -9
            ),
            31
        )

    if CloseIcon then
        CloseIcon.ImageColor3 =
            COLORS.Danger
    end

    --====================================================
    -- BODY
    --====================================================

    local Body =
        New(
            "Frame",
            {
                Parent =
                    Main,

                Position =
                    UDim2.fromOffset(
                        0,
                        58
                    ),

                Size =
                    UDim2.new(
                        1,
                        0,
                        1,
                        -58
                    ),

                BackgroundTransparency = 1,

                BorderSizePixel = 0,

                ZIndex = 10,
            }
        )

    --====================================================
    -- TAB BAR
    --====================================================

    local TabBar =
        New(
            "ScrollingFrame",
            {
                Parent =
                    Body,

                Name =
                    "TabBar",

                Position =
                    UDim2.fromOffset(
                        8,
                        8
                    ),

                Size =
                    UDim2.fromOffset(
                        145,
                        266
                    ),

                BackgroundColor3 =
                    COLORS.Background2,

                BorderSizePixel = 0,

                ScrollBarThickness = 3,

                ScrollBarImageColor3 =
                    COLORS.Border,

                ScrollingDirection =
                    Enum.ScrollingDirection.Y,

                CanvasSize =
                    UDim2.new(),

                AutomaticCanvasSize =
                    Enum.AutomaticSize.Y,

                ZIndex = 11,
            }
        )

    AddStroke(
        TabBar,
        COLORS.Border,
        1
    )

    AddPadding(
        TabBar,
        6,
        6,
        6,
        6
    )

    local TabLayout =
        New(
            "UIListLayout",
            {
                Parent =
                    TabBar,

                FillDirection =
                    Enum.FillDirection.Vertical,

                HorizontalAlignment =
                    Enum.HorizontalAlignment.Center,

                SortOrder =
                    Enum.SortOrder.LayoutOrder,

                Padding =
                    UDim.new(
                        0,
                        5
                    ),
            }
        )

    --====================================================
    -- PROFILE
    --====================================================

    if Window.UserConfig.Profile
        or Window.UserConfig.Username then

        local ProfileHolder =
            New(
                "Frame",
                {
                    Parent =
                        TabBar,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            50
                        ),

                    BackgroundColor3 =
                        COLORS.Panel,

                    BorderSizePixel = 0,

                    LayoutOrder = -100,

                    ZIndex = 13,
                }
            )

        AddStroke(
            ProfileHolder,
            COLORS.Border,
            1
        )

        if Window.UserConfig.Profile then

            local Avatar =
                New(
                    "ImageLabel",
                    {
                        Parent =
                            ProfileHolder,

                        Position =
                            UDim2.fromOffset(
                                7,
                                7
                            ),

                        Size =
                            UDim2.fromOffset(
                                36,
                                36
                            ),

                        BackgroundColor3 =
                            COLORS.Panel2,

                        BorderSizePixel = 0,

                        Image =
                            GetProfileImage(),

                        ZIndex = 14,
                    }
                )

            AddStroke(
                Avatar,
                COLORS.Border,
                1
            )
        end

        if Window.UserConfig.Username then

            local x =
                Window.UserConfig.Profile
                    and 49
                    or 8

            New(
                "TextLabel",
                {
                    Parent =
                        ProfileHolder,

                    BackgroundTransparency = 1,

                    Position =
                        UDim2.fromOffset(
                            x,
                            7
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -x - 5,
                            0,
                            19
                        ),

                    Text =
                        LocalPlayer.DisplayName,

                    TextColor3 =
                        COLORS.Text,

                    TextSize = 11,

                    Font =
                        Enum.Font.GothamBold,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,

                    ZIndex = 14,
                }
            )

            New(
                "TextLabel",
                {
                    Parent =
                        ProfileHolder,

                    BackgroundTransparency = 1,

                    Position =
                        UDim2.fromOffset(
                            x,
                            26
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -x - 5,
                            0,
                            16
                        ),

                    Text =
                        "@" ..
                        LocalPlayer.Name,

                    TextColor3 =
                        COLORS.SubText,

                    TextSize = 9,

                    Font =
                        Enum.Font.Gotham,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,

                    ZIndex = 14,
                }
            )
        end
    end

    --====================================================
    -- CONTENT
    --====================================================

    local Content =
        New(
            "Frame",
            {
                Parent =
                    Body,

                Position =
                    UDim2.fromOffset(
                        160,
                        8
                    ),

                Size =
                    UDim2.new(
                        1,
                        -168,
                        1,
                        -16
                    ),

                BackgroundTransparency = 1,

                BorderSizePixel = 0,

                ZIndex = 11,
            }
        )

    --====================================================
    -- SEARCH SYSTEM
    --====================================================

    local function SearchElements(text)

        text =
            tostring(
                text or ""
            ):lower()

        for _, element in ipairs(
            Window.Elements
        ) do

            if element.Root
                and element.Root.Parent then

                if text == "" then

                    element.Root.Visible =
                        true

                else

                    local elementTitle =
                        tostring(
                            element.Title
                                or ""
                        ):lower()

                    local elementDesc =
                        tostring(
                            element.Desc
                                or ""
                        ):lower()

                    element.Root.Visible =
                        elementTitle:find(
                            text,
                            1,
                            true
                        ) ~= nil

                        or

                        elementDesc:find(
                            text,
                            1,
                            true
                        ) ~= nil
                end
            end
        end
    end

    if SearchBox then

        SearchBox:GetPropertyChangedSignal(
            "Text"
        ):Connect(
            function()

                SearchElements(
                    SearchBox.Text
                )

            end
        )
    end

    --====================================================
    -- WINDOW METHODS
    --====================================================

    function Window:Minimize()

        if Window.Destroyed
            or Window.Minimized then

            return
        end

        Window.Minimized = true

        Tween(
            Main,
            TWEEN_MED,
            {
                Size =
                    UDim2.fromOffset(
                        550,
                        0
                    )
            }
        )

        task.delay(
            0.22,
            function()

                if Window.Destroyed then
                    return
                end

                Main.Visible =
                    false

                FloatingButton.Visible =
                    true

                FloatingButton.Size =
                    UDim2.fromOffset(
                        0,
                        0
                    )

                Tween(
                    FloatingButton,
                    TWEEN_MED,
                    {
                        Size =
                            UDim2.fromOffset(
                                52,
                                52
                            )
                    }
                )

            end
        )
    end

    function Window:Restore()

        if Window.Destroyed
            or not Window.Minimized then

            return
        end

        Window.Minimized =
            false

        FloatingButton.Visible =
            false

        Main.Visible =
            true

        Main.Size =
            UDim2.fromOffset(
                550,
                0
            )

        Tween(
            Main,
            TWEEN_MED,
            {
                Size =
                    DEFAULT_WINDOW_SIZE
            }
        )
    end

    function Window:Destroy()

        if Window.Destroyed then
            return
        end

        Window.Destroyed =
            true

        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    function Window:SetTitle(title)

        Window.Title =
            tostring(title)

        TitleLabel.Text =
            Window.Title
    end

    function Window:SetSubtitle(subtitle)

        Window.Subtitle =
            tostring(subtitle)

        SubtitleLabel.Text =
            Window.Subtitle
    end

    function Window:SetIcon(icon)

        Window.Image =
            icon

        local asset =
            ResolveIcon(icon)

        if not asset then
            return
        end

        if WindowIcon then
            WindowIcon.Image =
                asset
        end

        if FloatingIcon then
            FloatingIcon.Image =
                asset
        end
    end

    function Window:SetVisible(value)

        value =
            value == true

        if value then

            if Window.Minimized then
                Window:Restore()
            else
                Main.Visible = true
            end

        else

            Main.Visible = false
        end
    end

    function Window:GetActiveTab()
        return Window.ActiveTab
    end

    MinimizeButton.MouseButton1Click:Connect(
        function()
            Window:Minimize()
        end
    )

    CloseButton.MouseButton1Click:Connect(
        function()
            Window:Destroy()
        end
    )

    --====================================================
    -- FLOATING BUTTON DRAG
    --====================================================

    do

        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        local moved = false

        local function Update(input)

            if not dragging then
                return
            end

            local delta =
                input.Position
                - dragStart

            if delta.Magnitude > 7 then
                moved = true
            end

            FloatingButton.Position =
                UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset
                        + delta.X,

                    startPosition.Y.Scale,
                    startPosition.Y.Offset
                        + delta.Y
                )
        end

        FloatingButton.InputBegan:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.MouseButton1
                    or input.UserInputType ==
                    Enum.UserInputType.Touch then

                    dragging = true

                    moved = false

                    dragStart =
                        input.Position

                    startPosition =
                        FloatingButton.Position

                    dragInput = input

                    input.Changed:Connect(
                        function()

                            if input.UserInputState ==
                                Enum.UserInputState.End then

                                dragging = false

                                if not moved then
                                    Window:Restore()
                                end
                            end

                        end
                    )
                end

            end
        )

        FloatingButton.InputChanged:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                    or input.UserInputType ==
                    Enum.UserInputType.Touch then

                    dragInput = input
                end

            end
        )

        UserInputService.InputChanged:Connect(
            function(input)

                if input == dragInput then
                    Update(input)
                end

            end
        )
    end

    --====================================================
    -- CREATE TAB
    --====================================================

    function Window:CreateTab(tabConfig)

        tabConfig =
            tabConfig or {}

        local Tab = {}

        Tab.Title =
            tabConfig.Title
                or "Tab"

        Tab.Icon =
            tabConfig.Icon
                or "circle"

        Tab.Sections = {}

        --================================================
        -- TAB BUTTON
        --================================================

        local TabButton =
            New(
                "TextButton",
                {
                    Parent =
                        TabBar,

                    Name =
                        "TabButton",

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            38
                        ),

                    BackgroundColor3 =
                        COLORS.Panel,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text = "",

                    LayoutOrder =
                        #Window.Tabs + 1,

                    ZIndex = 15,
                }
            )

        AddStroke(
            TabButton,
            COLORS.Border,
            1
        )

        local SelectedBar =
            New(
                "Frame",
                {
                    Parent =
                        TabButton,

                    Position =
                        UDim2.fromOffset(
                            0,
                            0
                        ),

                    Size =
                        UDim2.fromOffset(
                            3,
                            38
                        ),

                    BackgroundColor3 =
                        COLORS.Accent,

                    BorderSizePixel = 0,

                    Visible = false,

                    ZIndex = 16,
                }
            )

        local TabIconHolder =
            New(
                "Frame",
                {
                    Parent =
                        TabButton,

                    BackgroundTransparency = 1,

                    Position =
                        UDim2.fromOffset(
                            8,
                            0
                        ),

                    Size =
                        UDim2.fromOffset(
                            38,
                            38
                        ),

                    ZIndex = 16,
                }
            )

        local TabIcon =
            CreateIcon(
                TabIconHolder,
                Tab.Icon,
                17,
                UDim2.new(
                    0.5,
                    -8,
                    0.5,
                    -8
                ),
                17
            )

        if not TabIcon then

            New(
                "TextLabel",
                {
                    Parent =
                        TabIconHolder,

                    BackgroundTransparency = 1,

                    Size =
                        UDim2.fromScale(
                            1,
                            1
                        ),

                    Text =
                        string.sub(
                            Tab.Title,
                            1,
                            1
                        ):upper(),

                    TextColor3 =
                        COLORS.Text,

                    TextSize = 12,

                    Font =
                        Enum.Font.GothamBold,

                    ZIndex = 17,
                }
            )
        end

        local TabText =
            New(
                "TextLabel",
                {
                    Parent =
                        TabButton,

                    BackgroundTransparency = 1,

                    Position =
                        UDim2.fromOffset(
                            47,
                            0
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -53,
                            1,
                            0
                        ),

                    Text =
                        Tab.Title,

                    TextColor3 =
                        COLORS.SubText,

                    TextSize = 11,

                    Font =
                        Enum.Font.GothamMedium,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,

                    ZIndex = 17,
                }
            )

        --================================================
        -- PAGE
        --================================================

        local Page =
            New(
                "ScrollingFrame",
                {
                    Parent =
                        Content,

                    Name =
                        "Page_" ..
                        tostring(
                            #Window.Tabs + 1
                        ),

                    Size =
                        UDim2.fromScale(
                            1,
                            1
                        ),

                    BackgroundTransparency = 1,

                    BorderSizePixel = 0,

                    ScrollBarThickness = 4,

                    ScrollBarImageColor3 =
                        COLORS.Border,

                    CanvasSize =
                        UDim2.new(),

                    AutomaticCanvasSize =
                        Enum.AutomaticSize.Y,

                    ScrollingDirection =
                        Enum.ScrollingDirection.Y,

                    Visible = false,

                    ZIndex = 12,
                }
            )

        AddPadding(
            Page,
            0,
            5,
            0,
            8
        )

        local PageLayout =
            New(
                "UIListLayout",
                {
                    Parent =
                        Page,

                    FillDirection =
                        Enum.FillDirection.Vertical,

                    SortOrder =
                        Enum.SortOrder.LayoutOrder,

                    Padding =
                        UDim.new(
                            0,
                            7
                        ),
                }
            )

        Tab.Button =
            TabButton

        Tab.Page =
            Page

        Tab.Layout =
            PageLayout

        Tab._SelectedBar =
            SelectedBar

        Tab._TabText =
            TabText

        --================================================
        -- SELECT
        --================================================

        function Tab:Select()

            for _, otherTab in ipairs(
                Window.Tabs
            ) do

                local active =
                    otherTab == Tab

                otherTab.Page.Visible =
                    active

                otherTab.Selected =
                    active

                if otherTab._SelectedBar then

                    otherTab._SelectedBar.Visible =
                        active
                end

                if otherTab._TabText then

                    otherTab._TabText.TextColor3 =
                        active
                        and COLORS.Text
                        or COLORS.SubText
                end

                Tween(
                    otherTab.Button,
                    TWEEN_FAST,
                    {
                        BackgroundColor3 =
                            active
                            and COLORS.Panel2
                            or COLORS.Panel,
                    }
                )
            end

            Window.ActiveTab =
                Tab

            if SearchBox then

                SearchElements(
                    SearchBox.Text
                )
            end
        end

        TabButton.MouseButton1Click:Connect(
            function()
                Tab:Select()
            end
        )

        TabButton.MouseEnter:Connect(
            function()

                if not Tab.Selected then

                    Tween(
                        TabButton,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 =
                                COLORS.Panel2
                        }
                    )
                end
            end
        )

        TabButton.MouseLeave:Connect(
            function()

                if not Tab.Selected then

                    Tween(
                        TabButton,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 =
                                COLORS.Panel
                        }
                    )
                end
            end
        )

        --================================================
        -- CREATE SECTION
        --================================================

        function Tab:CreateSection(
            sectionConfig
        )

            sectionConfig =
                sectionConfig or {}

            local Section = {}

            Section.Title =
                sectionConfig.Title
                    or "Section"

            -- IMPORTANT:
            -- The section has NO fixed Size.
            -- It automatically grows from its contents.

            local SectionFrame =
                New(
                    "Frame",
                    {
                        Parent =
                            Page,

                        Name =
                            "Section_" ..
                            Section.Title,

                        Size =
                            UDim2.new(
                                1,
                                -2,
                                0,
                                0
                            ),

                        AutomaticSize =
                            Enum.AutomaticSize.Y,

                        BackgroundColor3 =
                            COLORS.Background2,

                        BorderSizePixel = 0,

                        LayoutOrder =
                            #Tab.Sections + 1,

                        ZIndex = 13,
                    }
                )

            AddStroke(
                SectionFrame,
                COLORS.Border,
                1
            )

            AddPadding(
                SectionFrame,
                9,
                9,
                8,
                9
            )

            local SectionTitle =
                New(
                    "TextLabel",
                    {
                        Parent =
                            SectionFrame,

                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                20
                            ),

                        BackgroundTransparency = 1,

                        Text =
                            Section.Title,

                        TextColor3 =
                            COLORS.Text,

                        TextSize = 12,

                        Font =
                            Enum.Font.GothamBold,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 14,
                    }
                )

            local ElementHolder =
                New(
                    "Frame",
                    {
                        Parent =
                            SectionFrame,

                        Position =
                            UDim2.fromOffset(
                                0,
                                25
                            ),

                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                0
                            ),

                        AutomaticSize =
                            Enum.AutomaticSize.Y,

                        BackgroundTransparency = 1,

                        BorderSizePixel = 0,

                        ZIndex = 14,
                    }
                )

            local ElementLayout =
                New(
                    "UIListLayout",
                    {
                        Parent =
                            ElementHolder,

                        FillDirection =
                            Enum.FillDirection.Vertical,

                        HorizontalAlignment =
                            Enum.HorizontalAlignment.Center,

                        SortOrder =
                            Enum.SortOrder.LayoutOrder,

                        Padding =
                            UDim.new(
                                0,
                                5
                            ),
                    }
                )

            Section.Frame =
                SectionFrame

            Section.Holder =
                ElementHolder

            Section.Layout =
                ElementLayout

            table.insert(
                Tab.Sections,
                Section
            )

            --============================================
            -- REGISTER ELEMENT
            --============================================

            local function RegisterElement(
                root,
                title,
                desc
            )

                table.insert(
                    Window.Elements,
                    {
                        Root = root,

                        Title = title,

                        Desc = desc,
                    }
                )
            end

            --============================================
            -- BUTTON
            --============================================

            function Section:CreateButton(
                buttonConfig
            )

                buttonConfig =
                    buttonConfig or {}

                local Button = {}

                local title =
                    buttonConfig.Title
                        or "Button"

                local desc =
                    buttonConfig.Desc
                        or ""

                local locked =
                    buttonConfig.Locked
                        == true

                local root =
                    New(
                        "Frame",
                        {
                            Parent =
                                ElementHolder,

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    desc ~= ""
                                        and 53
                                        or 40
                                ),

                            BackgroundColor3 =
                                COLORS.Panel,

                            BorderSizePixel = 0,

                            ZIndex = 15,
                        }
                    )

                AddStroke(
                    root,
                    COLORS.Border,
                    1
                )

                local click =
                    New(
                        "TextButton",
                        {
                            Parent = root,

                            Size =
                                UDim2.fromScale(
                                    1,
                                    1
                                ),

                            BackgroundTransparency = 1,

                            AutoButtonColor = false,

                            Text = "",

                            ZIndex = 17,
                        }
                    )

                New(
                    "TextLabel",
                    {
                        Parent = root,

                        BackgroundTransparency = 1,

                        Position =
                            UDim2.fromOffset(
                                11,
                                desc ~= ""
                                    and 7
                                    or 0
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -55,
                                0,
                                20
                            ),

                        Text = title,

                        TextColor3 =
                            locked
                            and COLORS.Muted
                            or COLORS.Text,

                        TextSize = 11,

                        Font =
                            Enum.Font.GothamMedium,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    }
                )

                if desc ~= "" then

                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    28
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -20,
                                    0,
                                    16
                                ),

                            Text = desc,

                            TextColor3 =
                                COLORS.SubText,

                            TextSize = 9,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            TextTruncate =
                                Enum.TextTruncate.AtEnd,

                            ZIndex = 18,
                        }
                    )
                end

                if locked then

                    local lock =
                        CreateIcon(
                            root,
                            "lock",
                            14,
                            UDim2.new(
                                1,
                                -25,
                                0.5,
                                -7
                            ),
                            18
                        )

                    if lock then
                        lock.ImageColor3 =
                            COLORS.Warning
                    end

                    click.Active = false

                else

                    CreateIcon(
                        root,
                        "chevron-right",
                        15,
                        UDim2.new(
                            1,
                            -28,
                            0.5,
                            -7
                        ),
                        18
                    )

                    click.MouseEnter:Connect(
                        function()

                            Tween(
                                root,
                                TWEEN_FAST,
                                {
                                    BackgroundColor3 =
                                        COLORS.Panel2
                                }
                            )
                        end
                    )

                    click.MouseLeave:Connect(
                        function()

                            Tween(
                                root,
                                TWEEN_FAST,
                                {
                                    BackgroundColor3 =
                                        COLORS.Panel
                                }
                            )
                        end
                    )

                    click.MouseButton1Click:Connect(
                        function()

                            if typeof(
                                buttonConfig.Callback
                            ) == "function" then

                                task.spawn(
                                    buttonConfig.Callback
                                )
                            end
                        end
                    )
                end

                Button.Root =
                    root

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Button
            end

            --============================================
            -- TOGGLE
            --============================================

            function Section:CreateToggle(
                toggleConfig
            )

                toggleConfig =
                    toggleConfig or {}

                local Toggle = {}

                local title =
                    toggleConfig.Title
                        or "Toggle"

                local desc =
                    toggleConfig.Desc
                        or ""

                local state =
                    toggleConfig.Value
                        == true

                local root =
                    New(
                        "Frame",
                        {
                            Parent =
                                ElementHolder,

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    desc ~= ""
                                        and 57
                                        or 44
                                ),

                            BackgroundColor3 =
                                COLORS.Panel,

                            BorderSizePixel = 0,

                            ZIndex = 15,
                        }
                    )

                AddStroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,

                        BackgroundTransparency = 1,

                        Position =
                            UDim2.fromOffset(
                                11,
                                desc ~= ""
                                    and 7
                                    or 0
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -75,
                                0,
                                20
                            ),

                        Text = title,

                        TextColor3 =
                            COLORS.Text,

                        TextSize = 11,

                        Font =
                            Enum.Font.GothamMedium,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    }
                )

                if desc ~= "" then

                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    28
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -80,
                                    0,
                                    16
                                ),

                            Text = desc,

                            TextColor3 =
                                COLORS.SubText,

                            TextSize = 9,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            TextTruncate =
                                Enum.TextTruncate.AtEnd,

                            ZIndex = 18,
                        }
                    )
                end

                local Switch =
                    New(
                        "TextButton",
                        {
                            Parent = root,

                            Position =
                                UDim2.new(
                                    1,
                                    -58,
                                    0.5,
                                    -11
                                ),

                            Size =
                                UDim2.fromOffset(
                                    44,
                                    22
                                ),

                            BackgroundColor3 =
                                COLORS.Panel2,

                            BorderSizePixel = 0,

                            AutoButtonColor = false,

                            Text = "",

                            ZIndex = 19,
                        }
                    )

                AddStroke(
                    Switch,
                    COLORS.Border,
                    1
                )

                local Knob =
                    New(
                        "Frame",
                        {
                            Parent =
                                Switch,

                            Position =
                                UDim2.fromOffset(
                                    3,
                                    3
                                ),

                            Size =
                                UDim2.fromOffset(
                                    16,
                                    16
                                ),

                            BackgroundColor3 =
                                COLORS.SubText,

                            BorderSizePixel = 0,

                            ZIndex = 20,
                        }
                    )

                local function UpdateToggle()

                    if state then

                        Tween(
                            Switch,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 =
                                    COLORS.Accent
                            }
                        )

                        Tween(
                            Knob,
                            TWEEN_FAST,
                            {
                                Position =
                                    UDim2.new(
                                        1,
                                        -19,
                                        0.5,
                                        -8
                                    ),

                                BackgroundColor3 =
                                    COLORS.White,
                            }
                        )

                    else

                        Tween(
                            Switch,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 =
                                    COLORS.Panel2
                            }
                        )

                        Tween(
                            Knob,
                            TWEEN_FAST,
                            {
                                Position =
                                    UDim2.fromOffset(
                                        3,
                                        3
                                    ),

                                BackgroundColor3 =
                                    COLORS.SubText,
                            }
                        )
                    end
                end

                function Toggle:SetValue(
                    value,
                    callCallback
                )

                    state =
                        value == true

                    UpdateToggle()

                    if callCallback ~= false
                        and typeof(
                            toggleConfig.Callback
                        ) == "function" then

                        task.spawn(
                            toggleConfig.Callback,
                            state
                        )
                    end
                end

                function Toggle:GetValue()
                    return state
                end

                Switch.MouseButton1Click:Connect(
                    function()

                        Toggle:SetValue(
                            not state,
                            true
                        )
                    end
                )

                Toggle.Root =
                    root

                UpdateToggle()

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Toggle
            end

            --============================================
            -- SLIDER
            --============================================

            function Section:CreateSlider(
                sliderConfig
            )

                sliderConfig =
                    sliderConfig or {}

                local Slider = {}

                local title =
                    sliderConfig.Title
                        or "Slider"

                local desc =
                    sliderConfig.Desc
                        or ""

                local range =
                    sliderConfig.Value
                        or {}

                local minimum =
                    tonumber(
                        range.Min
                    ) or 0

                local maximum =
                    tonumber(
                        range.Max
                    ) or 100

                local current =
                    tonumber(
                        range.Default
                    ) or minimum

                local step =
                    tonumber(
                        sliderConfig.Step
                    ) or 1

                local root =
                    New(
                        "Frame",
                        {
                            Parent =
                                ElementHolder,

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    desc ~= ""
                                        and 67
                                        or 56
                                ),

                            BackgroundColor3 =
                                COLORS.Panel,

                            BorderSizePixel = 0,

                            ZIndex = 15,
                        }
                    )

                AddStroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,

                        BackgroundTransparency = 1,

                        Position =
                            UDim2.fromOffset(
                                11,
                                7
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -75,
                                0,
                                20
                            ),

                        Text = title,

                        TextColor3 =
                            COLORS.Text,

                        TextSize = 11,

                        Font =
                            Enum.Font.GothamMedium,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    }
                )

                local ValueLabel =
                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.new(
                                    1,
                                    -60,
                                    0,
                                    7
                                ),

                            Size =
                                UDim2.fromOffset(
                                    50,
                                    20
                                ),

                            Text =
                                tostring(
                                    current
                                ),

                            TextColor3 =
                                COLORS.Accent2,

                            TextSize = 11,

                            Font =
                                Enum.Font.GothamBold,

                            TextXAlignment =
                                Enum.TextXAlignment.Right,

                            ZIndex = 18,
                        }
                    )

                if desc ~= "" then

                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    27
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -20,
                                    0,
                                    16
                                ),

                            Text = desc,

                            TextColor3 =
                                COLORS.SubText,

                            TextSize = 9,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            ZIndex = 18,
                        }
                    )
                end

                local SliderHolder =
                    New(
                        "Frame",
                        {
                            Parent =
                                root,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    desc ~= ""
                                        and 49
                                        or 38
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -22,
                                    0,
                                    10
                                ),

                            BackgroundTransparency = 1,

                            ZIndex = 18,
                        }
                    )

                local Track =
                    New(
                        "Frame",
                        {
                            Parent =
                                SliderHolder,

                            Position =
                                UDim2.new(
                                    0,
                                    0,
                                    0.5,
                                    -3
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    6
                                ),

                            BackgroundColor3 =
                                COLORS.Panel2,

                            BorderSizePixel = 0,

                            ZIndex = 18,
                        }
                    )

                AddStroke(
                    Track,
                    COLORS.Border,
                    1
                )

                local Fill =
                    New(
                        "Frame",
                        {
                            Parent =
                                Track,

                            Size =
                                UDim2.new(
                                    0,
                                    0,
                                    1,
                                    0
                                ),

                            BackgroundColor3 =
                                COLORS.Accent,

                            BorderSizePixel = 0,

                            ZIndex = 19,
                        }
                    )

                local Knob =
                    New(
                        "Frame",
                        {
                            Parent =
                                Track,

                            AnchorPoint =
                                Vector2.new(
                                    0.5,
                                    0.5
                                ),

                            Position =
                                UDim2.new(
                                    0,
                                    0,
                                    0.5,
                                    0
                                ),

                            Size =
                                UDim2.fromOffset(
                                    12,
                                    12
                                ),

                            BackgroundColor3 =
                                COLORS.White,

                            BorderSizePixel = 0,

                            ZIndex = 20,
                        }
                    )

                local Drag =
                    New(
                        "TextButton",
                        {
                            Parent =
                                SliderHolder,

                            Size =
                                UDim2.fromScale(
                                    1,
                                    1
                                ),

                            BackgroundTransparency = 1,

                            AutoButtonColor = false,

                            Text = "",

                            ZIndex = 21,
                        }
                    )

                local function RoundStep(
                    value
                )

                    value =
                        math.clamp(
                            value,
                            minimum,
                            maximum
                        )

                    local stepped =
                        math.floor(
                            (
                                (
                                    value
                                    - minimum
                                ) / step
                            ) + 0.5
                        ) * step

                    return math.clamp(
                        minimum + stepped,
                        minimum,
                        maximum
                    )
                end

                local function UpdateSlider(
                    value,
                    callback
                )

                    current =
                        RoundStep(value)

                    local percent =
                        (
                            current
                            - minimum
                        )
                        /
                        math.max(
                            maximum
                            - minimum,
                            0.00001
                        )

                    Tween(
                        Fill,
                        TWEEN_FAST,
                        {
                            Size =
                                UDim2.new(
                                    percent,
                                    0,
                                    1,
                                    0
                                )
                        }
                    )

                    Tween(
                        Knob,
                        TWEEN_FAST,
                        {
                            Position =
                                UDim2.new(
                                    percent,
                                    0,
                                    0.5,
                                    0
                                )
                        }
                    )

                    ValueLabel.Text =
                        tostring(
                            current
                        )

                    if callback
                        and typeof(
                            sliderConfig.Callback
                        ) == "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                local draggingSlider =
                    false

                local function SetFromX(x)

                    local startX =
                        SliderHolder.AbsolutePosition.X

                    local width =
                        SliderHolder.AbsoluteSize.X

                    local alpha =
                        math.clamp(
                            (
                                x
                                - startX
                            )
                            /
                            math.max(
                                width,
                                1
                            ),
                            0,
                            1
                        )

                    UpdateSlider(
                        minimum
                            +
                            (
                                maximum
                                - minimum
                            )
                            * alpha,
                        true
                    )
                end

                Drag.InputBegan:Connect(
                    function(input)

                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            draggingSlider = true

                            SetFromX(
                                input.Position.X
                            )
                        end
                    end
                )

                UserInputService.InputChanged:Connect(
                    function(input)

                        if not draggingSlider then
                            return
                        end

                        if input.UserInputType ==
                            Enum.UserInputType.MouseMovement
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            SetFromX(
                                input.Position.X
                            )
                        end
                    end
                )

                UserInputService.InputEnded:Connect(
                    function(input)

                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                            or input.UserInputType ==
                            Enum.UserInputType.Touch then

                            draggingSlider = false
                        end
                    end
                )

                function Slider:SetValue(
                    value,
                    callCallback
                )

                    UpdateSlider(
                        tonumber(value)
                            or minimum,
                        callCallback ~= false
                    )
                end

                function Slider:GetValue()
                    return current
                end

                function Slider:SetRange(
                    min,
                    max,
                    default
                )

                    minimum =
                        tonumber(min)
                        or minimum

                    maximum =
                        tonumber(max)
                        or maximum

                    if default ~= nil then

                        current =
                            tonumber(
                                default
                            )
                            or minimum
                    end

                    UpdateSlider(
                        current,
                        false
                    )
                end

                Slider.Root =
                    root

                UpdateSlider(
                    current,
                    false
                )

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Slider
            end

            --============================================
            -- INPUT
            --============================================

            function Section:CreateInput(
                inputConfig
            )

                inputConfig =
                    inputConfig or {}

                local Input = {}

                local title =
                    inputConfig.Title
                        or "Input"

                local desc =
                    inputConfig.Desc
                        or ""

                local root =
                    New(
                        "Frame",
                        {
                            Parent =
                                ElementHolder,

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    desc ~= ""
                                        and 75
                                        or 62
                                ),

                            BackgroundColor3 =
                                COLORS.Panel,

                            BorderSizePixel = 0,

                            ZIndex = 15,
                        }
                    )

                AddStroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,

                        BackgroundTransparency = 1,

                        Position =
                            UDim2.fromOffset(
                                11,
                                7
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -20,
                                0,
                                19
                            ),

                        Text = title,

                        TextColor3 =
                            COLORS.Text,

                        TextSize = 11,

                        Font =
                            Enum.Font.GothamMedium,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    }
                )

                local inputY = 27

                if desc ~= "" then

                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    27
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -20,
                                    0,
                                    16
                                ),

                            Text = desc,

                            TextColor3 =
                                COLORS.SubText,

                            TextSize = 9,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            ZIndex = 18,
                        }
                    )

                    inputY = 46
                end

                local Box =
                    New(
                        "Frame",
                        {
                            Parent = root,

                            Position =
                                UDim2.fromOffset(
                                    10,
                                    inputY
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -20,
                                    0,
                                    26
                                ),

                            BackgroundColor3 =
                                COLORS.Panel2,

                            BorderSizePixel = 0,

                            ZIndex = 18,
                        }
                    )

                AddStroke(
                    Box,
                    COLORS.Border,
                    1
                )

                local TextBox =
                    New(
                        "TextBox",
                        {
                            Parent =
                                Box,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    8,
                                    0
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -16,
                                    1,
                                    0
                                ),

                            Text =
                                inputConfig.Value
                                or "",

                            PlaceholderText =
                                inputConfig.Placeholder
                                or "",

                            PlaceholderColor3 =
                                COLORS.Muted,

                            TextColor3 =
                                COLORS.Text,

                            TextSize = 10,

                            Font =
                                Enum.Font.Gotham,

                            ClearTextOnFocus = false,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            ZIndex = 19,
                        }
                    )

                TextBox.FocusLost:Connect(
                    function(enterPressed)

                        if typeof(
                            inputConfig.Callback
                        ) == "function" then

                            task.spawn(
                                inputConfig.Callback,
                                TextBox.Text,
                                enterPressed
                            )
                        end
                    end
                )

                function Input:GetValue()
                    return TextBox.Text
                end

                function Input:SetValue(value)

                    TextBox.Text =
                        tostring(
                            value or ""
                        )
                end

                Input.Root =
                    root

                Input.TextBox =
                    TextBox

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Input
            end

            --============================================
            -- DROPDOWN
            --============================================

            function Section:CreateDropdown(
                dropdownConfig
            )

                dropdownConfig =
                    dropdownConfig or {}

                local Dropdown = {}

                local title =
                    dropdownConfig.Title
                        or "Dropdown"

                local desc =
                    dropdownConfig.Desc
                        or ""

                local values =
                    dropdownConfig.Values
                        or {}

                local selected =
                    dropdownConfig.Value

                if selected == nil
                    and #values > 0 then

                    selected =
                        values[1]
                end

                local root =
                    New(
                        "Frame",
                        {
                            Parent =
                                ElementHolder,

                            Size =
                                UDim2.new(
                                    1,
                                    0,
                                    0,
                                    desc ~= ""
                                        and 72
                                        or 57
                                ),

                            BackgroundColor3 =
                                COLORS.Panel,

                            BorderSizePixel = 0,

                            ZIndex = 15,
                        }
                    )

                AddStroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,

                        BackgroundTransparency = 1,

                        Position =
                            UDim2.fromOffset(
                                11,
                                desc ~= ""
                                    and 7
                                    or 6
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -180,
                                0,
                                20
                            ),

                        Text = title,

                        TextColor3 =
                            COLORS.Text,

                        TextSize = 11,

                        Font =
                            Enum.Font.GothamMedium,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    }
                )

                if desc ~= "" then

                    New(
                        "TextLabel",
                        {
                            Parent = root,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    11,
                                    28
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -22,
                                    0,
                                    16
                                ),

                            Text = desc,

                            TextColor3 =
                                COLORS.SubText,

                            TextSize = 9,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            ZIndex = 18,
                        }
                    )
                end

                local Display =
                    New(
                        "TextButton",
                        {
                            Parent =
                                root,

                            Position =
                                UDim2.new(
                                    1,
                                    -165,
                                    0.5,
                                    -14
                                ),

                            Size =
                                UDim2.fromOffset(
                                    154,
                                    28
                                ),

                            BackgroundColor3 =
                                COLORS.Panel2,

                            BorderSizePixel = 0,

                            AutoButtonColor = false,

                            Text = "",

                            ZIndex = 20,
                        }
                    )

                AddStroke(
                    Display,
                    COLORS.Border,
                    1
                )

                local SelectedLabel =
                    New(
                        "TextLabel",
                        {
                            Parent =
                                Display,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    9,
                                    0
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -35,
                                    1,
                                    0
                                ),

                            Text =
                                tostring(
                                    selected
                                    or "Select..."
                                ),

                            TextColor3 =
                                COLORS.Text,

                            TextSize = 10,

                            Font =
                                Enum.Font.Gotham,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            TextTruncate =
                                Enum.TextTruncate.AtEnd,

                            ZIndex = 21,
                        }
                    )

                CreateIcon(
                    Display,
                    "chevrons-up-down",
                    15,
                    UDim2.new(
                        1,
                        -22,
                        0.5,
                        -7
                    ),
                    21
                )

                local Overlay = nil

                local function CloseDropdown()

                    if not Overlay then
                        return
                    end

                    local old =
                        Overlay

                    Overlay = nil

                    local Popup =
                        old:FindFirstChild(
                            "Popup"
                        )

                    if Popup then

                        Tween(
                            Popup,
                            TWEEN_FAST,
                            {
                                Size =
                                    UDim2.fromOffset(
                                        360,
                                        0
                                    )
                            }
                        )
                    end

                    task.delay(
                        0.14,
                        function()

                            if old then
                                old:Destroy()
                            end

                        end
                    )
                end

                local function OpenDropdown()

                    if Overlay then

                        CloseDropdown()

                        return
                    end

                    Overlay =
                        New(
                            "Frame",
                            {
                                Parent =
                                    ScreenGui,

                                Name =
                                    "DropdownOverlay",

                                Size =
                                    UDim2.fromScale(
                                        1,
                                        1
                                    ),

                                BackgroundColor3 =
                                    COLORS.Black,

                                BackgroundTransparency =
                                    0.5,

                                BorderSizePixel = 0,

                                ZIndex = 1000,
                            }
                        )

                    local Outside =
                        New(
                            "TextButton",
                            {
                                Parent =
                                    Overlay,

                                Size =
                                    UDim2.fromScale(
                                        1,
                                        1
                                    ),

                                BackgroundTransparency = 1,

                                Text = "",

                                AutoButtonColor = false,

                                ZIndex = 1000,
                            }
                        )

                    local Popup =
                        New(
                            "Frame",
                            {
                                Parent =
                                    Overlay,

                                Name =
                                    "Popup",

                                AnchorPoint =
                                    Vector2.new(
                                        0.5,
                                        0.5
                                    ),

                                Position =
                                    UDim2.fromScale(
                                        0.5,
                                        0.5
                                    ),

                                Size =
                                    UDim2.fromOffset(
                                        360,
                                        0
                                    ),

                                BackgroundColor3 =
                                    COLORS.Background,

                                BorderSizePixel = 0,

                                ZIndex = 1002,
                            }
                        )

                    AddStroke(
                        Popup,
                        COLORS.Border,
                        1
                    )

                    Outside.MouseButton1Click:Connect(
                        function()

                            CloseDropdown()

                        end
                    )

                    ----------------------------------------
                    -- HEADER
                    ----------------------------------------

                    local Header =
                        New(
                            "Frame",
                            {
                                Parent =
                                    Popup,

                                Size =
                                    UDim2.new(
                                        1,
                                        0,
                                        0,
                                        50
                                    ),

                                BackgroundColor3 =
                                    COLORS.Background2,

                                BorderSizePixel = 0,

                                ZIndex = 1003,
                            }
                        )

                    New(
                        "TextLabel",
                        {
                            Parent =
                                Header,

                            BackgroundTransparency = 1,

                            Position =
                                UDim2.fromOffset(
                                    12,
                                    0
                                ),

                            Size =
                                UDim2.new(
                                    1,
                                    -55,
                                    1,
                                    0
                                ),

                            Text = title,

                            TextColor3 =
                                COLORS.Text,

                            TextSize = 12,

                            Font =
                                Enum.Font.GothamBold,

                            TextXAlignment =
                                Enum.TextXAlignment.Left,

                            ZIndex = 1004,
                        }
                    )

                    local ModalClose =
                        New(
                            "TextButton",
                            {
                                Parent =
                                    Header,

                                Position =
                                    UDim2.new(
                                        1,
                                        -42,
                                        0,
                                        7
                                    ),

                                Size =
                                    UDim2.fromOffset(
                                        32,
                                        36
                                    ),

                                BackgroundTransparency = 1,

                                AutoButtonColor = false,

                                Text = "",

                                ZIndex = 1005,
                            }
                        )

                    local ModalCloseIcon =
                        CreateIcon(
                            ModalClose,
                            "x",
                            18,
                            UDim2.new(
                                0.5,
                                -9,
                                0.5,
                                -9
                            ),
                            1006
                        )

                    if ModalCloseIcon then

                        ModalCloseIcon.ImageColor3 =
                            COLORS.Danger
                    end

                    ModalClose.MouseButton1Click:Connect(
                        function()

                            CloseDropdown()

                        end
                    )

                    ----------------------------------------
                    -- SEARCH
                    ----------------------------------------

                    local SearchFrame =
                        New(
                            "Frame",
                            {
                                Parent =
                                    Popup,

                                Position =
                                    UDim2.fromOffset(
                                        10,
                                        58
                                    ),

                                Size =
                                    UDim2.new(
                                        1,
                                        -20,
                                        0,
                                        34
                                    ),

                                BackgroundColor3 =
                                    COLORS.Panel,

                                BorderSizePixel = 0,

                                ZIndex = 1003,
                            }
                        )

                    AddStroke(
                        SearchFrame,
                        COLORS.Border,
                        1
                    )

                    CreateIcon(
                        SearchFrame,
                        "search",
                        15,
                        UDim2.fromOffset(
                            9,
                            9
                        ),
                        1004
                    )

                    local ModalSearch =
                        New(
                            "TextBox",
                            {
                                Parent =
                                    SearchFrame,

                                BackgroundTransparency = 1,

                                Position =
                                    UDim2.fromOffset(
                                        31,
                                        0
                                    ),

                                Size =
                                    UDim2.new(
                                        1,
                                        -38,
                                        1,
                                        0
                                    ),

                                PlaceholderText =
                                    "Search option...",

                                PlaceholderColor3 =
                                    COLORS.Muted,

                                Text = "",

                                TextColor3 =
                                    COLORS.Text,

                                TextSize = 10,

                                Font =
                                    Enum.Font.Gotham,

                                ClearTextOnFocus = false,

                                TextXAlignment =
                                    Enum.TextXAlignment.Left,

                                ZIndex = 1005,
                            }
                        )

                    ----------------------------------------
                    -- OPTIONS
                    ----------------------------------------

                    local OptionList =
                        New(
                            "ScrollingFrame",
                            {
                                Parent =
                                    Popup,

                                Position =
                                    UDim2.fromOffset(
                                        10,
                                        100
                                    ),

                                Size =
                                    UDim2.new(
                                        1,
                                        -20,
                                        0,
                                        160
                                    ),

                                BackgroundTransparency = 1,

                                BorderSizePixel = 0,

                                ScrollBarThickness = 4,

                                ScrollBarImageColor3 =
                                    COLORS.Border,

                                CanvasSize =
                                    UDim2.new(),

                                AutomaticCanvasSize =
                                    Enum.AutomaticSize.Y,

                                ScrollingDirection =
                                    Enum.ScrollingDirection.Y,

                                ZIndex = 1003,
                            }
                        )

                    AddPadding(
                        OptionList,
                        1,
                        4,
                        1,
                        4
                    )

                    local OptionLayout =
                        New(
                            "UIListLayout",
                            {
                                Parent =
                                    OptionList,

                                FillDirection =
                                    Enum.FillDirection.Vertical,

                                SortOrder =
                                    Enum.SortOrder.LayoutOrder,

                                Padding =
                                    UDim.new(
                                        0,
                                        4
                                    ),
                            }
                        )

                    local CountLabel =
                        New(
                            "TextLabel",
                            {
                                Parent =
                                    Popup,

                                Position =
                                    UDim2.new(
                                        0,
                                        12,
                                        1,
                                        -31
                                    ),

                                Size =
                                    UDim2.new(
                                        1,
                                        -24,
                                        0,
                                        20
                                    ),

                                BackgroundTransparency = 1,

                                Text =
                                    tostring(
                                        #values
                                    )
                                    .. " options",

                                TextColor3 =
                                    COLORS.Muted,

                                TextSize = 9,

                                Font =
                                    Enum.Font.Gotham,

                                TextXAlignment =
                                    Enum.TextXAlignment.Left,

                                ZIndex = 1004,
                            }
                        )

                    ----------------------------------------
                    -- SELECT
                    ----------------------------------------

                    local function SelectOption(
                        value
                    )

                        selected =
                            value

                        SelectedLabel.Text =
                            tostring(value)

                        CloseDropdown()

                        if typeof(
                            dropdownConfig.Callback
                        ) == "function" then

                            task.spawn(
                                dropdownConfig.Callback,
                                value
                            )
                        end
                    end

                    ----------------------------------------
                    -- RENDER
                    ----------------------------------------

                    local function RenderOptions()

                        for _, child in ipairs(
                            OptionList:GetChildren()
                        ) do

                            if child:IsA(
                                "TextButton"
                            ) then

                                child:Destroy()
                            end
                        end

                        local filter =
                            ModalSearch.Text:lower()

                        for index, value in ipairs(
                            values
                        ) do

                            local text =
                                tostring(
                                    value
                                )

                            local matches =
                                filter == ""
                                or text:lower():find(
                                    filter,
                                    1,
                                    true
                                ) ~= nil

                            if matches then

                                local Option =
                                    New(
                                        "TextButton",
                                        {
                                            Parent =
                                                OptionList,

                                            Size =
                                                UDim2.new(
                                                    1,
                                                    0,
                                                    0,
                                                    35
                                                ),

                                            BackgroundColor3 =
                                                COLORS.Panel,

                                            BorderSizePixel = 0,

                                            AutoButtonColor = false,

                                            Text = "",

                                            LayoutOrder =
                                                index,

                                            ZIndex = 1005,
                                        }
                                    )

                                AddStroke(
                                    Option,
                                    COLORS.Border,
                                    1
                                )

                                New(
                                    "TextLabel",
                                    {
                                        Parent =
                                            Option,

                                        BackgroundTransparency = 1,

                                        Position =
                                            UDim2.fromOffset(
                                                10,
                                                0
                                            ),

                                        Size =
                                            UDim2.new(
                                                1,
                                                -45,
                                                1,
                                                0
                                            ),

                                        Text = text,

                                        TextColor3 =
                                            tostring(
                                                value
                                            )
                                            ==
                                            tostring(
                                                selected
                                            )
                                            and
                                            COLORS.Accent2
                                            or
                                            COLORS.Text,

                                        TextSize = 10,

                                        Font =
                                            Enum.Font.GothamMedium,

                                        TextXAlignment =
                                            Enum.TextXAlignment.Left,

                                        TextTruncate =
                                            Enum.TextTruncate.AtEnd,

                                        ZIndex = 1006,
                                    }
                                )

                                if tostring(value)
                                    ==
                                    tostring(selected) then

                                    CreateIcon(
                                        Option,
                                        "check",
                                        15,
                                        UDim2.new(
                                            1,
                                            -27,
                                            0.5,
                                            -7
                                        ),
                                        1007
                                    )
                                end

                                Option.MouseEnter:Connect(
                                    function()

                                        Tween(
                                            Option,
                                            TWEEN_FAST,
                                            {
                                                BackgroundColor3 =
                                                    COLORS.Panel2
                                            }
                                        )
                                    end
                                )

                                Option.MouseLeave:Connect(
                                    function()

                                        Tween(
                                            Option,
                                            TWEEN_FAST,
                                            {
                                                BackgroundColor3 =
                                                    COLORS.Panel
                                            }
                                        )
                                    end
                                )

                                Option.MouseButton1Click:Connect(
                                    function()

                                        SelectOption(
                                            value
                                        )
                                    end
                                )
                            end
                        end

                        CountLabel.Text =
                            tostring(
                                #values
                            )
                            .. " options"
                    end

                    ModalSearch:GetPropertyChangedSignal(
                        "Text"
                    ):Connect(
                        function()

                            RenderOptions()

                        end
                    )

                    RenderOptions()

                    Tween(
                        Popup,
                        TWEEN_MED,
                        {
                            Size =
                                UDim2.fromOffset(
                                    360,
                                    260
                                )
                        }
                    )
                end

                Display.MouseButton1Click:Connect(
                    function()

                        OpenDropdown()

                    end
                )

                --============================================
                -- DROPDOWN METHODS
                --============================================

                function Dropdown:Refresh(
                    newValues
                )

                    if type(newValues)
                        ~= "table" then
                        return
                    end

                    values =
                        newValues

                    local found =
                        false

                    for _, value in ipairs(
                        values
                    ) do

                        if tostring(value)
                            ==
                            tostring(
                                selected
                            ) then

                            found = true

                            break
                        end
                    end

                    if not found then

                        selected =
                            values[1]
                    end

                    SelectedLabel.Text =
                        tostring(
                            selected
                                or
                                "Select..."
                        )
                end

                function Dropdown:SetValue(
                    value,
                    callCallback
                )

                    selected =
                        value

                    SelectedLabel.Text =
                        tostring(value)

                    if callCallback ~= false
                        and typeof(
                            dropdownConfig.Callback
                        ) == "function" then

                        task.spawn(
                            dropdownConfig.Callback,
                            selected
                        )
                    end
                end

                function Dropdown:GetValue()
                    return selected
                end

                function Dropdown:GetValues()
                    return values
                end

                Dropdown.Root =
                    root

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Dropdown
            end

            return Section
        end

        table.insert(
            Window.Tabs,
            Tab
        )

        if not Window.ActiveTab then
            Tab:Select()
        end

        return Tab
    end

    --====================================================
    -- OPEN ANIMATION
    --====================================================

    Main.Size =
        UDim2.fromOffset(
            550,
            0
        )

    Tween(
        Main,
        TWEEN_MED,
        {
            Size =
                DEFAULT_WINDOW_SIZE
        }
    )

    return Window
end

--========================================================
-- KEY SYSTEM
--========================================================

function DarkyUI:CreateKeySystem(config)

    config = config or {}

    local KeySystem = {}

    KeySystem.Destroyed = false
    KeySystem.Cancelled = false

    local title =
        config.Title
            or "Access Required"

    local note =
        config.Note
            or ""

    local keyURL =
        config.URL
            or ""

    local saveKey =
        config.SaveKey == true

    local thumbnail =
        config.Thumbnail
            or {}

    local keyFile =
        "DarkyUI_Key.txt"

    --====================================================
    -- GUI
    --====================================================

    local ScreenGui =
        CoreGui:FindFirstChild(
            UI_NAME
        )

    if not ScreenGui then

        ScreenGui =
            New(
                "ScreenGui",
                {
                    Name =
                        UI_NAME,

                    Parent =
                        CoreGui,

                    IgnoreGuiInset = true,

                    ResetOnSpawn = false,

                    ZIndexBehavior =
                        Enum.ZIndexBehavior.Sibling,

                    DisplayOrder =
                        999999,
                }
            )
    end

    local Overlay =
        New(
            "Frame",
            {
                Parent =
                    ScreenGui,

                Name =
                    "KeySystem",

                Size =
                    UDim2.fromScale(
                        1,
                        1
                    ),

                BackgroundColor3 =
                    COLORS.Black,

                BackgroundTransparency =
                    0.35,

                BorderSizePixel = 0,

                ZIndex = 2000,
            }
        )

    --====================================================
    -- MAIN
    --====================================================

    local Main =
        New(
            "Frame",
            {
                Parent =
                    Overlay,

                Name =
                    "Main",

                AnchorPoint =
                    Vector2.new(
                        0.5,
                        0.5
                    ),

                Position =
                    UDim2.fromScale(
                        0.5,
                        0.5
                    ),

                Size =
                    UDim2.fromOffset(
                        480,
                        260
                    ),

                BackgroundColor3 =
                    COLORS.Background,

                BorderSizePixel = 0,

                ZIndex = 2001,
            }
        )

    AddStroke(
        Main,
        COLORS.Border,
        1
    )

    --====================================================
    -- HEADER
    --====================================================

    local Header =
        New(
            "Frame",
            {
                Parent =
                    Main,

                Size =
                    UDim2.new(
                        1,
                        0,
                        0,
                        56
                    ),

                BackgroundColor3 =
                    COLORS.Background2,

                BorderSizePixel = 0,

                ZIndex = 2002,
            }
        )

    AddStroke(
        Header,
        COLORS.Border,
        1
    )

    New(
        "TextLabel",
        {
            Parent =
                Header,

            BackgroundTransparency = 1,

            Position =
                UDim2.fromOffset(
                    15,
                    7
                ),

            Size =
                UDim2.new(
                    1,
                    -30,
                    0,
                    22
                ),

            Text = title,

            TextColor3 =
                COLORS.Text,

            TextSize = 15,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            ZIndex = 2003,
        }
    )

    New(
        "TextLabel",
        {
            Parent =
                Header,

            BackgroundTransparency = 1,

            Position =
                UDim2.fromOffset(
                    15,
                    30
                ),

            Size =
                UDim2.new(
                    1,
                    -30,
                    0,
                    17
                ),

            Text = note,

            TextColor3 =
                COLORS.SubText,

            TextSize = 9,

            Font =
                Enum.Font.Gotham,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            TextTruncate =
                Enum.TextTruncate.AtEnd,

            ZIndex = 2003,
        }
    )

    --====================================================
    -- CONTENT
    --====================================================

    local Content =
        New(
            "Frame",
            {
                Parent =
                    Main,

                Position =
                    UDim2.fromOffset(
                        0,
                        56
                    ),

                Size =
                    UDim2.new(
                        1,
                        0,
                        1,
                        -56
                    ),

                BackgroundTransparency = 1,

                ZIndex = 2002,
            }
        )

    --====================================================
    -- LEFT THUMBNAIL
    --====================================================

    local ThumbnailFrame =
        New(
            "Frame",
            {
                Parent =
                    Content,

                Position =
                    UDim2.fromOffset(
                        13,
                        14
                    ),

                Size =
                    UDim2.fromOffset(
                        145,
                        147
                    ),

                BackgroundColor3 =
                    COLORS.Panel,

                BorderSizePixel = 0,

                ZIndex = 2003,
            }
        )

    AddStroke(
        ThumbnailFrame,
        COLORS.Border,
        1
    )

    local ThumbnailImage

    if thumbnail.Image then

        ThumbnailImage =
            New(
                "ImageLabel",
                {
                    Parent =
                        ThumbnailFrame,

                    Position =
                        UDim2.fromOffset(
                            7,
                            7
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -14,
                            0,
                            105
                        ),

                    BackgroundColor3 =
                        COLORS.Panel2,

                    BorderSizePixel = 0,

                    Image =
                        NormalizeAssetId(
                            tostring(
                                thumbnail.Image
                            )
                        ),

                    ScaleType =
                        Enum.ScaleType.Crop,

                    ZIndex = 2004,
                }
            )

    else

        ThumbnailImage =
            New(
                "Frame",
                {
                    Parent =
                        ThumbnailFrame,

                    Position =
                        UDim2.fromOffset(
                            7,
                            7
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -14,
                            0,
                            105
                        ),

                    BackgroundColor3 =
                        COLORS.Panel2,

                    BorderSizePixel = 0,

                    ZIndex = 2004,
                }
            )
    end

    AddStroke(
        ThumbnailImage,
        COLORS.Border,
        1
    )

    New(
        "TextLabel",
        {
            Parent =
                ThumbnailFrame,

            BackgroundTransparency = 1,

            Position =
                UDim2.fromOffset(
                    8,
                    117
                ),

            Size =
                UDim2.new(
                    1,
                    -16,
                    0,
                    22
                ),

            Text =
                thumbnail.Title
                    or "Premium Member",

            TextColor3 =
                COLORS.Text,

            TextSize = 10,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Center,

            TextTruncate =
                Enum.TextTruncate.AtEnd,

            ZIndex = 2005,
        }
    )

    --====================================================
    -- RIGHT KEY AREA
    --====================================================

    local KeyArea =
        New(
            "Frame",
            {
                Parent =
                    Content,

                Position =
                    UDim2.fromOffset(
                        170,
                        14
                    ),

                Size =
                    UDim2.new(
                        1,
                        -183,
                        0,
                        147
                    ),

                BackgroundColor3 =
                    COLORS.Panel,

                BorderSizePixel = 0,

                ZIndex = 2003,
            }
        )

    AddStroke(
        KeyArea,
        COLORS.Border,
        1
    )

    New(
        "TextLabel",
        {
            Parent =
                KeyArea,

            BackgroundTransparency = 1,

            Position =
                UDim2.fromOffset(
                    11,
                    10
                ),

            Size =
                UDim2.new(
                    1,
                    -22,
                    0,
                    20
                ),

            Text =
                "Enter your access key",

            TextColor3 =
                COLORS.Text,

            TextSize = 11,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            ZIndex = 2004,
        }
    )

    New(
        "TextLabel",
        {
            Parent =
                KeyArea,

            BackgroundTransparency = 1,

            Position =
                UDim2.fromOffset(
                    11,
                    31
                ),

            Size =
                UDim2.new(
                    1,
                    -22,
                    0,
                    17
                ),

            Text =
                "Paste your key below to continue.",

            TextColor3 =
                COLORS.SubText,

            TextSize = 9,

            Font =
                Enum.Font.Gotham,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            ZIndex = 2004,
        }
    )

    local InputFrame =
        New(
            "Frame",
            {
                Parent =
                    KeyArea,

                Position =
                    UDim2.fromOffset(
                        10,
                        58
                    ),

                Size =
                    UDim2.new(
                        1,
                        -20,
                        0,
                        38
                    ),

                BackgroundColor3 =
                    COLORS.Panel2,

                BorderSizePixel = 0,

                ZIndex = 2005,
            }
        )

    AddStroke(
        InputFrame,
        COLORS.Border,
        1
    )

    CreateIcon(
        InputFrame,
        "key-round",
        16,
        UDim2.fromOffset(
            10,
            11
        ),
        2006
    )

    local KeyInput =
        New(
            "TextBox",
            {
                Parent =
                    InputFrame,

                BackgroundTransparency = 1,

                Position =
                    UDim2.fromOffset(
                        34,
                        0
                    ),

                Size =
                    UDim2.new(
                        1,
                        -42,
                        1,
                        0
                    ),

                PlaceholderText =
                    "Enter key...",

                PlaceholderColor3 =
                    COLORS.Muted,

                Text = "",

                TextColor3 =
                    COLORS.Text,

                TextSize = 10,

                Font =
                    Enum.Font.Gotham,

                ClearTextOnFocus = false,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

                ZIndex = 2006,
            }
        )

    --====================================================
    -- STATUS
    --====================================================

    local StatusLabel =
        New(
            "TextLabel",
            {
                Parent =
                    Content,

                Position =
                    UDim2.fromOffset(
                        13,
                        225
                    ),

                Size =
                    UDim2.new(
                        1,
                        -26,
                        0,
                        20
                    ),

                BackgroundTransparency = 1,

                Text = "",

                TextColor3 =
                    COLORS.SubText,

                TextSize = 9,

                Font =
                    Enum.Font.Gotham,

                TextXAlignment =
                    Enum.TextXAlignment.Center,

                ZIndex = 2006,
            }
        )

    --====================================================
    -- BUTTON MAKER
    --====================================================

    local function CreateKeyButton(
        parent,
        position,
        size,
        background,
        icon,
        text
    )

        local button =
            New(
                "TextButton",
                {
                    Parent =
                        parent,

                    Position =
                        position,

                    Size =
                        size,

                    BackgroundColor3 =
                        background,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text = "",

                    ZIndex = 2005,
                }
            )

        AddStroke(
            button,
            COLORS.Border,
            1
        )

        local iconObject =
            CreateIcon(
                button,
                icon,
                16,
                UDim2.fromOffset(
                    13,
                    12
                ),
                2006
            )

        if iconObject
            and icon == "x" then

            iconObject.ImageColor3 =
                COLORS.Danger
        end

        New(
            "TextLabel",
            {
                Parent =
                    button,

                BackgroundTransparency = 1,

                Position =
                    UDim2.fromOffset(
                        37,
                        0
                    ),

                Size =
                    UDim2.new(
                        1,
                        -42,
                        1,
                        0
                    ),

                Text = text,

                TextColor3 =
                    background ==
                    COLORS.Accent
                    and COLORS.White
                    or COLORS.Text,

                TextSize = 10,

                Font =
                    background ==
                    COLORS.Accent
                    and Enum.Font.GothamBold
                    or Enum.Font.GothamMedium,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

                ZIndex = 2006,
            }
        )

        return button
    end

    --====================================================
    -- BUTTONS
    --====================================================

    local CancelButton =
        CreateKeyButton(
            Content,

            UDim2.fromOffset(
                13,
                176
            ),

            UDim2.fromOffset(
                108,
                40
            ),

            COLORS.Panel,

            "x",

            "Cancel"
        )

    local GetKeyButton =
        CreateKeyButton(
            Content,

            UDim2.new(
                0.5,
                -54,
                0,
                176
            ),

            UDim2.fromOffset(
                108,
                40
            ),

            COLORS.Panel,

            "key",

            "Get Key"
        )

    local SubmitButton =
        CreateKeyButton(
            Content,

            UDim2.new(
                1,
                -121,
                0,
                176
            ),

            UDim2.fromOffset(
                108,
                40
            ),

            COLORS.Accent,

            "arrow-right",

            "Submit"
        )

    --====================================================
    -- FILE SYSTEM
    --====================================================

    local function ReadSavedKey()

        if not saveKey then
            return nil
        end

        if typeof(isfile)
            ~= "function"
            or typeof(readfile)
            ~= "function" then

            return nil
        end

        local exists = false

        pcall(
            function()

                exists =
                    isfile(
                        keyFile
                    )

            end
        )

        if not exists then
            return nil
        end

        local saved

        pcall(
            function()

                saved =
                    readfile(
                        keyFile
                    )

            end
        )

        if saved and saved ~= "" then
            return saved
        end

        return nil
    end

    local function SaveKey(key)

        if not saveKey then
            return
        end

        if typeof(writefile)
            ~= "function" then
            return
        end

        pcall(
            function()

                writefile(
                    keyFile,
                    key
                )

            end
        )
    end

    --====================================================
    -- VALIDATE
    --====================================================

    local function Validate(key)

        if typeof(
            config.KeyValidator
        ) ~= "function" then

            return false
        end

        local success, result =
            pcall(
                config.KeyValidator,
                key
            )

        return success
            and result == true
    end

    --====================================================
    -- CONTINUE
    --====================================================

    local function Continue()

        KeySystem.Destroyed =
            true

        if Overlay then
            Overlay:Destroy()
        end

        return true
    end

    --====================================================
    -- SUBMIT
    --====================================================

    local submitting = false

    local function Submit()

        if submitting then
            return
        end

        submitting = true

        local key =
            KeyInput.Text

        if key == "" then

            StatusLabel.Text =
                "Please enter a key."

            StatusLabel.TextColor3 =
                COLORS.Warning

            submitting = false

            return
        end

        StatusLabel.Text =
            "Checking key..."

        StatusLabel.TextColor3 =
            COLORS.SubText

        local valid =
            Validate(key)

        if valid then

            StatusLabel.Text =
                "Key accepted!"

            StatusLabel.TextColor3 =
                COLORS.Accent2

            SaveKey(key)

            task.delay(
                0.3,
                function()

                    if Overlay
                        and Overlay.Parent then

                        Continue()
                    end
                end
            )

        else

            StatusLabel.Text =
                "Invalid key."

            StatusLabel.TextColor3 =
                COLORS.Danger
        end

        submitting = false
    end

    --====================================================
    -- CANCEL
    --====================================================

    CancelButton.MouseButton1Click:Connect(
        function()

            KeySystem.Cancelled =
                true

            KeySystem.Destroyed =
                true

            Overlay:Destroy()
        end
    )

    --====================================================
    -- GET KEY / COPY
    --====================================================

    GetKeyButton.MouseButton1Click:Connect(
        function()

            if keyURL == "" then

                StatusLabel.Text =
                    "Key URL is not configured."

                StatusLabel.TextColor3 =
                    COLORS.Danger

                return
            end

            local copied = false

            local clipboardMethods = {

                function()
                    setclipboard(
                        keyURL
                    )
                end,

                function()
                    toclipboard(
                        keyURL
                    )
                end,

                function()

                    if syn
                        and syn.clipboard then

                        syn.clipboard =
                            keyURL
                    else

                        error(
                            "clipboard unavailable"
                        )
                    end
                end,
            }

            for _, method in ipairs(
                clipboardMethods
            ) do

                local success =
                    pcall(method)

                if success then

                    copied = true

                    break
                end
            end

            if copied then

                StatusLabel.Text =
                    "Key URL copied."

                StatusLabel.TextColor3 =
                    COLORS.Accent2

            else

                StatusLabel.Text =
                    keyURL

                StatusLabel.TextColor3 =
                    COLORS.SubText
            end
        end
    )

    --====================================================
    -- SUBMIT CLICK
    --====================================================

    SubmitButton.MouseButton1Click:Connect(
        Submit
    )

    KeyInput.FocusLost:Connect(
        function(enterPressed)

            if enterPressed then
                Submit()
            end
        end
    )

    --====================================================
    -- BUTTON HOVER
    --====================================================

    local function Hover(
        button,
        normalColor,
        hoverColor
    )

        button.MouseEnter:Connect(
            function()

                Tween(
                    button,
                    TWEEN_FAST,
                    {
                        BackgroundColor3 =
                            hoverColor
                    }
                )
            end
        )

        button.MouseLeave:Connect(
            function()

                Tween(
                    button,
                    TWEEN_FAST,
                    {
                        BackgroundColor3 =
                            normalColor
                    }
                )
            end
        )
    end

    Hover(
        CancelButton,
        COLORS.Panel,
        COLORS.Panel2
    )

    Hover(
        GetKeyButton,
        COLORS.Panel,
        COLORS.Panel2
    )

    Hover(
        SubmitButton,
        COLORS.Accent,
        COLORS.Accent2
    )

    --====================================================
    -- SAVED KEY
    --====================================================

    local savedKey =
        ReadSavedKey()

    if savedKey then

        KeyInput.Text =
            savedKey

        task.spawn(
            function()

                if Validate(
                    savedKey
                ) then

                    Continue()
                end

            end
        )
    end

    --====================================================
    -- OPEN ANIMATION
    --====================================================

    Main.Size =
        UDim2.fromOffset(
            480,
            0
        )

    Tween(
        Main,
        TWEEN_MED,
        {
            Size =
                UDim2.fromOffset(
                    480,
                    260
                )
        }
    )

    --====================================================
    -- METHODS
    --====================================================

    function KeySystem:GetKey()
        return KeyInput.Text
    end

    function KeySystem:SetKey(key)
        KeyInput.Text =
            tostring(
                key or ""
            )
    end

    function KeySystem:Submit()
        Submit()
    end

    function KeySystem:Destroy()

        if Overlay then
            Overlay:Destroy()
        end

        KeySystem.Destroyed =
            true
    end

    function KeySystem:IsDestroyed()
        return KeySystem.Destroyed
            == true
    end

    return KeySystem
end

--========================================================
-- RETURN
--========================================================

return DarkyUI
