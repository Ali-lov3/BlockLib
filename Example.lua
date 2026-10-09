local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/BlockLib/refs/heads/main/Source.lua"))():CreateWindow({
    Title = "My UI",
    Logo = "layers",
    ConfigFolder = "MyUI_Configs",
    ShowWaterMark = true
})

local Main = Window:CreateTab("Main", "house")
local General = Main:CreateSection("General", "left")
local Advanced = Main:CreateSection("Advanced", "right")

General:AddLabel("Welcome", "A small example showing the available elements.")

General:AddToggle("Enabled", {
    Flag = "Enabled",
    Default = false,
    Keybind = "E"
}, function(value)
    Window:Notify({ Title = "Toggle", Info = "Enabled: " .. tostring(value) })
end)

General:AddToggle("Toggle with Color", {
    Flag = "ColorToggle",
    Default = true,
    ColorPicker = Color3.fromRGB(22, 190, 165)
}, function(value)
    print("Color toggle:", value)
end)

General:AddSlider("Walk Speed", {
    Flag = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 32,
    Increment = 1
}, function(value)
    print("Walk Speed:", value)
end)

General:AddDropdown("Mode", {
    Flag = "Mode",
    Options = { "Legit", "Rage", "Custom" },
    Default = "Legit"
}, function(value)
    print("Mode:", value)
end)

General:AddInput("Username", {
    Flag = "Username",
    Default = "",
    Placeholder = "Enter a username..."
}, function(value, enterPressed)
    if enterPressed then
        Window:Notify({ Title = "Input", Info = value })
    end
end)

Advanced:AddMultiDropdown("Targets", {
    Flag = "Targets",
    Options = { "Players", "NPCs", "Objects", "Animals" },
    Default = { "Players", "NPCs" }
}, function(values)
    print("Targets:", table.concat(values, ", "))
end)

Advanced:AddSearchDropdown("Fruit", {
    Flag = "Fruit",
    Options = { "Apple", "Banana", "Cherry", "Grape", "Lemon", "Mango", "Orange", "Peach", "Pear", "Plum" },
    Default = "Apple"
}, function(value)
    print("Fruit:", value)
end)

Advanced:AddColorPicker("Accent Color", {
    Flag = "AccentColor",
    Default = Color3.fromRGB(40, 226, 196)
}, function(color)
    Window:SetAccent(color)
end)

Advanced:AddButton("Test Notification", function()
    Window:Notify({ Title = "My UI", Info = "The button works.", Icon = "check", Duration = 3 })
end)

local Viewport = Advanced:AddViewport("MyViewport", {
    Object = Instance.new("Part"),
    Camera = Instance.new("Camera"),
    Interactive = true,
    AutoFocus = true,
    Height = 200
})

Window:LoadConfigManger()
Window:LoadSettingManger()
Window:LoadSerachManger()
