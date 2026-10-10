local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/BlockLib/refs/heads/main/Source.lua"))()

local Window = Library:CreateWindow({
	Title = "Block Hub",
	Logo = "box",
	ConfigFolder = "BlockHub",
	ToggleKey = "RightShift",
	ShowWaterMark = true,
})

local ExampleTab = Window:AddTab("Example", "layers", "General")

local Left = ExampleTab:AddLeftSection("Controls", "sliders-horizontal")

local MainToggle = Left:AddToggle("Toggle", {
	Flag = "Example/Toggle",
	Default = false,
	Callback = function(State)
		print("Toggle:", State)
	end,
})

MainToggle:AddSlider("Sub Slider", {
	Flag = "Example/SubSlider",
	Min = 0,
	Max = 100,
	Default = 50,
	Increment = 1,
})

Left:AddToggle("Toggle with Keybind", {
	Flag = "Example/ToggleKeybind",
	Default = false,
	Keybind = "X",
	Callback = function(State)
		print("Toggle Keybind:", State)
	end,
})

Left:AddToggle("Toggle with Color", {
	Flag = "Example/ToggleColor",
	Default = false,
	Color = Color3.fromRGB(255, 70, 70),
	Callback = function(State)
		print("Toggle Color:", State)
	end,
	ColorCallback = function(Color)
		print("Color:", Color)
	end,
})

Left:AddSlider("Slider", {
	Flag = "Example/Slider",
	Min = 0,
	Max = 100,
	Default = 25,
	Increment = 1,
	Callback = function(Value)
		print("Slider:", Value)
	end,
})

Left:AddDropdown("Dropdown", {
	Flag = "Example/Dropdown",
	Values = { "Option 1", "Option 2", "Option 3" },
	Default = "Option 1",
	Callback = function(Option)
		print("Dropdown:", Option)
	end,
})

Left:AddMultiDropdown("Multi Dropdown", {
	Flag = "Example/MultiDropdown",
	Values = { "Option 1", "Option 2", "Option 3", "Option 4" },
	Default = { "Option 1", "Option 3" },
	Callback = function(Selected)
		print("Multi Dropdown:", table.concat(Selected, ", "))
	end,
})

Left:AddSearchDropdown("Search Dropdown", {
	Flag = "Example/SearchDropdown",
	Values = {
		"Apple",
		"Banana",
		"Cherry",
		"Grape",
		"Lemon",
		"Mango",
		"Orange",
		"Peach",
		"Pear",
		"Strawberry",
	},
	Default = "Apple",
	Callback = function(Option)
		print("Search Dropdown:", Option)
	end,
})

local Right = ExampleTab:AddRightSection("Misc", "box")

local ExampleLabel = Right:AddLabel("This is a label.")

Right:AddInput("Input", {
	Flag = "Example/Input",
	Placeholder = "Type something...",
	Default = "",
	Callback = function(Text, EnterPressed)
		print("Input:", Text, EnterPressed)
	end,
})

Right:AddColorPicker("Color Picker", {
	Flag = "Example/ColorPicker",
	Default = Color3.fromRGB(22, 190, 165),
	Callback = function(Color)
		print("Color Picker:", Color)
	end,
})

Right:AddButton("Button", {
	Callback = function()
		ExampleLabel:SetText("Button clicked!")
	end,
})

Right:AddButton("Notify", {
	Callback = function()
		Library:Notify({
			Title = "Block Hub",
			Info = "This is an example notification.",
			Icon = "bell",
			Duration = 4,
		})
	end,
})

local Viewport = Right:AddViewport("Viewport", {
	Height = 220,
	Interactive = true,
	AutoFocus = true,
	Clone = true,
	Visible = true,
})

local ViewportSection = ExampleTab:AddLeftSection("Viewport Settings", "camera")

ViewportSection:AddToggle("Interactive", {
	Flag = "Example/ViewportInteractive",
	Default = true,
	Callback = function(State)
		Viewport:SetInteractive(State)
	end,
})

ViewportSection:AddToggle("Visible", {
	Flag = "Example/ViewportVisible",
	Default = true,
	Callback = function(State)
		Viewport:SetVisible(State)
	end,
})

ViewportSection:AddSlider("Height", {
	Flag = "Example/ViewportHeight",
	Min = 100,
	Max = 400,
	Default = 220,
	Increment = 10,
	Callback = function(Value)
		Viewport:SetHeight(Value)
	end,
})

ViewportSection:AddButton("Focus Camera", {
	Callback = function()
		Viewport:Focus()
	end,
})

ViewportSection:AddButton("Load Part", {
	Callback = function()
		local Part = Instance.new("Part")
		Part.Shape = Enum.PartType.Ball
		Part.Size = Vector3.new(4, 4, 4)
		Part.Color = Color3.fromRGB(22, 190, 165)
		Part.Material = Enum.Material.SmoothPlastic
		Viewport:SetObject(Part)
	end,
})

ViewportSection:AddButton("Load My Character", {
	Callback = function()
		local Character = game:GetService("Players").LocalPlayer.Character
		if Character then
			Viewport:SetObject(Character)
		end
	end,
})

Window:LoadSettingManger()
Window:LoadConfigManger()
Window:LoadSerachManger()
