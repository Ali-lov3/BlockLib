local Library = {}
Library.Version = "1.0.0"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local IconLibrary
pcall(function()
    IconLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local Theme = {
    WindowTop = Color3.fromRGB(28, 32, 44),
    WindowBottom = Color3.fromRGB(15, 17, 24),
    CardTop = Color3.fromRGB(32, 36, 50),
    CardBottom = Color3.fromRGB(24, 27, 38),
    ElementTop = Color3.fromRGB(40, 45, 61),
    ElementBottom = Color3.fromRGB(30, 34, 47),
    Line = Color3.fromRGB(42, 46, 60),
    LineLight = Color3.fromRGB(62, 68, 88),
    Accent = Color3.fromRGB(22, 190, 165),
    AccentLight = Color3.fromRGB(40, 226, 196),
    AccentDark = Color3.fromRGB(12, 140, 122),
    Text = Color3.fromRGB(238, 240, 246),
    Sub = Color3.fromRGB(150, 155, 170),
    Muted = Color3.fromRGB(116, 122, 140)
}

local function ResolveIcon(icon)
    if typeof(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end
    if type(icon) ~= "string" or icon == "" then
        return "rbxassetid://0"
    end
    if string.match(icon, "^rbxassetid://") then
        return icon
    end
    if string.match(icon, "^%d+$") then
        return "rbxassetid://" .. icon
    end
    local name = string.lower(icon)
    local data
    if type(IconLibrary) == "function" then
        local ok, result = pcall(IconLibrary, name)
        if ok then data = result end
    elseif type(IconLibrary) == "table" then
        for _, set in ipairs({ IconLibrary["48px"], IconLibrary["256px"], IconLibrary }) do
            if type(set) == "table" and set[name] then
                data = set[name]
                break
            end
        end
    end
    if type(data) == "table" then
        local id = data.id or data.Id or data[1]
        local offset = data.imageRectOffset or data.imageRectPosition or data.ImageRectOffset or data[3]
        local size = data.imageRectSize or data.ImageRectSize or data[2]
        if id then
            return "rbxassetid://" .. tostring(id), offset, size
        end
    end
    return "rbxassetid://0"
end

local function New(className, properties)
    local object = Instance.new(className)
    if object:IsA("GuiObject") then
        object.BorderSizePixel = 0
    end
    if object:IsA("GuiButton") then
        object.AutoButtonColor = false
    end
    if object:IsA("TextLabel") or object:IsA("ImageLabel") then
        object.BackgroundTransparency = 1
    end
    local parent
    for key, value in pairs(properties or {}) do
        if key == "Parent" then
            parent = value
        else
            pcall(function()
                object[key] = value
            end)
        end
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function Corner(object, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = object })
end

local function Stroke(object, color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Theme.Line,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = object
    })
end

local function Gradient(object, top, bottom, rotation)
    return New("UIGradient", {
        Color = ColorSequence.new(top, bottom),
        Rotation = rotation or 90,
        Parent = object
    })
end

local function Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function AddIcon(parent, icon, size, color)
    local image = New("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        ImageColor3 = color or Theme.Text,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent
    })
    local asset, offset, rectSize = ResolveIcon(icon)
    image.Image = asset
    if offset then
        pcall(function()
            image.ImageRectOffset = typeof(offset) == "Vector2" and offset or Vector2.new(offset[1] or offset.X or 0, offset[2] or offset.Y or 0)
        end)
    end
    if rectSize then
        pcall(function()
            image.ImageRectSize = typeof(rectSize) == "Vector2" and rectSize or Vector2.new(rectSize[1] or rectSize.X or 0, rectSize[2] or rectSize.Y or 0)
        end)
    end
    return image
end

local function SafeCall(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[Library] " .. tostring(err)) end
end

local function CopyTable(value)
    local result = {}
    for key, item in pairs(value) do
        if type(item) == "table" then
            result[key] = CopyTable(item)
        else
            result[key] = item
        end
    end
    return result
end

function Library:CreateWindow(config)
    config = config or {}
    local window = {
        Title = tostring(config.Title or "Untitled"),
        Logo = config.Logo or "layers",
        ConfigFolder = tostring(config.ConfigFolder or "Library_Configs"),
        ShowWaterMark = config.ShowWaterMark ~= false,
        Flags = {},
        Tabs = {},
        SearchIndex = {},
        Controls = {},
        KeyListeners = {},
        Accent = Theme.Accent,
        AccentBindings = {},
        ManagerButtons = {},
        Managers = {},
        ActiveViewport = nil,
        Destroyed = false
    }

    local screenGui = New("ScreenGui", {
        Name = "Library_" .. string.gsub(window.Title, "[^%w]", ""),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    })
    window.Gui = screenGui
    local parent
    pcall(function()
        if gethui then parent = gethui() end
    end)
    if not parent then parent = CoreGui end
    local parentOk = pcall(function() screenGui.Parent = parent end)
    if not parentOk or not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.96, 0, 0.9, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = screenGui
    })
    window.Main = main
    Corner(main, 14)
    Gradient(main, Theme.WindowTop, Theme.WindowBottom, 45)
    Stroke(main, Theme.LineLight, 0.15, 1)
    New("UISizeConstraint", { MinSize = Vector2.new(320, 360), MaxSize = Vector2.new(1040, 780), Parent = main })

    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.fromOffset(205, 650),
        BackgroundTransparency = 1,
        Parent = main
    })
    window.Sidebar = sidebar

    local divider = New("Frame", {
        Size = UDim2.new(0, 1, 1, -20),
        Position = UDim2.new(0, 204, 0, 10),
        BackgroundColor3 = Theme.LineLight,
        BackgroundTransparency = 0.4,
        Parent = main
    })
    Gradient(divider, Theme.LineLight, Theme.Line, 90)

    local logo = AddIcon(sidebar, window.Logo, 32, window.AccentLight or Theme.AccentLight)
    logo.Position = UDim2.fromOffset(17, 17)
    local titleLabel = New("TextLabel", {
        Position = UDim2.fromOffset(58, 13),
        Size = UDim2.new(1, -66, 0, 40),
        Text = window.Title,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = sidebar
    })
    window.TitleLabel = titleLabel

    local tabList = New("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(10, 72),
        Size = UDim2.new(1, -20, 1, -230),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = window.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar
    })
    window.TabList = tabList
    New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })

    local header = New("Frame", {
        Name = "Header",
        Position = UDim2.fromOffset(206, 0),
        Size = UDim2.new(1, -206, 0, 58),
        BackgroundTransparency = 1,
        Parent = main
    })
    window.Header = header
    local pageTitle = New("TextLabel", {
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.new(0.62, 0, 1, 0),
        Text = "Welcome",
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header
    })
    window.PageTitle = pageTitle
    local watermark = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.new(0.34, 0, 0, 24),
        Text = window.Title .. "  •  Library",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = window.ShowWaterMark,
        Parent = header
    })
    window.Watermark = watermark

    local body = New("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(206, 58),
        Size = UDim2.new(1, -206, 1, -58),
        BackgroundTransparency = 1,
        Parent = main
    })
    window.Body = body

    local watermarkLine = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -8),
        Size = UDim2.fromOffset(200, 18),
        Text = "Powered by " .. window.Title,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Visible = false,
        Parent = body
    })
    window.WatermarkLine = watermarkLine

    local toggleButton = New("TextButton", {
        Name = "ToggleButton",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = screenGui
    })
    window.ToggleButton = toggleButton
    Corner(toggleButton, 12)
    Gradient(toggleButton, Theme.CardTop, Theme.WindowBottom, 90)
    Stroke(toggleButton, Theme.Line, 0.2, 1)
    local toggleIcon = AddIcon(toggleButton, window.Logo, 24, Theme.Text)
    toggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleIcon.Position = UDim2.fromScale(0.5, 0.5)
    toggleButton.Activated:Connect(function() main.Visible = not main.Visible end)

    local function ResizeLayout()
        if not main.Parent then return end
        local width = main.AbsoluteSize.X
        local height = main.AbsoluteSize.Y
        local mobile = width < 650
        local sideWidth = mobile and 62 or 205
        sidebar.Size = UDim2.new(0, sideWidth, 1, 0)
        divider.Position = UDim2.new(0, sideWidth - 1, 0, 10)
        header.Position = UDim2.new(0, sideWidth, 0, 0)
        header.Size = UDim2.new(1, -sideWidth, 0, 58)
        body.Position = UDim2.new(0, sideWidth, 0, 58)
        body.Size = UDim2.new(1, -sideWidth, 1, -58)
        tabList.Position = UDim2.fromOffset(mobile and 5 or 10, 72)
        tabList.Size = UDim2.new(1, mobile and -10 or -20, 1, -180)
        logo.Position = UDim2.fromOffset(mobile and 15 or 17, 17)
        logo.Size = UDim2.fromOffset(mobile and 30 or 32, mobile and 30 or 32)
        titleLabel.Visible = not mobile
        pageTitle.Position = UDim2.fromOffset(mobile and 12 or 22, 0)
        pageTitle.Size = UDim2.new(window.ShowWaterMark and 0.58 or 1, -22, 1, 0)
        watermark.Visible = window.ShowWaterMark and not mobile
        watermarkLine.Visible = false
        for index, item in ipairs(window.ManagerButtons) do
            item.Button.AnchorPoint = Vector2.new(0, 1)
            item.Button.Position = UDim2.new(0, (sideWidth - 34) / 2, 1, -14 - ((index - 1) * 42))
            item.Button.Size = UDim2.fromOffset(34, 34)
        end
        for _, tab in ipairs(window.Tabs) do
            if tab.LayoutColumns then tab.LayoutColumns() end
        end
    end

    local function ApplyAccent(color)
        window.Accent = color
        local h, s, v = Color3.toHSV(color)
        local light = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.2, 1))
        local dark = Color3.fromHSV(h, math.min(s + 0.2, 1), math.max(v - 0.2, 0))
        window.AccentLight = light
        window.AccentDark = dark
        for _, binding in ipairs(window.AccentBindings) do
            if binding.Object and binding.Object.Parent then
                if binding.Type == "Color" then
                    pcall(function() binding.Object[binding.Property] = color end)
                elseif binding.Type == "Gradient" then
                    pcall(function() binding.Object.Color = ColorSequence.new(light, dark) end)
                end
            end
        end
        tabList.ScrollBarImageColor3 = color
        toggleIcon.ImageColor3 = color
    end
    window.SetAccent = ApplyAccent

    function window:SetVisible(visible)
        main.Visible = visible == nil and not main.Visible or visible == true
    end

    function window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        if self.ActiveViewport then self.ActiveViewport:SetInteractive(false) end
        screenGui:Destroy()
    end

    function window:Notify(options)
        if type(options) == "string" then options = { Title = options } end
        options = options or {}
        local toastHolder = self.NotificationHolder
        if not toastHolder or not toastHolder.Parent then
            toastHolder = New("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -14, 1, -14),
                Size = UDim2.new(0, 300, 1, -28),
                BackgroundTransparency = 1,
                ZIndex = 200,
                Parent = screenGui
            })
            New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = toastHolder })
            self.NotificationHolder = toastHolder
            self.NotificationCount = 0
        end
        self.NotificationCount += 1
        local height = options.Info and options.Info ~= "" and 76 or 54
        local card = New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Color3.new(1, 1, 1),
            LayoutOrder = self.NotificationCount,
            ZIndex = 201,
            Parent = toastHolder
        })
        Corner(card, 10)
        Gradient(card, Theme.CardTop, Theme.CardBottom, 90)
        Stroke(card, Theme.LineLight, 0.2, 1)
        local icon = AddIcon(card, options.Icon or "bell", 24, self.Accent)
        icon.Position = UDim2.fromOffset(14, 14)
        icon.ZIndex = 202
        New("TextLabel", {
            Position = UDim2.fromOffset(48, 9),
            Size = UDim2.new(1, -60, 0, 22),
            Text = tostring(options.Title or self.Title),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 202,
            Parent = card
        })
        if options.Info and options.Info ~= "" then
            New("TextLabel", {
                Position = UDim2.fromOffset(48, 31),
                Size = UDim2.new(1, -60, 0, 34),
                Text = tostring(options.Info),
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = Theme.Sub,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 202,
                Parent = card
            })
        end
        task.delay(math.max(tonumber(options.Duration) or 3.5, 1), function()
            if card and card.Parent then
                Tween(card, { BackgroundTransparency = 1 }, 0.2)
                task.wait(0.22)
                if card and card.Parent then card:Destroy() end
            end
        end)
        return card
    end

    local function NewTabPage(tab)
        local page = New("Frame", {
            Name = tab.Name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = body
        })
        local scroller = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -10),
            Position = UDim2.fromOffset(0, 3),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = window.Accent,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = page
        })
        local host = New("Frame", {
            Size = UDim2.new(1, -28, 0, 0),
            Position = UDim2.fromOffset(14, 12),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = scroller
        })
        local left = New("Frame", {
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = host
        })
        local right = New("Frame", {
            Position = UDim2.new(0.5, 9, 0, 0),
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = host
        })
        New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
        New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
        local function LayoutColumns()
            local mobile = body.AbsoluteSize.X < 590
            if mobile then
                left.Position = UDim2.new(0, 0, 0, 0)
                left.Size = UDim2.new(1, 0, 0, 0)
                right.Position = UDim2.new(0, 0, 0, left.AbsoluteSize.Y + 14)
                right.Size = UDim2.new(1, 0, 0, 0)
            else
                left.Position = UDim2.new(0, 0, 0, 0)
                left.Size = UDim2.new(0.5, -9, 0, 0)
                right.Position = UDim2.new(0.5, 9, 0, 0)
                right.Size = UDim2.new(0.5, -9, 0, 0)
            end
        end
        left:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if body.AbsoluteSize.X < 590 then
                right.Position = UDim2.new(0, 0, 0, left.AbsoluteSize.Y + 14)
            end
        end)
        body:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutColumns)
        tab.Page = page
        tab.Scroller = scroller
        tab.LeftColumn = left
        tab.RightColumn = right
        tab.LayoutColumns = LayoutColumns
        LayoutColumns()
    end

    function window:SelectTab(name)
        for _, tab in ipairs(self.Tabs) do
            local selected = tab.Name == name
            tab.Page.Visible = selected
            tab.Button.BackgroundTransparency = selected and 0 or 1
            tab.ButtonStroke.Transparency = selected and 0.45 or 1
            tab.Label.TextColor3 = selected and Theme.Text or Theme.Muted
            tab.Icon.ImageColor3 = selected and Theme.Text or Theme.Muted
            if selected then
                self.CurrentTab = tab
                pageTitle.Text = tab.Name
            end
        end
        for _, panel in pairs(self.Managers) do
            if panel.Overlay then panel.Overlay.Visible = false end
        end
    end

    local function AttachSectionMethods(section)
        local card = section.Card

        local function Register(name, kind, target, key, setter, getter)
            if key and setter then
                window.Controls[key] = setter
            end
            table.insert(window.SearchIndex, {
                Name = tostring(name or kind),
                Kind = kind,
                Tab = section.Tab,
                Section = section,
                Target = target
            })
            return {
                Instance = target,
                Set = function(_, value, silent)
                    if setter then setter(value, silent) end
                end,
                Get = function()
                    return getter and getter() or (key and window.Flags[key])
                end,
                Destroy = function()
                    if target and target.Parent then target:Destroy() end
                end
            }
        end

        local function NormalizeOptions(value, fallback)
            if type(value) ~= "table" then
                return { Default = value == nil and fallback or value }
            end
            return value
        end

        local function Field(name, height)
            local block = New("Frame", {
                Size = UDim2.new(1, 0, 0, height or 40),
                BackgroundTransparency = 1,
                Parent = card
            })
            local label = New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 0, 22),
                Text = tostring(name or ""),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = block
            })
            return block, label
        end

        local function OpenColorPicker(current, apply)
            local old = window.ColorEditorOverlay
            if old and old.Parent then old:Destroy() end
            local overlay = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(5, 7, 11),
                BackgroundTransparency = 0.24,
                ZIndex = 70,
                Parent = main
            })
            window.ColorEditorOverlay = overlay
            local panel = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(280, 154),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 71,
                Parent = overlay
            })
            Corner(panel, 12)
            Gradient(panel, Theme.CardTop, Theme.WindowBottom, 90)
            Stroke(panel, Theme.LineLight, 0.2, 1)
            New("TextLabel", {
                Position = UDim2.fromOffset(14, 10),
                Size = UDim2.new(1, -50, 0, 28),
                Text = "Color Picker",
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 72,
                Parent = panel
            })
            local close = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -8, 0, 6),
                Size = UDim2.fromOffset(30, 30),
                BackgroundTransparency = 1,
                Text = "×",
                Font = Enum.Font.GothamMedium,
                TextSize = 23,
                TextColor3 = Theme.Muted,
                ZIndex = 72,
                Parent = panel
            })
            local hex = string.format("#%02X%02X%02X", math.floor(current.R * 255 + 0.5), math.floor(current.G * 255 + 0.5), math.floor(current.B * 255 + 0.5))
            local input = New("TextBox", {
                Position = UDim2.fromOffset(14, 48),
                Size = UDim2.new(1, -28, 0, 36),
                BackgroundColor3 = Color3.fromRGB(24, 27, 38),
                Text = hex,
                PlaceholderText = "#RRGGBB",
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                ClearTextOnFocus = false,
                ZIndex = 72,
                Parent = panel
            })
            Corner(input, 7)
            Stroke(input, Theme.Line, 0.2, 1)
            New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = input })
            local save = New("TextButton", {
                Position = UDim2.fromOffset(14, 96),
                Size = UDim2.new(1, -28, 0, 36),
                BackgroundColor3 = window.Accent,
                Text = "Apply Color",
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = Theme.Text,
                ZIndex = 72,
                Parent = panel
            })
            Corner(save, 7)
            local function closePicker()
                if overlay and overlay.Parent then overlay:Destroy() end
            end
            close.Activated:Connect(closePicker)
            save.Activated:Connect(function()
                local r, g, b = string.match(input.Text, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
                if not r then
                    input.Text = "Invalid color"
                    return
                end
                SafeCall(apply, Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)))
                closePicker()
            end)
        end

        function section:AddToggle(name, options, callback)
            options = NormalizeOptions(options, false)
            if type(options) == "table" and options.Default == nil then options.Default = false end
            local key = tostring(options.Flag or name)
            local row = New("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                Parent = card
            })
            local label = New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -106, 1, 0),
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row
            })
            local switch = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(42, 24),
                BackgroundColor3 = Theme.ElementBottom,
                Parent = row
            })
            Corner(switch, 12)
            local onLayer = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = window.Accent,
                BackgroundTransparency = 1,
                Parent = switch
            })
            Corner(onLayer, 12)
            table.insert(window.AccentBindings, { Type = "Color", Object = onLayer, Property = "BackgroundColor3" })
            local knob = New("Frame", {
                Position = UDim2.new(0, 3, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Theme.Text,
                Parent = switch
            })
            Corner(knob, 9)
            local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = row })
            local state = false
            local function set(value, silent)
                state = value == true
                window.Flags[key] = state
                Tween(onLayer, { BackgroundTransparency = state and 0 or 1 }, 0.15)
                Tween(knob, { Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.15)
                Tween(label, { TextColor3 = state and Theme.Text or Theme.Muted }, 0.15)
                if not silent then SafeCall(callback, state) end
            end
            hit.Activated:Connect(function() set(not state) end)
            local bindChip
            if options.Keybind then
                bindChip = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -63, 0.5, 0),
                    Size = UDim2.fromOffset(35, 25),
                    BackgroundColor3 = Theme.ElementTop,
                    Text = tostring(options.Keybind),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 11,
                    TextColor3 = Theme.Sub,
                    Parent = row
                })
                Corner(bindChip, 6)
                local listener = { Listening = false, Key = Enum.KeyCode[tostring(options.Keybind)], Toggle = function() set(not state) end }
                listener.Refresh = function()
                    bindChip.Text = listener.Listening and "..." or (listener.Key and listener.Key.Name or "-")
                end
                bindChip.Activated:Connect(function()
                    listener.Listening = true
                    listener.Refresh()
                end)
                table.insert(window.KeyListeners, listener)
            end
            local colorOption = options.ColorPicker
            if colorOption then
                local initialColor = typeof(colorOption) == "Color3" and colorOption or window.Accent
                local swatch = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, options.Keybind and -105 or -62, 0.5, 0),
                    Size = UDim2.fromOffset(20, 20),
                    BackgroundColor3 = initialColor,
                    Text = "",
                    Parent = row
                })
                Corner(swatch, 5)
                Stroke(swatch, Theme.LineLight, 0.2, 1)
                window.Flags[key .. "/Color"] = initialColor
                local function setColor(color, silent)
                    window.Flags[key .. "/Color"] = color
                    swatch.BackgroundColor3 = color
                    if not silent then SafeCall(options.OnColorChanged, color) end
                end
                window.Controls[key .. "/Color"] = setColor
                swatch.Activated:Connect(function() OpenColorPicker(window.Flags[key .. "/Color"], setColor) end)
                label.Size = UDim2.new(1, -132, 1, 0)
            end
            set(options.Default, true)
            return Register(name, "Toggle", row, key, set, function() return state end)
        end

        function section:AddSlider(name, options, callback)
            options = type(options) == "table" and options or {}
            local min = tonumber(options.Min) or 0
            local max = tonumber(options.Max) or 100
            if max <= min then max = min + 1 end
            local increment = tonumber(options.Increment or options.Step) or 1
            if increment <= 0 then increment = 1 end
            local key = tostring(options.Flag or name)
            local block = New("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, Parent = card })
            New("TextLabel", {
                Position = UDim2.fromOffset(12, 3),
                Size = UDim2.new(1, -82, 0, 22),
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = block
            })
            local valueLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 3),
                Size = UDim2.fromOffset(68, 22),
                Text = "0",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = Theme.Sub,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = block
            })
            local track = New("Frame", {
                Position = UDim2.fromOffset(12, 38),
                Size = UDim2.new(1, -24, 0, 7),
                BackgroundColor3 = Theme.ElementBottom,
                Parent = block
            })
            Corner(track, 4)
            local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = window.Accent, Parent = track })
            Corner(fill, 4)
            table.insert(window.AccentBindings, { Type = "Color", Object = fill, Property = "BackgroundColor3" })
            local knob = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Theme.Text,
                Parent = track
            })
            Corner(knob, 7)
            local hit = New("TextButton", {
                Position = UDim2.fromOffset(6, 29),
                Size = UDim2.new(1, -12, 0, 24),
                BackgroundTransparency = 1,
                Parent = block
            })
            local value = min
            local dragging = false
            local function set(newValue, silent)
                newValue = math.clamp(tonumber(newValue) or min, min, max)
                newValue = min + math.floor(((newValue - min) / increment) + 0.5) * increment
                newValue = math.clamp(tonumber(string.format("%.5f", newValue)), min, max)
                value = newValue
                local fraction = (value - min) / (max - min)
                fill.Size = UDim2.new(fraction, 0, 1, 0)
                knob.Position = UDim2.new(fraction, 0, 0.5, 0)
                valueLabel.Text = tostring(value)
                window.Flags[key] = value
                if not silent then SafeCall(callback, value) end
            end
            local function update(x)
                local fraction = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                set(min + (max - min) * fraction)
            end
            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input.Position.X)
                end
            end)
            hit.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            set(options.Default == nil and min or options.Default, true)
            return Register(name, "Slider", block, key, set, function() return value end)
        end

        local function CreateDropdown(name, options, callback, multi, search)
            options = type(options) == "table" and options or {}
            local choices = options.Options or options.Values or options.Items or (#options > 0 and options or {})
            local key = tostring(options.Flag or name)
            local block = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
            New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = block })
            New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 7), Parent = block })
            New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
                Parent = block
            })
            local box = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.ElementBottom,
                Text = "",
                LayoutOrder = 2,
                Parent = block
            })
            Corner(box, 7)
            Stroke(box, Theme.Line, 0.35, 1)
            local valueLabel = New("TextLabel", {
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Text = "Select...",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = Theme.Sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = box
            })
            local arrow = AddIcon(box, "chevron-down", 16, Theme.Muted)
            arrow.AnchorPoint = Vector2.new(1, 0.5)
            arrow.Position = UDim2.new(1, -10, 0.5, 0)
            local wrapper = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(20, 22, 30),
                ClipsDescendants = true,
                LayoutOrder = 3,
                Parent = block
            })
            Corner(wrapper, 7)
            Stroke(wrapper, Theme.Line, 0.3, 1)
            local contentY = 0
            local searchBox
            if search then
                searchBox = New("TextBox", {
                    Position = UDim2.fromOffset(6, 6),
                    Size = UDim2.new(1, -12, 0, 30),
                    BackgroundColor3 = Theme.ElementBottom,
                    PlaceholderText = "Search options...",
                    PlaceholderColor3 = Theme.Muted,
                    Text = "",
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    ClearTextOnFocus = false,
                    Parent = wrapper
                })
                Corner(searchBox, 6)
                contentY = 42
            end
            local scroll = New("ScrollingFrame", {
                Position = UDim2.fromOffset(0, contentY),
                Size = UDim2.new(1, 0, 1, -contentY),
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = window.Accent,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = wrapper
            })
            New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = scroll })
            local selected = {}
            local itemButtons = {}
            local open = false
            local function displayValue()
                if multi then
                    local result = {}
                    for _, item in ipairs(choices) do
                        if selected[item] then table.insert(result, tostring(item)) end
                    end
                    valueLabel.Text = #result > 0 and table.concat(result, ", ") or "None"
                    valueLabel.TextColor3 = #result > 0 and Theme.Text or Theme.Muted
                else
                    valueLabel.Text = tostring(selected.Value or "Select...")
                    valueLabel.TextColor3 = selected.Value and Theme.Text or Theme.Muted
                end
            end
            local function close()
                open = false
                wrapper.Size = UDim2.new(1, 0, 0, 0)
                arrow.Rotation = 0
                if window.OpenDropdownClose == close then window.OpenDropdownClose = nil end
            end
            local function updateItems()
                for choice, button in pairs(itemButtons) do
                    local matches = not searchBox or searchBox.Text == "" or string.find(string.lower(tostring(choice)), string.lower(searchBox.Text), 1, true) ~= nil
                    button.Visible = matches
                    if multi then
                        button.TextColor3 = selected[choice] and Theme.Text or Theme.Muted
                        button.BackgroundTransparency = selected[choice] and 0.82 or 1
                    else
                        button.TextColor3 = selected.Value == choice and Theme.Text or Theme.Muted
                    end
                end
            end
            local function set(value, silent)
                if multi then
                    selected = {}
                    if type(value) == "table" then
                        for _, choice in ipairs(value) do selected[choice] = true end
                    elseif value ~= nil then
                        selected[value] = true
                    end
                    local result = {}
                    for _, choice in ipairs(choices) do if selected[choice] then table.insert(result, choice) end end
                    window.Flags[key] = result
                else
                    if type(value) == "table" then value = value[1] end
                    local valid = false
                    for _, choice in ipairs(choices) do if choice == value then valid = true break end end
                    if not valid then value = choices[1] end
                    selected = { Value = value }
                    window.Flags[key] = value
                end
                displayValue()
                updateItems()
                if not silent then
                    if multi then
                        local result = {}
                        for _, choice in ipairs(choices) do if selected[choice] then table.insert(result, choice) end end
                        SafeCall(callback, result)
                    else
                        SafeCall(callback, selected.Value)
                    end
                end
            end
            for index, choice in ipairs(choices) do
                local button = New("TextButton", {
                    Size = UDim2.new(1, -8, 0, 30),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundColor3 = Theme.ElementTop,
                    BackgroundTransparency = 1,
                    Text = tostring(choice),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextColor3 = Theme.Muted,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    LayoutOrder = index,
                    Parent = scroll
                })
                New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6), Parent = button })
                Corner(button, 5)
                itemButtons[choice] = button
                button.Activated:Connect(function()
                    if multi then
                        selected[choice] = not selected[choice]
                        local result = {}
                        for _, item in ipairs(choices) do if selected[item] then table.insert(result, item) end end
                        set(result)
                    else
                        set(choice)
                        close()
                    end
                end)
            end
            if searchBox then searchBox:GetPropertyChangedSignal("Text"):Connect(updateItems) end
            box.Activated:Connect(function()
                if open then close() return end
                if window.OpenDropdownClose then window.OpenDropdownClose() end
                open = true
                window.OpenDropdownClose = close
                local count = #choices
                local listHeight = math.min(math.max(count, 1) * 31, 145)
                wrapper.Size = UDim2.new(1, 0, 0, listHeight + contentY)
                arrow.Rotation = 180
                if searchBox then
                    searchBox.Text = ""
                    if not UserInputService.TouchEnabled then task.defer(function() pcall(function() searchBox:CaptureFocus() end) end) end
                end
                updateItems()
            end)
            local default = options.Default
            if default == nil then default = multi and {} or choices[1] end
            set(default, true)
            return Register(name, multi and "MultiDropdown" or (search and "SearchDropdown" or "Dropdown"), block, key, set, function()
                if multi then
                    local result = {}
                    for _, choice in ipairs(choices) do if selected[choice] then table.insert(result, choice) end end
                    return result
                end
                return selected.Value
            end)
        end

        function section:AddDropdown(name, options, callback)
            return CreateDropdown(name, options, callback, false, false)
        end

        function section:AddMultiDropdown(name, options, callback)
            return CreateDropdown(name, options, callback, true, false)
        end

        function section:AddSearchDropdown(name, options, callback)
            return CreateDropdown(name, options, callback, false, true)
        end

        function section:AddLabel(text, description)
            local labelText = description == nil and tostring(text or "") or tostring(description)
            local searchName = description == nil and labelText or tostring(text or labelText)
            local block = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
            local label = New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.fromOffset(12, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = labelText,
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = Theme.Sub,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = block
            })
            New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = block })
            local function set(value)
                label.Text = tostring(value or "")
            end
            return Register(searchName, "Label", block, nil, set, function() return label.Text end)
        end

        function section:AddInput(name, options, callback)
            options = NormalizeOptions(options, "")
            local key = tostring(options.Flag or name)
            local block = New("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, Parent = card })
            New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 0, 22),
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = block
            })
            local input = New("TextBox", {
                Position = UDim2.fromOffset(12, 27),
                Size = UDim2.new(1, -24, 0, 34),
                BackgroundColor3 = Theme.ElementBottom,
                Text = tostring(options.Default or ""),
                PlaceholderText = tostring(options.Placeholder or "Type here..."),
                PlaceholderColor3 = Theme.Muted,
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = block
            })
            Corner(input, 7)
            Stroke(input, Theme.Line, 0.35, 1)
            New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = input })
            local function set(value, silent)
                input.Text = tostring(value or "")
                window.Flags[key] = input.Text
                if not silent then SafeCall(callback, input.Text, false) end
            end
            input.FocusLost:Connect(function(enterPressed)
                window.Flags[key] = input.Text
                SafeCall(callback, input.Text, enterPressed)
            end)
            window.Flags[key] = input.Text
            return Register(name, "Input", block, key, set, function() return input.Text end)
        end

        function section:AddColorPicker(name, options, callback)
            options = NormalizeOptions(options, window.Accent)
            local key = tostring(options.Flag or name)
            local block, label = Field(name, 42)
            label.Size = UDim2.new(1, -64, 1, 0)
            local current = typeof(options.Default) == "Color3" and options.Default or window.Accent
            local swatch = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(34, 23),
                BackgroundColor3 = current,
                Text = "",
                Parent = block
            })
            Corner(swatch, 6)
            Stroke(swatch, Theme.LineLight, 0.2, 1)
            local function set(color, silent)
                if typeof(color) ~= "Color3" then return end
                current = color
                swatch.BackgroundColor3 = color
                window.Flags[key] = color
                if not silent then SafeCall(callback, color) end
            end
            swatch.Activated:Connect(function() OpenColorPicker(current, set) end)
            set(current, true)
            return Register(name, "ColorPicker", block, key, set, function() return current end)
        end
        section.AddColor = section.AddColorPicker

        function section:AddButton(name, callback)
            if type(callback) == "table" then callback = callback.Callback end
            local row = New("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Parent = card })
            local button = New("TextButton", {
                Position = UDim2.fromOffset(12, 5),
                Size = UDim2.new(1, -24, 0, 38),
                BackgroundColor3 = Theme.ElementTop,
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                Parent = row
            })
            Corner(button, 7)
            local outline = Stroke(button, Theme.Line, 0.3, 1)
            button.MouseEnter:Connect(function() Tween(outline, { Color = window.Accent, Transparency = 0 }, 0.15) end)
            button.MouseLeave:Connect(function() Tween(outline, { Color = Theme.Line, Transparency = 0.3 }, 0.15) end)
            button.Activated:Connect(function() SafeCall(callback) end)
            return Register(name, "Button", row)
        end

        function section:AddViewport(name, options)
            options = type(options) == "table" and options or {}
            local height = math.clamp(tonumber(options.Height) or 200, 90, 480)
            local block = New("Frame", { Size = UDim2.new(1, 0, 0, height + 54), BackgroundTransparency = 1, Parent = card })
            New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 0, 22),
                Text = tostring(name),
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = block
            })
            local holder = New("Frame", {
                Position = UDim2.fromOffset(12, 27),
                Size = UDim2.new(1, -24, 0, height),
                BackgroundColor3 = Color3.fromRGB(18, 20, 27),
                ClipsDescendants = true,
                Parent = block
            })
            Corner(holder, 8)
            Stroke(holder, Theme.Line, 0.3, 1)
            local viewport = New("ViewportFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Ambient = Color3.fromRGB(175, 175, 185),
                LightColor = Color3.fromRGB(255, 255, 255),
                LightDirection = Vector3.new(-0.35, -0.6, 1),
                Active = true,
                Parent = holder
            })
            local world = New("WorldModel", { Parent = viewport })
            local providedCamera = options.Camera
            local camera = providedCamera or Instance.new("Camera")
            camera.FieldOfView = camera.FieldOfView > 0 and camera.FieldOfView or 35
            camera.Parent = viewport
            viewport.CurrentCamera = camera
            local sourceObject = options.Object
            local clone
            local center = Vector3.zero
            local bounds = Vector3.new(4, 4, 4)
            local yaw, pitch = 0, 0
            local distance = 10
            local handle = { Instance = block, Frame = viewport, Interactive = options.Interactive == true, AutoFocus = options.AutoFocus ~= false, Height = height, Dragging = false, LastPosition = nil, Destroyed = false }
            local function clearClone()
                if clone and clone.Parent then clone:Destroy() end
                clone = nil
            end
            local function copyObject(object)
                clearClone()
                sourceObject = object
                if not object then return end
                local oldArchivable
                pcall(function()
                    oldArchivable = object.Archivable
                    object.Archivable = true
                end)
                local ok, result = pcall(function() return object:Clone() end)
                if oldArchivable ~= nil then pcall(function() object.Archivable = oldArchivable end) end
                if not ok or not result then return end
                clone = result
                for _, descendant in ipairs(clone:GetDescendants()) do
                    if descendant:IsA("BaseScript") or descendant:IsA("Sound") or descendant:IsA("Tool") or descendant:IsA("BillboardGui") or descendant:IsA("ProximityPrompt") then
                        pcall(function() descendant:Destroy() end)
                    elseif descendant:IsA("BasePart") then
                        descendant.Anchored = true
                        descendant.CanCollide = false
                    end
                end
                if clone:IsA("BasePart") then
                    clone.Anchored = true
                    clone.CanCollide = false
                end
                clone.Parent = world
                if handle.AutoFocus then handle:Focus() else handle:RenderCamera() end
            end
            function handle:RenderCamera()
                if not camera or not camera.Parent then return end
                local cp = math.cos(pitch)
                local offset = Vector3.new(math.sin(yaw) * cp, math.sin(pitch), math.cos(yaw) * cp) * distance
                camera.CFrame = CFrame.lookAt(center + offset, center)
            end
            function handle:Focus()
                if not clone then return end
                local foundParts = {}
                if clone:IsA("BasePart") then table.insert(foundParts, clone) end
                for _, descendant in ipairs(clone:GetDescendants()) do
                    if descendant:IsA("BasePart") then table.insert(foundParts, descendant) end
                end
                if #foundParts == 0 then return end
                local minV = Vector3.new(math.huge, math.huge, math.huge)
                local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
                for _, part in ipairs(foundParts) do
                    local half = part.Size * 0.5
                    local p = part.Position
                    minV = Vector3.new(math.min(minV.X, p.X - half.X), math.min(minV.Y, p.Y - half.Y), math.min(minV.Z, p.Z - half.Z))
                    maxV = Vector3.new(math.max(maxV.X, p.X + half.X), math.max(maxV.Y, p.Y + half.Y), math.max(maxV.Z, p.Z + half.Z))
                end
                center = (minV + maxV) * 0.5
                bounds = maxV - minV
                distance = math.max(bounds.Magnitude * 1.25, 4)
                yaw = 0
                pitch = 0.08
                self:RenderCamera()
            end
            function handle:DragTo(position)
                if not self.Interactive or not self.Dragging then return end
                if self.LastPosition then
                    local delta = position - self.LastPosition
                    yaw = yaw - delta.X * 0.012
                    pitch = math.clamp(pitch + delta.Y * 0.009, -1.2, 1.2)
                    self:RenderCamera()
                end
                self.LastPosition = position
            end
            function handle:ZoomBy(delta)
                if not self.Interactive then return end
                distance = math.clamp(distance - delta * 1.25, math.max(bounds.Magnitude * 0.5, 2), math.max(bounds.Magnitude * 5, 15))
                self:RenderCamera()
            end
            function handle:SetVisible(visible)
                block.Visible = visible == true
            end
            function handle:SetHeight(newHeight)
                self.Height = math.clamp(tonumber(newHeight) or self.Height, 90, 480)
                holder.Size = UDim2.new(1, -24, 0, self.Height)
                block.Size = UDim2.new(1, 0, 0, self.Height + 54)
            end
            function handle:SetInteractive(visible)
                self.Interactive = visible == true
                if not self.Interactive then
                    self.Dragging = false
                    self.LastPosition = nil
                    if window.ActiveViewport == self then window.ActiveViewport = nil end
                end
            end
            function handle:SetCamera(newCamera)
                if not newCamera or not newCamera:IsA("Camera") then return end
                if camera ~= providedCamera and camera and camera.Parent then camera:Destroy() end
                camera = newCamera
                providedCamera = newCamera
                camera.Parent = viewport
                viewport.CurrentCamera = camera
                self:RenderCamera()
            end
            function handle:SetObject(object)
                copyObject(object)
            end
            function handle:Destroy()
                self.Destroyed = true
                if window.ActiveViewport == self then window.ActiveViewport = nil end
                if clone and clone.Parent then clone:Destroy() end
                if camera and camera.Parent then camera:Destroy() end
                if block and block.Parent then block:Destroy() end
            end
            viewport.InputBegan:Connect(function(input)
                if self.Interactive and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    window.ActiveViewport = self
                    self.Dragging = true
                    self.LastPosition = input.Position
                end
            end)
            viewport.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    self.Dragging = false
                    self.LastPosition = nil
                end
            end)
            copyObject(sourceObject)
            return Register(name, "Viewport", block, nil, nil, function() return handle end).Instance and handle
        end

        return section
    end

    function window:CreateTab(name, icon)
        local options
        if type(name) == "table" then
            options = name
        else
            options = { Name = name, Icon = icon }
        end
        local tabName = tostring(options.Name or options.Title or ("Tab " .. (#self.Tabs + 1)))
        local tabIcon = options.Icon or "layers"
        local button = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = #self.Tabs + 1,
            Parent = tabList
        })
        Corner(button, 8)
        Gradient(button, Theme.ElementTop, Theme.ElementBottom, 90)
        local buttonStroke = Stroke(button, Theme.LineLight, 1, 1)
        local tabImage = AddIcon(button, tabIcon, 20, Theme.Muted)
        tabImage.Position = UDim2.fromOffset(10, 11)
        local label = New("TextLabel", {
            Position = UDim2.fromOffset(40, 0),
            Size = UDim2.new(1, -48, 1, 0),
            Text = tabName,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = button
        })
        local tab = { Name = tabName, IconName = tabIcon, Button = button, ButtonStroke = buttonStroke, Icon = tabImage, Label = label, Sections = {} }
        NewTabPage(tab)
        function tab:CreateSection(sectionName, side)
            side = string.lower(tostring(side or "left"))
            local column = side == "right" and self.RightColumn or self.LeftColumn
            local holder = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = column
            })
            local heading = New("Frame", {
                Size = UDim2.new(1, 0, 0, 29),
                BackgroundTransparency = 1,
                Parent = holder
            })
            local headingIcon = AddIcon(heading, options.SectionIcon or "layers", 18, Theme.Muted)
            headingIcon.Position = UDim2.fromOffset(2, 5)
            local headingLabel = New("TextLabel", {
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -32, 1, 0),
                Text = tostring(sectionName or "Section"),
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                TextColor3 = Theme.Sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = heading
            })
            local card = New("Frame", {
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = holder
            })
            Corner(card, 10)
            Gradient(card, Theme.CardTop, Theme.CardBottom, 90)
            Stroke(card, Theme.LineLight, 0.55, 1)
            New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
            New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = card })
            local section = { Name = tostring(sectionName or "Section"), Tab = self, Holder = holder, Card = card, Side = side }
            table.insert(self.Sections, section)
            table.insert(window.SearchIndex, { Name = section.Name, Kind = "Section", Tab = self, Section = section, Target = holder })
            AttachSectionMethods(section)
            return section
        end
        function tab:CreateLeftSection(sectionName)
            return self:CreateSection(sectionName, "left")
        end
        function tab:CreateRightSection(sectionName)
            return self:CreateSection(sectionName, "right")
        end
        function tab:Select()
            window:SelectTab(self.Name)
        end
        button.Activated:Connect(function() window:SelectTab(tabName) end)
        button.MouseEnter:Connect(function()
            if window.CurrentTab ~= tab then label.TextColor3 = Theme.Sub end
        end)
        button.MouseLeave:Connect(function()
            if window.CurrentTab ~= tab then label.TextColor3 = Theme.Muted end
        end)
        table.insert(self.Tabs, tab)
        table.insert(self.SearchIndex, { Name = tabName, Kind = "Tab", Tab = tab, Target = tab.Page })
        if #self.Tabs == 1 then self:SelectTab(tabName) end
        return tab
    end

    window.AddTab = window.CreateTab

    local function AddManagerButton(icon, callback)
        local button = New("TextButton", {
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = sidebar
        })
        Corner(button, 8)
        Gradient(button, Theme.ElementTop, Theme.ElementBottom, 90)
        Stroke(button, Theme.Line, 0.4, 1)
        local image = AddIcon(button, icon, 18, Theme.Muted)
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.Position = UDim2.fromScale(0.5, 0.5)
        button.MouseEnter:Connect(function() Tween(image, { ImageColor3 = window.Accent }, 0.15) end)
        button.MouseLeave:Connect(function() Tween(image, { ImageColor3 = Theme.Muted }, 0.15) end)
        button.Activated:Connect(callback)
        table.insert(window.ManagerButtons, { Button = button, Icon = image })
        ResizeLayout()
        return button
    end

    local function CreateManagerPanel(key, titleText)
        local overlay = New("Frame", {
            Name = key .. "Overlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(7, 9, 14),
            BackgroundTransparency = 0.22,
            Visible = false,
            ZIndex = 50,
            Parent = main
        })
        local panel = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0.86, 0, 0.82, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 51,
            Parent = overlay
        })
        New("UISizeConstraint", { MinSize = Vector2.new(270, 280), MaxSize = Vector2.new(540, 520), Parent = panel })
        Corner(panel, 12)
        Gradient(panel, Theme.CardTop, Theme.WindowBottom, 90)
        Stroke(panel, Theme.LineLight, 0.2, 1)
        local title = New("TextLabel", {
            Position = UDim2.fromOffset(18, 13),
            Size = UDim2.new(1, -65, 0, 32),
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 52,
            Parent = panel
        })
        local close = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.fromOffset(32, 32),
            BackgroundTransparency = 1,
            Text = "×",
            Font = Enum.Font.GothamMedium,
            TextSize = 24,
            TextColor3 = Theme.Muted,
            ZIndex = 52,
            Parent = panel
        })
        close.Activated:Connect(function() overlay.Visible = false end)
        local content = New("ScrollingFrame", {
            Position = UDim2.fromOffset(14, 54),
            Size = UDim2.new(1, -28, 1, -66),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = window.Accent,
            ZIndex = 52,
            Parent = panel
        })
        New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
        New("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = content })
        local manager = { Overlay = overlay, Panel = panel, Content = content, Title = title }
        window.Managers[key] = manager
        function manager:Open()
            for _, other in pairs(window.Managers) do
                if other.Overlay then other.Overlay.Visible = false end
            end
            overlay.Visible = true
        end
        return manager
    end

    local function AddManagerLabel(parent, text)
        return New("TextLabel", {
            Size = UDim2.new(1, -8, 0, 28),
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = Theme.Sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 53,
            Parent = parent
        })
    end

    local function AddManagerInput(parent, placeholder, defaultText)
        local box = New("TextBox", {
            Size = UDim2.new(1, -8, 0, 38),
            BackgroundColor3 = Color3.fromRGB(25, 28, 39),
            Text = defaultText or "",
            PlaceholderText = placeholder or "Enter a value",
            PlaceholderColor3 = Theme.Muted,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex = 53,
            Parent = parent
        })
        Corner(box, 7)
        Stroke(box, Theme.Line, 0.2, 1)
        New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box })
        return box
    end

    local function AddManagerButtonRow(parent, label, callback, icon)
        local button = New("TextButton", {
            Size = UDim2.new(1, -8, 0, 38),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Text = label,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Theme.Text,
            ZIndex = 53,
            Parent = parent
        })
        Corner(button, 7)
        Gradient(button, Theme.ElementTop, Theme.ElementBottom, 90)
        Stroke(button, Theme.Line, 0.35, 1)
        button.Activated:Connect(function() SafeCall(callback) end)
        return button
    end

    local function Serialize(value)
        if typeof(value) == "Color3" then
            return { __type = "Color3", R = value.R, G = value.G, B = value.B }
        end
        if type(value) == "table" then
            local result = {}
            for key, item in pairs(value) do result[key] = Serialize(item) end
            return result
        end
        if type(value) == "string" or type(value) == "number" or type(value) == "boolean" or value == nil then
            return value
        end
        return nil
    end

    local function Deserialize(value)
        if type(value) ~= "table" then return value end
        if value.__type == "Color3" then
            return Color3.new(tonumber(value.R) or 1, tonumber(value.G) or 1, tonumber(value.B) or 1)
        end
        local result = {}
        for key, item in pairs(value) do result[key] = Deserialize(item) end
        return result
    end

    local function EnsureConfigFolder()
        pcall(function()
            if isfolder and makefolder and not isfolder(window.ConfigFolder) then
                makefolder(window.ConfigFolder)
            end
        end)
    end

    function window:SaveConfig(name)
        name = tostring(name or "")
        name = string.gsub(name, "[^%w%-%_ ]", "")
        name = string.gsub(name, "%s+", "_")
        if name == "" then return false end
        local data = {}
        for key, value in pairs(self.Flags) do
            data[key] = Serialize(value)
        end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok then return false end
        local saved = false
        pcall(function()
            EnsureConfigFolder()
            if writefile then
                writefile(self.ConfigFolder .. "/" .. name .. ".json", encoded)
                saved = true
            end
        end)
        return saved
    end

    function window:LoadConfig(name)
        name = tostring(name or "")
        name = string.gsub(name, "[^%w%-%_ ]", "")
        name = string.gsub(name, "%s+", "_")
        if name == "" then return false end
        local loaded = false
        pcall(function()
            local path = self.ConfigFolder .. "/" .. name .. ".json"
            if isfile and readfile and isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                if type(data) == "table" then
                    for key, value in pairs(data) do
                        local parsed = Deserialize(value)
                        self.Flags[key] = parsed
                        if self.Controls[key] then
                            pcall(function() self.Controls[key](parsed, true) end)
                        end
                    end
                    loaded = true
                end
            end
        end)
        return loaded
    end

    function window:DeleteConfig(name)
        name = tostring(name or "")
        name = string.gsub(name, "[^%w%-%_ ]", "")
        name = string.gsub(name, "%s+", "_")
        if name == "" then return false end
        local removed = false
        pcall(function()
            local path = self.ConfigFolder .. "/" .. name .. ".json"
            if isfile and delfile and isfile(path) then
                delfile(path)
                removed = true
            end
        end)
        return removed
    end

    function window:GetConfigs()
        local names = {}
        pcall(function()
            if listfiles and isfolder and isfolder(self.ConfigFolder) then
                for _, path in ipairs(listfiles(self.ConfigFolder)) do
                    local name = string.match(path, "([^/\\]+)%.json$")
                    if name then table.insert(names, name) end
                end
            end
        end)
        table.sort(names)
        return names
    end

    function window:LoadConfigManger()
        if self.Managers.Config then return self.Managers.Config end
        local manager = CreateManagerPanel("Config", "Config Manager")
        local nameBox = AddManagerInput(manager.Content, "Config name", "default")
        AddManagerButtonRow(manager.Content, "Save Config", function()
            local ok = self:SaveConfig(nameBox.Text)
            self:Notify({ Title = "Config Manager", Info = ok and "Configuration saved." or "Could not save. Check file API support.", Icon = ok and "check" or "alert-circle" })
        end)
        AddManagerButtonRow(manager.Content, "Load Config", function()
            local ok = self:LoadConfig(nameBox.Text)
            self:Notify({ Title = "Config Manager", Info = ok and "Configuration loaded." or "Config not found or file API unavailable.", Icon = ok and "check" or "alert-circle" })
        end)
        AddManagerButtonRow(manager.Content, "Delete Config", function()
            local ok = self:DeleteConfig(nameBox.Text)
            self:Notify({ Title = "Config Manager", Info = ok and "Configuration deleted." or "Could not delete config.", Icon = ok and "check" or "alert-circle" })
        end)
        AddManagerLabel(manager.Content, "Available configs")
        local list = New("Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ZIndex = 53,
            Parent = manager.Content
        })
        New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
        local function RefreshList()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end
            local configs = self:GetConfigs()
            if #configs == 0 then AddManagerLabel(list, "No configs found yet.") end
            for _, configName in ipairs(configs) do
                AddManagerButtonRow(list, configName, function() nameBox.Text = configName end)
            end
        end
        AddManagerButtonRow(manager.Content, "Refresh List", RefreshList, "refresh-cw")
        RefreshList()
        AddManagerButton("folder", function() manager:Open() end)
        return manager
    end

    function window:LoadSettingManger()
        if self.Managers.Settings then return self.Managers.Settings end
        local manager = CreateManagerPanel("Settings", "Settings Manager")
        AddManagerLabel(manager.Content, "Watermark")
        AddManagerButtonRow(manager.Content, self.ShowWaterMark and "Hide Watermark" or "Show Watermark", function()
            self.ShowWaterMark = not self.ShowWaterMark
            self.Watermark.Visible = self.ShowWaterMark and main.AbsoluteSize.X >= 650
            local button = manager.Content:FindFirstChild("WatermarkToggle")
            if button then button.Text = self.ShowWaterMark and "Hide Watermark" or "Show Watermark" end
            pageTitle.Size = UDim2.new(self.ShowWaterMark and 0.58 or 1, -22, 1, 0)
            self:Notify({ Title = "Settings", Info = "Watermark " .. (self.ShowWaterMark and "enabled." or "disabled."), Icon = "settings" })
        end).Name = "WatermarkToggle"
        AddManagerLabel(manager.Content, "Accent color (hex)")
        local colorBox = AddManagerInput(manager.Content, "#16BEA5", "#16BEA5")
        AddManagerButtonRow(manager.Content, "Apply Accent", function()
            local r, g, b = string.match(colorBox.Text, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
            if not r then
                self:Notify({ Title = "Settings", Info = "Enter a color like #16BEA5.", Icon = "alert-circle" })
                return
            end
            ApplyAccent(Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)))
            self:Notify({ Title = "Settings", Info = "Accent color updated.", Icon = "check" })
        end)
        AddManagerButton("settings", function() manager:Open() end)
        return manager
    end

    function window:LoadSerachManger()
        if self.Managers.Search then return self.Managers.Search end
        local manager = CreateManagerPanel("Search", "Search")
        local searchBox = AddManagerInput(manager.Content, "Search tabs, sections and elements", "")
        local results = New("Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ZIndex = 53,
            Parent = manager.Content
        })
        local resultsLayout = New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = results })
        local function RefreshResults()
            for _, child in ipairs(results:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end
            local query = string.lower(string.match(searchBox.Text, "^%s*(.-)%s*$"))
            local found = 0
            for _, entry in ipairs(self.SearchIndex) do
                local name = string.lower(tostring(entry.Name or ""))
                local kind = string.lower(tostring(entry.Kind or ""))
                if query == "" or string.find(name, query, 1, true) or string.find(kind, query, 1, true) then
                    found += 1
                    if found > 40 then break end
                    local button = AddManagerButtonRow(results, entry.Name .. "  ·  " .. entry.Kind, function()
                        manager.Overlay.Visible = false
                        self:SelectTab(entry.Tab.Name)
                        task.defer(function()
                            local target = entry.Target
                            if target and target.Parent and entry.Tab.Scroller then
                                local y = target.AbsolutePosition.Y - entry.Tab.Scroller.AbsolutePosition.Y + entry.Tab.Scroller.CanvasPosition.Y - 12
                                entry.Tab.Scroller.CanvasPosition = Vector2.new(0, math.max(0, y))
                            end
                        end)
                    end)
                    button.TextXAlignment = Enum.TextXAlignment.Left
                    New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = button })
                end
            end
            if found == 0 then AddManagerLabel(results, "No matching elements.") end
        end
        searchBox:GetPropertyChangedSignal("Text"):Connect(RefreshResults)
        RefreshResults()
        AddManagerButton("search", function() RefreshResults() manager:Open() end)
        return manager
    end

    function window:LoadConfigManager() return self:LoadConfigManger() end
    function window:LoadSettingManager() return self:LoadSettingManger() end
    function window:LoadSearchManager() return self:LoadSerachManger() end
    function window:LoadSerachManager() return self:LoadSerachManger() end

    local dragging, dragStart, startPosition = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
        local active = window.ActiveViewport
        if active and active.Interactive and active.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            active:DragTo(input.Position)
        end
        if window.ActiveViewport and input.UserInputType == Enum.UserInputType.MouseWheel then
            window.ActiveViewport:ZoomBy(input.Position.Z)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if window.ActiveViewport then window.ActiveViewport.Dragging = false end
        end
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
        end
        for _, listener in ipairs(window.KeyListeners) do
            if listener.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                listener.Listening = false
                if input.KeyCode == Enum.KeyCode.Escape then
                    listener.Key = nil
                else
                    listener.Key = input.KeyCode
                end
                listener.Refresh()
            elseif not processed and not listener.Listening and listener.Key and input.KeyCode == listener.Key then
                listener.Toggle()
            end
        end
    end)

    main:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeLayout)
    ResizeLayout()

    function window:SetWatermarkVisible(visible)
        self.ShowWaterMark = visible == true
        self.Watermark.Visible = self.ShowWaterMark and main.AbsoluteSize.X >= 650
        pageTitle.Size = UDim2.new(self.ShowWaterMark and 0.58 or 1, -22, 1, 0)
    end

    function window:SetLogo(icon)
        self.Logo = icon
        local asset, offset, rectSize = ResolveIcon(icon)
        logo.Image = asset
        toggleIcon.Image = asset
        if offset then pcall(function() logo.ImageRectOffset = typeof(offset) == "Vector2" and offset or Vector2.new(offset[1] or offset.X or 0, offset[2] or offset.Y or 0) end) end
        if rectSize then pcall(function() logo.ImageRectSize = typeof(rectSize) == "Vector2" and rectSize or Vector2.new(rectSize[1] or rectSize.X or 0, rectSize[2] or rectSize.Y or 0) end) end
    end

    return window
end

return Library
