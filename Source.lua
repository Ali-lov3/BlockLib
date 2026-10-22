local Players = game.GetService(game, "Players")
local UserInputService = game.GetService(game, "UserInputService")
local TweenService = game.GetService(game, "TweenService")
local RunService = game.GetService(game, "RunService")
local CoreGui = game.GetService(game, "CoreGui")
local TextService = game.GetService(game, "TextService")
local Stats = game.GetService(game, "Stats")
local HttpService = game.GetService(game, "HttpService")

local Library = { Flags = {} }
local Flags = Library.Flags
local ControlBinds = {}
local Index = {}
local Connections = {}
local AccentBindings = {}
local Tabs = {}
local Modals = {}
local WindowConfig = {}

local GuiName = "BlockUiLibrary"
local WatermarkKey = "Settings/Watermark"
local BaseWidth, BaseHeight = 960, 730
local SidebarWidth = 248
local OverlayTransparency = 0.4

local Gui, Main, Scale, Content, Sidebar, Items, ColorCatcher
local OpenDropdown, OpenColor, CloseColor, UpdateScale, Notify
local Current, TabOrder, LastCategory, SideSlots

local Lucide

pcall(function()
	Lucide = loadstring(game.HttpGet(game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local function IsAsset(Icon)
	if type(Icon) == "number" then return true end
	if type(Icon) == "string" then
		return string.match(Icon, "^rbxassetid://") ~= nil or string.match(Icon, "^%d+$") ~= nil
	end
	return false
end

local Theme = {
	WindowTop = Color3.fromRGB(40, 40, 41),
	WindowBottom = Color3.fromRGB(40, 40, 41),
	SidebarBg = Color3.fromRGB(32, 31, 32),
	CardTop = Color3.fromRGB(46, 47, 50),
	CardBottom = Color3.fromRGB(46, 47, 50),
	ElementTop = Color3.fromRGB(40, 42, 43),
	ElementBottom = Color3.fromRGB(37, 39, 40),
	Field = Color3.fromRGB(36, 38, 38),
	Line = Color3.fromRGB(58, 59, 64),
	LineLight = Color3.fromRGB(66, 67, 72),
	SelectedTop = Color3.fromRGB(46, 47, 49),
	SelectedBottom = Color3.fromRGB(46, 47, 49),
	Accent = Color3.fromRGB(74, 118, 168),
	AccentLight = Color3.fromRGB(86, 130, 182),
	AccentDark = Color3.fromRGB(66, 106, 154),
	Text = Color3.fromRGB(232, 232, 236),
	Sub = Color3.fromRGB(150, 151, 157),
	Muted = Color3.fromRGB(122, 123, 129),
}

local DefaultAccent = { Theme.Accent, Theme.AccentLight, Theme.AccentDark }

local function RegisterAccentGradient(Grad, Mode)
	AccentBindings[#AccentBindings + 1] = { Type = "Gradient", Object = Grad, Mode = Mode or 1 }
end

local function RegisterAccentColor(Obj, Prop, Mode)
	AccentBindings[#AccentBindings + 1] = { Type = "Color", Object = Obj, Property = Prop, Mode = Mode or "Accent" }
end

local function UpdateAccentTheme(NewColor)
	Theme.Accent = NewColor
	local H, S, V = Color3.toHSV(NewColor)
	Theme.AccentLight = Color3.fromHSV(H, math.max(S - 0.08, 0), math.min(V + 0.08, 1))
	Theme.AccentDark = Color3.fromHSV(H, math.min(S + 0.08, 1), math.max(V - 0.08, 0))

	for _, Item in ipairs(AccentBindings) do
		local Obj = Item.Object
		if Obj and Obj.Parent then
			if Item.Type == "Gradient" then
				if Item.Mode == 1 then
					Obj.Color = ColorSequence.new(Theme.AccentLight, Theme.AccentDark)
				elseif Item.Mode == 2 then
					Obj.Color = ColorSequence.new(Theme.AccentDark, Theme.AccentLight)
				end
			elseif Item.Type == "Color" then
				if Item.Mode == "Accent" then
					Obj[Item.Property] = Theme.Accent
				elseif Item.Mode == "Light" then
					Obj[Item.Property] = Theme.AccentLight
				elseif Item.Mode == "Dark" then
					Obj[Item.Property] = Theme.AccentDark
				end
			end
		end
	end
end

local function New(Class, Props)
	local Obj = Instance.new(Class)
	if Obj.IsA(Obj, "GuiObject") then Obj.BorderSizePixel = 0 end
	if Obj.IsA(Obj, "GuiButton") then Obj.AutoButtonColor = false end
	if Class == "TextLabel" or Class == "ImageLabel" then Obj.BackgroundTransparency = 1 end
	if Class == "TextLabel" or Class == "TextButton" or Class == "TextBox" then Obj.Text = "" end
	local Parent
	for Key, Value in pairs(Props or {}) do
		if Key == "Parent" then Parent = Value else Obj[Key] = Value end
	end
	if Parent then Obj.Parent = Parent end
	return Obj
end

local function Corner(Object, Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius), Parent = Object })
end

local function Stroke(Object, Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color,
		Thickness = Thickness or 1,
		Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Object,
	})
end

local function Gradient(Parent, From, To, Rotation, TransFrom, TransTo)
	return New("UIGradient", {
		Color = ColorSequence.new(From, To),
		Rotation = Rotation or 0,
		Transparency = NumberSequence.new(TransFrom or 0, TransTo or 0),
		Parent = Parent,
	})
end

local function Tween(Object, Props, Time, Style, Direction)
	local Created = TweenService.Create(
		TweenService,
		Object,
		TweenInfo.new(Time or 0.15, Style or Enum.EasingStyle.Quad, Direction or Enum.EasingDirection.Out),
		Props
	)
	Created.Play(Created)
	return Created
end

local function MakeIcon(Parent, Names, Size, Color)
	local Img = New("ImageLabel", {
		Size = UDim2.fromOffset(Size, Size),
		ImageColor3 = Color,
		ScaleType = Enum.ScaleType.Fit,
		Parent = Parent,
	})
	if type(Names) ~= "table" then Names = { Names } end
	for _, Name in ipairs(Names) do
		if ResolveIcon(Name) ~= "rbxassetid://0" then
			ApplyIcon(Img, Name)
			break
		end
	end
	return Img
end

local function MakeAccentIcon(Parent, Names, Size)
	local Img = MakeIcon(Parent, Names, Size, Color3.new(1, 1, 1))
	local First = type(Names) == "table" and Names[1] or Names
	if not IsAsset(First) then
		RegisterAccentGradient(Gradient(Img, Theme.AccentLight, Theme.AccentDark, 90), 1)
	end
	return Img
end

local function NextOrder(Parent)
	return #Parent.GetChildren(Parent)
end

local function SafeCall(Callback, ...)
	if not Callback then return end
	local Ok, Err = pcall(Callback, ...)
	if not Ok then warn("[BlockUi] Callback error: " .. tostring(Err)) end
end

local function Connect(Signal, Callback, Own)
	local Connection = Signal.Connect(Signal, Callback)
	Connections[#Connections + 1] = Connection
	if Own then Own[#Own + 1] = Connection end
	return Connection
end

local function IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function ColorToHex(Color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(Color.R * 255 + 0.5),
		math.floor(Color.G * 255 + 0.5),
		math.floor(Color.B * 255 + 0.5)
	)
end

local function BuildPicker()
	local PickerWidth, PickerHeight = 232, 232

	ColorCatcher = New("TextButton", {
		Name = "ColorCatcher",
		Size = UDim2.fromOffset(BaseWidth, BaseHeight),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 300,
		Parent = Main,
	})

	local ColorPopup = New("Frame", {
		Name = "ColorPopup",
		Size = UDim2.fromOffset(PickerWidth, PickerHeight),
		BackgroundColor3 = Color3.fromRGB(36, 37, 40),
		Active = true,
		ZIndex = 301,
		Parent = ColorCatcher,
	})
	Corner(ColorPopup, 12)
	Stroke(ColorPopup, Theme.LineLight, 1, 0.4)

	local SV = New("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(208, 140),
		BackgroundColor3 = Color3.fromHSV(0, 1, 1),
		Parent = ColorPopup,
	})
	Corner(SV, 6)
	local SVWhite = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = SV,
	})
	Corner(SVWhite, 6)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = SVWhite })
	local SVBlack = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Parent = SV,
	})
	Corner(SVBlack, 6)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = SVBlack })
	local SVCursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = SV,
	})
	Corner(SVCursor, 7)
	Stroke(SVCursor, Color3.new(1, 1, 1), 2, 0)
	local SVHit = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = SV,
	})

	local HueBar = New("Frame", {
		Position = UDim2.fromOffset(12, 164),
		Size = UDim2.fromOffset(208, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ColorPopup,
	})
	Corner(HueBar, 7)
	local HueKeys = {}
	for I = 0, 6 do
		HueKeys[#HueKeys + 1] = ColorSequenceKeypoint.new(I / 6, Color3.fromHSV((I % 6) / 6, 1, 1))
	end
	New("UIGradient", { Color = ColorSequence.new(HueKeys), Parent = HueBar })
	local HueKnob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = HueBar,
	})
	Corner(HueKnob, 8)
	Stroke(HueKnob, Color3.new(1, 1, 1), 2, 0)
	local HueHit = New("TextButton", {
		Position = UDim2.fromOffset(-4, -8),
		Size = UDim2.new(1, 8, 1, 16),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = HueBar,
	})

	local PreviewSwatch = New("Frame", {
		Position = UDim2.fromOffset(12, 192),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ColorPopup,
	})
	Corner(PreviewSwatch, 7)
	Stroke(PreviewSwatch, Theme.LineLight, 1, 0.5)
	local HexFrame = New("Frame", {
		Position = UDim2.fromOffset(48, 192),
		Size = UDim2.fromOffset(172, 28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ColorPopup,
	})
	Corner(HexFrame, 7)
	Gradient(HexFrame, Theme.ElementTop, Theme.ElementBottom, 90)
	Stroke(HexFrame, Theme.Line, 1, 0.3)
	local HexBox = New("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Theme.Sub,
		PlaceholderText = "#RRGGBB",
		PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false,
		Parent = HexFrame,
	})

	local Picker = { H = 0, S = 0, V = 1, Apply = nil }
	local PickerDrag = nil

	local function PickerRefresh()
		local Color = Color3.fromHSV(Picker.H, Picker.S, Picker.V)
		SV.BackgroundColor3 = Color3.fromHSV(Picker.H, 1, 1)
		SVCursor.Position = UDim2.fromScale(Picker.S, 1 - Picker.V)
		HueKnob.Position = UDim2.fromScale(Picker.H, 0.5)
		HueKnob.BackgroundColor3 = Color3.fromHSV(Picker.H, 1, 1)
		PreviewSwatch.BackgroundColor3 = Color
		HexBox.Text = ColorToHex(Color)
		return Color
	end

	local function PickerChanged()
		local Color = PickerRefresh()
		if Picker.Apply then Picker.Apply(Color) end
	end

	local function SVFromInput(Pos)
		Picker.S = math.clamp((Pos.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
		Picker.V = 1 - math.clamp((Pos.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
		PickerChanged()
	end

	local function HueFromInput(Pos)
		Picker.H = math.clamp((Pos.X - HueBar.AbsolutePosition.X) / math.max(HueBar.AbsoluteSize.X, 1), 0, 1)
		PickerChanged()
	end

	SVHit.InputBegan.Connect(SVHit.InputBegan, function(Input)
		if IsPress(Input) then
			PickerDrag = "sv"
			SVFromInput(Input.Position)
		end
	end)
	HueHit.InputBegan.Connect(HueHit.InputBegan, function(Input)
		if IsPress(Input) then
			PickerDrag = "hue"
			HueFromInput(Input.Position)
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if PickerDrag and IsMove(Input) then
			if PickerDrag == "sv" then
				SVFromInput(Input.Position)
			else
				HueFromInput(Input.Position)
			end
		end
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if PickerDrag and IsPress(Input) then
			PickerDrag = nil
		end
	end)

	HexBox.FocusLost.Connect(HexBox.FocusLost, function()
		local R, G, B = string.match(HexBox.Text, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
		if R then
			local Color = Color3.fromRGB(tonumber(R, 16), tonumber(G, 16), tonumber(B, 16))
			local H, S, V = Color3.toHSV(Color)
			if S > 0 then Picker.H = H end
			Picker.S, Picker.V = S, V
			PickerChanged()
		else
			PickerRefresh()
		end
	end)

	CloseColor = function()
		ColorCatcher.Visible = false
		Picker.Apply = nil
		PickerDrag = nil
		pcall(function() HexBox.ReleaseFocus(HexBox) end)
	end

	OpenColor = function(Anchor, CurrentColor, Apply)
		if OpenDropdown then OpenDropdown() end
		local H, S, V = Color3.toHSV(CurrentColor)
		Picker.H, Picker.S, Picker.V = H, S, V
		Picker.Apply = Apply

		local S2 = Scale.Scale
		local Rel = (Anchor.AbsolutePosition - Main.AbsolutePosition) / S2
		local AnchorW = Anchor.AbsoluteSize.X / S2
		local AnchorH = Anchor.AbsoluteSize.Y / S2
		local X = math.clamp(Rel.X + AnchorW - PickerWidth, 8, BaseWidth - PickerWidth - 8)
		local Y = Rel.Y + AnchorH + 8
		if Y + PickerHeight > BaseHeight - 8 then
			Y = Rel.Y - PickerHeight - 8
		end
		ColorPopup.Position = UDim2.fromOffset(X, math.max(Y, 8))
		PickerRefresh()
		ColorCatcher.Visible = true
	end

	ColorCatcher.Activated.Connect(ColorCatcher.Activated, CloseColor)
end

local function MakeColorSwatch(Parent, Key, Default, RightOffset, OnChange)
	Default = Default or Color3.new(1, 1, 1)
	local Swatch = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, RightOffset, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Default,
		ZIndex = 2,
		Parent = Parent,
	})
	Corner(Swatch, 5)
	Stroke(Swatch, Theme.LineLight, 1, 0.6)
	Flags[Key] = Default
	local function Set(Color, Silent)
		Swatch.BackgroundColor3 = Color
		Flags[Key] = Color
		if not Silent then SafeCall(OnChange, Color) end
	end
	ControlBinds[Key] = Set
	Swatch.Activated.Connect(Swatch.Activated, function()
		OpenColor(Swatch, Flags[Key], Set)
	end)
	return Swatch, Set
end

local function NewSection(Column, Title, Icon, Order)
	local Holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = Order,
		Parent = Column,
	})
	Holder.SetAttribute(Holder, "SectionHolder", true)
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Holder })
	local Head = New("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = Holder,
	})
	local HeadIcon = MakeIcon(Head, Icon, 20, Theme.Muted)
	HeadIcon.Position = UDim2.fromOffset(4, 4)
	New("TextLabel", {
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Text = Title,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Head,
	})
	local Card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 2,
		Parent = Holder,
	})
	Corner(Card, 8)
	Gradient(Card, Theme.CardTop, Theme.CardBottom, 90)
	local CardStroke = Stroke(Card, Color3.new(1, 1, 1), 1, 0)
	Gradient(CardStroke, Theme.Line, Theme.Line, 90, 0.1, 0.1)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Card })
	New("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), Parent = Card })
	return Card, Holder
end

local function AddGroup(Card, Order)
	local Wrap = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = Order or NextOrder(Card),
		Parent = Card,
	})
	local Inner = New("Frame", {
		Position = UDim2.fromOffset(0, -12),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Wrap,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Inner })

	local Group = { Inner = Inner, Wrap = Wrap }
	local Open = false
	local Shown = false
	local Token = 0

	local function Apply(Instant)
		Token += 1
		local My = Token
		if Open then
			Wrap.Visible = true
			Wrap.ClipsDescendants = true
			local H = math.ceil(Inner.AbsoluteSize.Y / math.max(Scale.Scale, 0.01))
			if not Shown then Inner.Position = UDim2.fromOffset(0, -12) end
			Shown = true
			Tween(Inner, { Position = UDim2.fromOffset(0, 0) }, 0.34, Enum.EasingStyle.Quint)
			local T = Tween(Wrap, { Size = UDim2.new(1, 0, 0, H) }, 0.34, Enum.EasingStyle.Quint)
			T.Completed.Connect(T.Completed, function()
				if My == Token and Open then Wrap.ClipsDescendants = false end
			end)
		else
			Shown = false
			if Instant then
				Wrap.Size = UDim2.new(1, 0, 0, 0)
				Wrap.Visible = false
				Inner.Position = UDim2.fromOffset(0, -12)
				return
			end
			Wrap.ClipsDescendants = true
			Tween(Inner, { Position = UDim2.fromOffset(0, -12) }, 0.22, Enum.EasingStyle.Quint)
			local T = Tween(Wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.26, Enum.EasingStyle.Quint)
			T.Completed.Connect(T.Completed, function()
				if My == Token and not Open then Wrap.Visible = false end
			end)
		end
	end

	Inner.GetPropertyChangedSignal(Inner, "AbsoluteSize").Connect(Inner.GetPropertyChangedSignal(Inner, "AbsoluteSize"), function()
		if Open then Apply(false) end
	end)

	function Group.Set(Value, Instant)
		Value = Value and true or false
		if Value == Open and Shown == Open then return end
		Open = Value
		Apply(Instant)
	end

	return Group
end

local function NewField(Card, Name)
	local Block = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Block })
	New("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 17),
		Parent = Block,
	})
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		Text = Name,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = Block,
	})
	local BoxFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 2,
		Parent = Block,
	})
	Corner(BoxFrame, 7)
	Gradient(BoxFrame, Theme.Field, Theme.Field, 90)
	local BoxStroke = Stroke(BoxFrame, Theme.Line, 1, 0.3)
	return Block, BoxFrame, BoxStroke
end

local function NewDropdownShell(Card, Name)
	local Block, BoxFrame = NewField(Card, Name)
	local Value = New("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = BoxFrame,
	})
	local Chevron = MakeIcon(BoxFrame, { "layout-panel-left", "panel-left", "layout-dashboard", "layout-template" }, 20, Theme.Muted)
	Chevron.AnchorPoint = Vector2.new(1, 0.5)
	Chevron.Position = UDim2.new(1, -10, 0.5, 0)
	local Box = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = BoxFrame,
	})
	local List = New("Frame", {
		Position = UDim2.new(0, 0, 1, 12),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(29, 30, 32),
		Visible = false,
		ZIndex = 20,
		Parent = BoxFrame,
	})
	Corner(List, 8)
	Stroke(List, Theme.Line, 1, 0.2)
	local Layout = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = List })
	New("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = List,
	})

	local function SetChainZ(Z)
		local Obj = Block
		while Obj and Obj ~= Gui do
			if Obj.IsA(Obj, "GuiObject") then Obj.ZIndex = Z end
			if Obj.GetAttribute(Obj, "SectionHolder") then break end
			Obj = Obj.Parent
		end
	end

	return { Block = Block, Value = Value, Box = Box, List = List, Layout = Layout, SetChainZ = SetChainZ }
end

local Container = {}
Container.__index = Container

local ElementMeta = {}
ElementMeta.__index = ElementMeta

local ToggleMeta = setmetatable({}, {
	__index = function(_, Name)
		local Value = ElementMeta[Name]
		if Value ~= nil then return Value end
		return Container[Name]
	end,
})
ToggleMeta.__index = ToggleMeta

function ElementMeta:Get()
	return Flags[self.Flag]
end

function ElementMeta:Set(Value)
	if self.Setter then self.Setter(Value) end
end

function ElementMeta:SetVisible(Visible)
	self.Frame.Visible = Visible and true or false
end

function ElementMeta:Destroy()
	for _, Connection in ipairs(self.Own) do
		pcall(function() Connection.Disconnect(Connection) end)
	end
	for Position, Entry in ipairs(Index) do
		if Entry == self.Entry then
			table.remove(Index, Position)
			break
		end
	end
	if self.Flag then
		Flags[self.Flag] = nil
		ControlBinds[self.Flag] = nil
	end
	if self.Extra and self.Extra.Parent then self.Extra.Destroy(self.Extra) end
	if self.Frame.Parent then self.Frame.Destroy(self.Frame) end
end

local function NewContainer(Card, Page, Path, Holder, NoIndex)
	return setmetatable({ Card = Card, Page = Page, Path = Path, Holder = Holder, NoIndex = NoIndex }, Container)
end

local function CardOf(Self)
	if not Self.Card and Self.MakeGroup then
		Self.Card = Self.MakeGroup()
	end
	return Self.Card
end

local function KeyOf(Self, Name, Info)
	return Info.Flag or ((Self.Path or "Window") .. "/" .. tostring(Name))
end

local function Register(Self, Frame, Kind, Name, Key, Setter, Own, Meta)
	local Entry
	if not Self.NoIndex then
		Entry = { Name = tostring(Name), Kind = Kind, Page = Self.Page, Target = Self.Anchor or Frame, Via = Self.Via, Rank = 1 }
		Index[#Index + 1] = Entry
	end
	return setmetatable({ Frame = Frame, Flag = Key, Entry = Entry, Own = Own or {}, Setter = Setter }, Meta or ElementMeta)
end

function Container:SetVisible(Visible)
	if self.Holder then self.Holder.Visible = Visible and true or false end
end

function Container:AddToggle(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Own = {}
	local Row = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	local Label = New("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -120, 1, 0),
		Text = Name,
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Row,
	})
	local Switch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -17, 0.5, 0),
		Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Row,
	})
	Corner(Switch, 11)
	Gradient(Switch, Theme.Field, Theme.Field, 90)
	local OnLayer = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Parent = Switch,
	})
	Corner(OnLayer, 11)
	local OnGrad = Gradient(OnLayer, Theme.AccentDark, Theme.AccentLight, 0)
	RegisterAccentGradient(OnGrad, 2)

	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = Switch,
	})
	Corner(Knob, 8)

	local State = false
	local Group
	local Element

	local function Apply(Value)
		State = Value and true or false
		Flags[Key] = State
		Tween(OnLayer, { BackgroundTransparency = State and 0 or 1 })
		Tween(Knob, {
			Position = State and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = State and Color3.new(1, 1, 1) or Color3.fromRGB(118, 119, 125),
		})
		Tween(Label, { TextColor3 = State and Theme.Text or Theme.Muted })
		if Group then Group.Set(State) end
	end

	local function Set(Value, Silent)
		Apply(Value)
		if not Silent then SafeCall(Info.Callback, State) end
	end

	ControlBinds[Key] = Set
	Row.Activated.Connect(Row.Activated, function()
		Set(not State)
	end)

	local Used = 17 + 44

	if Info.Color then
		Used += 12
		MakeColorSwatch(Row, Key .. "/Color", Info.Color, -Used, Info.ColorCallback)
		Used += 20
	end

	if Info.Keybind then
		Used += 8
		local Found, Code = pcall(function() return Enum.KeyCode[Info.Keybind] end)
		local BindKey = Found and Code or nil
		local Listening = false
		local BoxFrame = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -Used, 0.5, 0),
			Size = UDim2.fromOffset(30, 22),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Row,
		})
		Used += 30
		Corner(BoxFrame, 5)
		Gradient(BoxFrame, Theme.ElementTop, Theme.ElementBottom, 90)
		Stroke(BoxFrame, Theme.Line, 1, 0.4)
		local Box = New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = BindKey and BindKey.Name or "-",
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Theme.Sub,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = BoxFrame,
		})
		Box.Activated.Connect(Box.Activated, function()
			Listening = true
			Box.Text = "..."
		end)
		Connect(UserInputService.InputBegan, function(Input, Processed)
			if Listening then
				if Input.UserInputType == Enum.UserInputType.Keyboard then
					Listening = false
					if Input.KeyCode == Enum.KeyCode.Escape then
						BindKey = nil
						Box.Text = "-"
					else
						BindKey = Input.KeyCode
						Box.Text = Input.KeyCode.Name
					end
				end
			elseif not Processed and BindKey and Input.KeyCode == BindKey then
				Set(not State)
			end
		end, Own)
	end

	Label.Size = UDim2.new(1, -(18 + Used + 8), 1, 0)

	Apply(Info.Default)

	Element = Register(self, Row, "Toggle", Name, Key, Set, Own, ToggleMeta)
	Element.Page = self.Page
	Element.Path = Key
	Element.Anchor = self.Anchor or Row
	Element.Via = self.Anchor and self.Via or Name
	Element.NoIndex = self.NoIndex
	Element.MakeGroup = function()
		Group = AddGroup(Card, Row.LayoutOrder)
		Group.Set(State, true)
		Element.Extra = Group.Wrap
		return Group.Inner
	end
	return Element
end

function Container:AddSlider(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Own = {}
	local Min, Max = Info.Min or 0, Info.Max or 100
	if Max <= Min then Max = Min + 1 end
	local Inc = Info.Increment or Info.Rounding or 1
	if Inc <= 0 then Inc = 1 end

	local Block = New("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(18, 4),
		Size = UDim2.new(0.6, 0, 0, 24),
		Text = Name,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Block,
	})
	local ValueBox = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -17, 0, 5),
		Size = UDim2.fromOffset(52, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Block,
	})
	Corner(ValueBox, 6)
	Gradient(ValueBox, Theme.ElementTop, Theme.ElementBottom, 90)
	local ValueStroke = Stroke(ValueBox, Theme.Accent, 1, 1)
	local ValueText = New("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Theme.Sub,
		ClearTextOnFocus = false,
		Parent = ValueBox,
	})
	local Track = New("Frame", {
		Position = UDim2.fromOffset(18, 31),
		Size = UDim2.new(1, -35, 0, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Block,
	})
	Corner(Track, 4)
	Gradient(Track, Theme.Field, Theme.Field, 90)
	local Fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Track,
	})
	Corner(Fill, 4)
	local FillGrad = Gradient(Fill, Theme.AccentDark, Theme.AccentLight, 0)
	RegisterAccentGradient(FillGrad, 2)

	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = Track,
	})
	Corner(Knob, 7)
	Gradient(Knob, Color3.fromRGB(232, 232, 244), Color3.fromRGB(216, 217, 236), 90)
	Stroke(Knob, Theme.Field, 2)
	local Hit = New("TextButton", {
		Position = UDim2.fromOffset(18, 20),
		Size = UDim2.new(1, -35, 0, 30),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = Block,
	})

	local function SetValue(Value, Silent)
		Value = tonumber(Value) or Min
		Value = math.clamp(math.floor((Value - Min) / Inc + 0.5) * Inc + Min, Min, Max)
		Value = tonumber(string.format("%.4f", Value))
		if Value == 0 then Value = 0 end
		local Fraction = (Value - Min) / (Max - Min)
		Fill.Size = UDim2.fromScale(Fraction, 1)
		Knob.Position = UDim2.new(Fraction, 0, 0.5, 0)
		ValueText.Text = tostring(Value)
		Flags[Key] = Value
		if not Silent then SafeCall(Info.Callback, Value) end
	end

	ControlBinds[Key] = SetValue

	ValueText.Focused.Connect(ValueText.Focused, function()
		Tween(ValueStroke, { Transparency = 0 }, 0.2)
		Tween(ValueText, { TextColor3 = Theme.Text }, 0.2)
	end)
	ValueText.FocusLost.Connect(ValueText.FocusLost, function()
		Tween(ValueStroke, { Transparency = 1 }, 0.2)
		Tween(ValueText, { TextColor3 = Theme.Sub }, 0.2)
		local Typed = tonumber(ValueText.Text)
		if Typed then
			SetValue(Typed)
		else
			SetValue(Flags[Key], true)
		end
	end)

	local Dragging = false
	local Scroller = Card.FindFirstAncestorOfClass(Card, "ScrollingFrame")

	local function FromX(X)
		local Fraction = math.clamp((X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		SetValue(Min + (Max - Min) * Fraction)
	end

	Hit.InputBegan.Connect(Hit.InputBegan, function(Input)
		if IsPress(Input) then
			Dragging = true
			if Scroller then Scroller.ScrollingEnabled = false end
			FromX(Input.Position.X)
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if Dragging and IsMove(Input) then
			FromX(Input.Position.X)
		end
	end, Own)
	Connect(UserInputService.InputEnded, function(Input)
		if Dragging and IsPress(Input) then
			Dragging = false
			if Scroller then Scroller.ScrollingEnabled = true end
		end
	end, Own)

	SetValue(Info.Default or Min, true)
	return Register(self, Block, "Slider", Name, Key, SetValue, Own)
end

function Container:AddDropdown(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Values = Info.Values or Info.Options or {}
	local Shell = NewDropdownShell(Card, Name)
	local List, Value, Box = Shell.List, Shell.Value, Shell.Box
	local Buttons = {}
	local Marks = {}
	local RowHeight, MaxHeight = 36, 180
	local Scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, math.min(math.max(#Values, 1) * RowHeight, MaxHeight)),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = List,
	})
	RegisterAccentColor(Scroll, "ScrollBarImageColor3", "Accent")
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })
	New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = Scroll })

	local function Close()
		List.Visible = false
		Shell.SetChainZ(1)
		if OpenDropdown == Close then OpenDropdown = nil end
	end

	local function Set(Option, Silent)
		if not Buttons[Option] then Option = Values[1] end
		if Option == nil then return end
		Value.Text = tostring(Option)
		Flags[Key] = Option
		for Name2, Button in pairs(Buttons) do
			local Picked = Name2 == Option
			Tween(Button, { TextColor3 = Picked and Theme.Text or Theme.Muted, BackgroundTransparency = Picked and 0 or 1 })
			Tween(Marks[Name2], { BackgroundTransparency = Picked and 0 or 1 })
		end
		Close()
		if not Silent then SafeCall(Info.Callback, Option) end
	end

	ControlBinds[Key] = Set

	for OptIndex, Option in ipairs(Values) do
		local Button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, RowHeight),
			BackgroundTransparency = 1,
			Text = tostring(Option),
			Font = Enum.Font.GothamMedium,
			TextSize = 17,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = OptIndex,
			Parent = Scroll,
		})
		New("UIPadding", { PaddingLeft = UDim.new(0, 18), Parent = Button })
		Button.BackgroundColor3 = Color3.fromRGB(46, 48, 52)
		Corner(Button, 6)
		local Mark = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -14, 0.5, 0),
			Size = UDim2.fromOffset(3, 16),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Parent = Button,
		})
		Corner(Mark, 2)
		RegisterAccentColor(Mark, "BackgroundColor3", "Accent")
		Marks[Option] = Mark
		Buttons[Option] = Button
		Button.Activated.Connect(Button.Activated, function()
			Set(Option)
		end)
	end
	Box.Activated.Connect(Box.Activated, function()
		if List.Visible then
			Close()
			return
		end
		if OpenDropdown then OpenDropdown() end
		Shell.SetChainZ(20)
		Scroll.CanvasPosition = Vector2.new(0, 0)
		List.Visible = true
		OpenDropdown = Close
	end)
	Set(Info.Default, true)
	return Register(self, Shell.Block, "Dropdown", Name, Key, Set)
end

function Container:AddMultiDropdown(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Values = Info.Values or Info.Options or {}
	local Shell = NewDropdownShell(Card, Name)
	local List, Value, Box = Shell.List, Shell.Value, Shell.Box
	Shell.Layout.Padding = UDim.new(0, 4)
	local Buttons = {}
	local RowHeight, MaxHeight = 34, 180

	local Actions = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = List,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Actions,
	})

	local Scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, math.min(math.max(#Values, 1) * RowHeight, MaxHeight)),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		LayoutOrder = 2,
		Parent = List,
	})
	RegisterAccentColor(Scroll, "ScrollBarImageColor3", "Accent")
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })
	New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = Scroll })
	local Chosen = {}

	local function Close()
		List.Visible = false
		Shell.SetChainZ(1)
		if OpenDropdown == Close then OpenDropdown = nil end
	end

	local function Apply(Silent)
		local Picked = {}
		for _, Option in ipairs(Values) do
			local On = Chosen[Option] == true
			if On then Picked[#Picked + 1] = Option end
			local Entry = Buttons[Option]
			Tween(Entry.Label, { TextColor3 = On and Theme.Text or Theme.Muted })
			Tween(Entry.Check, { ImageTransparency = On and 0 or 1 })
		end
		Flags[Key] = Picked
		Value.Text = #Picked > 0 and table.concat(Picked, ", ") or "None"
		Value.TextColor3 = #Picked > 0 and Theme.Sub or Theme.Muted
		if not Silent then SafeCall(Info.Callback, Picked) end
	end

	local function Set(Selected, Silent)
		Chosen = {}
		if type(Selected) == "table" then
			for _, Option in ipairs(Selected) do
				Chosen[Option] = true
			end
		end
		Apply(Silent)
	end

	ControlBinds[Key] = Set

	local function MakeAction(Text, Order, Handler)
		local Holder = New("Frame", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			LayoutOrder = Order,
			Parent = Actions,
		})
		Corner(Holder, 6)
		Gradient(Holder, Theme.ElementTop, Theme.ElementBottom, 90)
		Stroke(Holder, Theme.Line, 1, 0.3)
		local Button = New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Theme.Sub,
			Parent = Holder,
		})
		Button.MouseEnter.Connect(Button.MouseEnter, function()
			Tween(Button, { TextColor3 = Theme.Text })
		end)
		Button.MouseLeave.Connect(Button.MouseLeave, function()
			Tween(Button, { TextColor3 = Theme.Sub })
		end)
		Button.Activated.Connect(Button.Activated, Handler)
	end

	MakeAction("Select all", 1, function()
		for _, Option in ipairs(Values) do
			Chosen[Option] = true
		end
		Apply()
	end)

	MakeAction("Deselect all", 2, function()
		Chosen = {}
		Apply()
	end)

	for OptIndex, Option in ipairs(Values) do
		local Button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, RowHeight),
			BackgroundTransparency = 1,
			LayoutOrder = OptIndex,
			Parent = Scroll,
		})
		local OptionLabel = New("TextLabel", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Text = tostring(Option),
			Font = Enum.Font.GothamMedium,
			TextSize = 17,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Button,
		})
		local Check = MakeIcon(Button, { "check" }, 18, Theme.Accent)
		Check.AnchorPoint = Vector2.new(1, 0.5)
		Check.Position = UDim2.new(1, -10, 0.5, 0)
		Check.ImageTransparency = 1
		RegisterAccentColor(Check, "ImageColor3", "Accent")
		Buttons[Option] = { Label = OptionLabel, Check = Check }
		Button.Activated.Connect(Button.Activated, function()
			Chosen[Option] = not Chosen[Option]
			Apply()
		end)
	end

	Box.Activated.Connect(Box.Activated, function()
		if List.Visible then
			Close()
			return
		end
		if OpenDropdown then OpenDropdown() end
		Shell.SetChainZ(20)
		Scroll.CanvasPosition = Vector2.new(0, 0)
		List.Visible = true
		OpenDropdown = Close
	end)

	Set(Info.Default, true)
	return Register(self, Shell.Block, "MultiDropdown", Name, Key, Set)
end

function Container:AddSearchDropdown(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Values = Info.Values or Info.Options or {}
	local Shell = NewDropdownShell(Card, Name)
	local List, Value, Box = Shell.List, Shell.Value, Shell.Box
	Shell.Layout.Padding = UDim.new(0, 6)

	local RowHeight, MaxHeight = 34, 170

	local SearchFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 1,
		Parent = List,
	})
	Corner(SearchFrame, 6)
	Gradient(SearchFrame, Theme.ElementTop, Theme.ElementBottom, 90)
	local SearchStroke = Stroke(SearchFrame, Theme.Line, 1, 0.3)
	local SearchIcon = MakeIcon(SearchFrame, { "search" }, 16, Theme.Muted)
	SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
	SearchIcon.Position = UDim2.new(0, 10, 0.5, 0)
	local SearchBox = New("TextBox", {
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Theme.Text,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = SearchFrame,
	})

	local Scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		LayoutOrder = 2,
		Parent = List,
	})
	RegisterAccentColor(Scroll, "ScrollBarImageColor3", "Accent")
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })
	New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = Scroll })

	local Empty = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, RowHeight),
		Text = "No results found",
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Theme.Muted,
		Visible = false,
		LayoutOrder = #Values + 1,
		Parent = Scroll,
	})

	local Buttons = {}
	local Marks = {}

	local function Filter()
		local Query = string.lower(string.match(SearchBox.Text, "^%s*(.-)%s*$"))
		local Count = 0
		for Option, Button in pairs(Buttons) do
			local Show = Query == "" or string.find(string.lower(tostring(Option)), Query, 1, true) ~= nil
			Button.Visible = Show
			if Show then Count += 1 end
		end
		Empty.Visible = Count == 0
		Scroll.Size = UDim2.new(1, 0, 0, math.min(math.max(Count, 1) * RowHeight, MaxHeight))
		Scroll.CanvasPosition = Vector2.new(0, 0)
	end

	local function Close()
		List.Visible = false
		Shell.SetChainZ(1)
		pcall(function() SearchBox.ReleaseFocus(SearchBox) end)
		if OpenDropdown == Close then OpenDropdown = nil end
	end

	local function Set(Option, Silent)
		if not Buttons[Option] then
			Option = Values[1]
		end
		if Option == nil then return end
		Value.Text = tostring(Option)
		Flags[Key] = Option
		for Name2, Button in pairs(Buttons) do
			local Picked = Name2 == Option
			Tween(Button, { TextColor3 = Picked and Theme.Text or Theme.Muted, BackgroundTransparency = Picked and 0 or 1 })
			Tween(Marks[Name2], { BackgroundTransparency = Picked and 0 or 1 })
		end
		Close()
		if not Silent then SafeCall(Info.Callback, Option) end
	end

	ControlBinds[Key] = Set

	for OptIndex, Option in ipairs(Values) do
		local Button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, RowHeight),
			BackgroundTransparency = 1,
			Text = tostring(Option),
			Font = Enum.Font.GothamMedium,
			TextSize = 17,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = OptIndex,
			Parent = Scroll,
		})
		New("UIPadding", { PaddingLeft = UDim.new(0, 18), Parent = Button })
		Button.BackgroundColor3 = Color3.fromRGB(46, 48, 52)
		Corner(Button, 6)
		local Mark = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -14, 0.5, 0),
			Size = UDim2.fromOffset(3, 16),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Parent = Button,
		})
		Corner(Mark, 2)
		RegisterAccentColor(Mark, "BackgroundColor3", "Accent")
		Marks[Option] = Mark
		Buttons[Option] = Button
		Button.Activated.Connect(Button.Activated, function()
			Set(Option)
		end)
	end

	SearchBox.GetPropertyChangedSignal(SearchBox, "Text").Connect(SearchBox.GetPropertyChangedSignal(SearchBox, "Text"), Filter)

	SearchBox.Focused.Connect(SearchBox.Focused, function()
		Tween(SearchStroke, { Color = Theme.Accent, Transparency = 0 }, 0.25)
		Tween(SearchIcon, { ImageColor3 = Theme.Accent }, 0.25)
	end)
	SearchBox.FocusLost.Connect(SearchBox.FocusLost, function(EnterPressed)
		Tween(SearchStroke, { Color = Theme.Line, Transparency = 0.3 }, 0.25)
		Tween(SearchIcon, { ImageColor3 = Theme.Muted }, 0.25)
		if EnterPressed and List.Visible then
			for _, Option in ipairs(Values) do
				if Buttons[Option].Visible then
					Set(Option)
					break
				end
			end
		end
	end)

	Box.Activated.Connect(Box.Activated, function()
		if List.Visible then
			Close()
			return
		end
		if OpenDropdown then OpenDropdown() end
		Shell.SetChainZ(20)
		SearchBox.Text = ""
		Filter()
		List.Visible = true
		OpenDropdown = Close
		if not UserInputService.TouchEnabled then
			task.defer(function()
				pcall(function() SearchBox.CaptureFocus(SearchBox) end)
			end)
		end
	end)

	Filter()
	Set(Info.Default, true)
	return Register(self, Shell.Block, "SearchDropdown", Name, Key, Set)
end

function Container:AddLabel(Text, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 17),
		Parent = Row,
	})
	local Label = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(Text),
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = Row,
	})
	local Element
	local function SetText(NewText)
		Label.Text = tostring(NewText)
		if Element and Element.Entry then Element.Entry.Name = tostring(NewText) end
	end
	Element = Register(self, Row, "Label", Text, nil, SetText)
	Element.SetText = function(_, NewText)
		SetText(NewText)
	end
	return Element
end

function Container:AddInput(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Block, BoxFrame, BoxStroke = NewField(Card, Name)
	local Input = New("TextBox", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Theme.Text,
		PlaceholderText = Info.Placeholder or "",
		PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = BoxFrame,
	})

	local function Set(Text, Silent)
		Text = tostring(Text or "")
		Input.Text = Text
		Flags[Key] = Text
		if not Silent then SafeCall(Info.Callback, Text, false) end
	end

	ControlBinds[Key] = Set

	Input.GetPropertyChangedSignal(Input, "Text").Connect(Input.GetPropertyChangedSignal(Input, "Text"), function()
		Flags[Key] = Input.Text
	end)
	Input.Focused.Connect(Input.Focused, function()
		Tween(BoxStroke, { Color = Theme.Accent, Transparency = 0 }, 0.25)
	end)
	Input.FocusLost.Connect(Input.FocusLost, function(EnterPressed)
		Tween(BoxStroke, { Color = Theme.Line, Transparency = 0.3 }, 0.25)
		Flags[Key] = Input.Text
		SafeCall(Info.Callback, Input.Text, EnterPressed)
	end)

	Set(Info.Default, true)
	return Register(self, Block, "Input", Name, Key, Set)
end

function Container:AddColorPicker(Name, Info)
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Text = Name,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})
	local _, Set = MakeColorSwatch(Row, Key, Info.Default, -17, Info.Callback)
	return Register(self, Row, "Color", Name, Key, Set)
end

function Container:AddButton(Name, Info)
	if type(Info) == "function" then Info = { Callback = Info } end
	Info = Info or {}
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	local Frame = New("Frame", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 40),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Row,
	})
	Corner(Frame, 8)
	Gradient(Frame, Theme.ElementTop, Theme.ElementBottom, 90)
	local Line = Stroke(Frame, Theme.Line, 1, 0.3)
	local Button = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = Name,
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Theme.Text,
		Parent = Frame,
	})
	Button.MouseEnter.Connect(Button.MouseEnter, function()
		Tween(Line, { Transparency = 0 })
	end)
	Button.MouseLeave.Connect(Button.MouseLeave, function()
		Tween(Line, { Transparency = 0.3 })
	end)
	Button.Activated.Connect(Button.Activated, function()
		Line.Color = Theme.Accent
		Tween(Line, { Color = Theme.Line }, 0.35)
		if Info.Callback then
			task.spawn(function()
				local Ok, Err = pcall(Info.Callback)
				if not Ok then warn("[BlockUi] Button error: " .. tostring(Err)) end
			end)
		end
	end)
	local Element = Register(self, Row, "Button", Name, Key, function()
		if Info.Callback then SafeCall(Info.Callback) end
	end)
	Element.SetText = function(_, NewText)
		Button.Text = tostring(NewText)
		if Element.Entry then Element.Entry.Name = tostring(NewText) end
	end
	return Element
end

local function ObjectBounds(Object)
	if Object.IsA(Object, "Model") then return Object.GetBoundingBox(Object) end
	if Object.IsA(Object, "BasePart") then return Object.CFrame, Object.Size end
	return CFrame.new(), Vector3.new(4, 4, 4)
end

function Container:AddViewport(Name, Info)
	if type(Name) == "table" then Info, Name = Name, "Viewport" end
	Info = Info or {}
	Name = tostring(Name or "Viewport")
	local Card = CardOf(self)
	local Key = KeyOf(self, Name, Info)
	local Own = {}
	local Height = Info.Height or 200

	local Block = New("Frame", {
		Size = UDim2.new(1, 0, 0, Height + 20),
		BackgroundTransparency = 1,
		Visible = Info.Visible ~= false,
		LayoutOrder = NextOrder(Card),
		Parent = Card,
	})
	local Holder = New("Frame", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, Height),
		BackgroundColor3 = Color3.fromRGB(29, 30, 32),
		Parent = Block,
	})
	Corner(Holder, 8)
	Stroke(Holder, Theme.Line, 1, 0.3)

	local View = New("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(175, 175, 185),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.35, -0.6, 1),
		Parent = Holder,
	})
	Corner(View, 8)

	local Status = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "Loading...",
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Muted,
		Parent = Holder,
	})

	local Hit = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = Info.Interactive == true,
		ZIndex = 3,
		Parent = Holder,
	})

	local Interactive = Info.Interactive == true
	local AutoFocus = Info.AutoFocus ~= false
	local Camera, Model
	local OwnCamera = false
	local Yaw, Pitch, Distance = math.pi, 0.15, 10
	local Target = Vector3.new()
	local Radius, Fit = 2, 10
	local Oriented = false
	local Dragging, LastPosition = false, nil
	local PinchBase = nil
	local LoadToken = 0
	local Scroller = Card.FindFirstAncestorOfClass(Card, "ScrollingFrame")

	local function Place()
		if not Camera then return end
		Camera.CFrame = CFrame.new(Target) * CFrame.Angles(0, Yaw, 0) * CFrame.Angles(-Pitch, 0, 0) * CFrame.new(0, 0, Distance)
	end

	local function Measure()
		if not Model or not Camera then return end
		local BoxCF, BoxSize = ObjectBounds(Model)
		Target = BoxCF.Position
		Radius = math.max(BoxSize.Magnitude / 2, 0.5)
		Fit = Radius / math.sin(math.rad(math.clamp(Camera.FieldOfView, 1, 120) / 2)) * 1.1
	end

	local function Adopt()
		Measure()
		local Offset = Camera.CFrame.Position - Target
		if Offset.Magnitude < 0.01 then
			Yaw, Pitch, Distance = math.pi, 0.15, Fit
		else
			Distance = Offset.Magnitude
			Yaw = math.atan2(Offset.X, Offset.Z)
			Pitch = math.asin(math.clamp(Offset.Y / Distance, -1, 1))
		end
		Oriented = true
	end

	local function UseCamera(NewCamera)
		if Camera and OwnCamera and Camera ~= NewCamera then Camera.Destroy(Camera) end
		OwnCamera = NewCamera == nil
		Camera = NewCamera or New("Camera", { FieldOfView = 30 })
		Camera.Parent = View
		View.CurrentCamera = Camera
		Oriented = false
	end

	local Viewport

	local function Load(Object, Ready)
		LoadToken += 1
		if Model then
			Model.Destroy(Model)
			Model = nil
		end
		if not Object then
			Status.Text = "No preview available"
			Status.Visible = true
			return
		end
		local Clone = Object
		if not Ready and Info.Clone ~= false then
			pcall(function() Object.Archivable = true end)
			local Ok, Result = pcall(function() return Object.Clone(Object) end)
			if not Ok or not Result then
				Status.Text = "No preview available"
				Status.Visible = true
				return
			end
			Clone = Result
		end
		for _, D in ipairs(Clone.GetDescendants(Clone)) do
			if D.IsA(D, "BaseScript") or D.IsA(D, "Sound") or D.IsA(D, "Tool") or D.IsA(D, "ForceField") or D.IsA(D, "BillboardGui") then
				pcall(function() D.Destroy(D) end)
			elseif D.IsA(D, "Motor6D") then
				pcall(function() D.Transform = CFrame.new() end)
			elseif D.IsA(D, "BasePart") then
				D.Anchored = true
			end
		end
		if Clone.IsA(Clone, "BasePart") then Clone.Anchored = true end
		local Hum = Clone.FindFirstChildOfClass(Clone, "Humanoid")
		if Hum then Hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		Clone.Parent = View
		Clone.PivotTo(Clone, CFrame.new())
		Model = Clone
		Status.Visible = false
		Measure()
		if AutoFocus then
			Viewport:Focus()
		elseif Oriented then
			Place()
		end
	end

	local function LoadCharacter()
		LoadToken += 1
		local My = LoadToken
		Status.Text = "Loading..."
		Status.Visible = true
		task.spawn(function()
			local LP = Players.LocalPlayer
			local Clone
			local Char = LP and LP.Character
			if Char then
				pcall(function() Char.Archivable = true end)
				local Ok, Result = pcall(function() return Char.Clone(Char) end)
				if Ok and Result then Clone = Result end
			end
			if not Clone and LP then
				local Ok, Result = pcall(function() return Players.CreateHumanoidModelFromUserId(Players, LP.UserId) end)
				if Ok and Result then Clone = Result end
			end
			if My ~= LoadToken then
				if Clone then Clone.Destroy(Clone) end
				return
			end
			if not Clone then
				Status.Text = "No preview available"
				return
			end
			Load(Clone, true)
		end)
	end

	Viewport = Register(self, Block, "Viewport", Name, Key, nil, Own)

	function Viewport:Focus()
		if not Camera then return end
		Measure()
		Yaw, Pitch, Distance = math.pi, 0.15, Fit
		Oriented = true
		Place()
	end

	function Viewport:SetObject(Object)
		Info.Object = Object
		Load(Object)
	end

	function Viewport:SetCamera(NewCamera)
		UseCamera(NewCamera)
		Measure()
		if AutoFocus then self:Focus() end
	end

	function Viewport:SetInteractive(Value)
		Interactive = Value and true or false
		Hit.Visible = Interactive
		if not Interactive and Dragging then
			Dragging = false
			if Scroller then Scroller.ScrollingEnabled = true end
		end
	end

	function Viewport:SetHeight(NewHeight)
		NewHeight = tonumber(NewHeight) or Height
		Height = NewHeight
		Block.Size = UDim2.new(1, 0, 0, NewHeight + 20)
		Holder.Size = UDim2.new(1, -28, 0, NewHeight)
	end

	function Viewport:SetVisible(Value)
		Block.Visible = Value and true or false
	end

	Hit.InputBegan.Connect(Hit.InputBegan, function(Input)
		if Interactive and IsPress(Input) and Camera then
			if not Oriented then Adopt() end
			Dragging = true
			LastPosition = Input.Position
			if Scroller then Scroller.ScrollingEnabled = false end
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if Dragging and IsMove(Input) then
			local Delta = Input.Position - LastPosition
			LastPosition = Input.Position
			Yaw += Delta.X * 0.01
			Pitch = math.clamp(Pitch + Delta.Y * 0.01, -1.4, 1.4)
			Place()
		end
	end, Own)
	Connect(UserInputService.InputEnded, function(Input)
		if Dragging and IsPress(Input) then
			Dragging = false
			if Scroller then Scroller.ScrollingEnabled = true end
		end
	end, Own)

	local function Zoom(Factor)
		if not Interactive or not Camera then return end
		if not Oriented then Adopt() end
		Distance = math.clamp(Distance * Factor, Radius * 0.6, math.max(Fit * 3, Radius))
		Place()
	end
	Hit.MouseWheelForward.Connect(Hit.MouseWheelForward, function()
		Zoom(0.9)
	end)
	Hit.MouseWheelBackward.Connect(Hit.MouseWheelBackward, function()
		Zoom(1.1)
	end)
	Connect(UserInputService.TouchPinch, function(Positions, PinchScale, _, State)
		if not Interactive or not Camera or not Block.Visible then return end
		local Center = (Positions[1] + (Positions[2] or Positions[1])) / 2
		local Position, Size = Holder.AbsolutePosition, Holder.AbsoluteSize
		local Inside = Center.X >= Position.X and Center.X <= Position.X + Size.X and Center.Y >= Position.Y and Center.Y <= Position.Y + Size.Y
		if State == Enum.UserInputState.Begin and Inside then
			if not Oriented then Adopt() end
			PinchBase = Distance
		elseif PinchBase and State == Enum.UserInputState.Change then
			Distance = math.clamp(PinchBase / math.max(PinchScale, 0.1), Radius * 0.6, math.max(Fit * 3, Radius))
			Place()
		elseif State == Enum.UserInputState.End then
			PinchBase = nil
		end
	end, Own)

	UseCamera(Info.Camera)

	if Info.Object then
		Load(Info.Object)
	else
		LoadCharacter()
		pcall(function()
			local LP = Players.LocalPlayer
			Connect(LP.CharacterAdded, function()
				if Info.Object then return end
				task.wait(1)
				if Block.Parent and not Info.Object then LoadCharacter() end
			end, Own)
		end)
	end

	return Viewport
end

local function BuildNotify()
	local NotifyWidth = 320

	local NotifyHolder = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, NotifyWidth, 1, -40),
		BackgroundTransparency = 1,
		ZIndex = 200,
		Parent = Gui,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Parent = NotifyHolder,
	})

	local NotifyCount = 0

	Notify = function(Options)
		if type(Options) == "string" then Options = { Title = Options } end
		Options = Options or {}

		local Title = tostring(Options.Title or WindowConfig.Title)
		local Info = tostring(Options.Info or Options.Content or "")
		local Icon = Options.Icon or WindowConfig.Logo
		local Duration = tonumber(Options.Duration) or 4

		local TextWidth = NotifyWidth - 66 - 14
		local InfoHeight = 0
		if Info ~= "" then
			InfoHeight = TextService.GetTextSize(TextService, Info, 15, Enum.Font.GothamMedium, Vector2.new(TextWidth, 1000)).Y
		end
		local Height = math.max(72, 14 + 22 + (InfoHeight > 0 and InfoHeight + 2 or 0) + 14 + 4)

		NotifyCount += 1

		local Slot = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = NotifyCount,
			Parent = NotifyHolder,
		})

		local Card = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(1, NotifyWidth + 40, 1, 0),
			Size = UDim2.new(1, 0, 0, Height),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Slot,
		})
		Corner(Card, 12)
		Gradient(Card, Theme.CardTop, Theme.CardBottom, 90)
		local CardStroke = Stroke(Card, Color3.new(1, 1, 1), 1, 0)
		Gradient(CardStroke, Theme.LineLight, Theme.Line, 90, 0.2, 0.7)

		local IconBox = New("Frame", {
			Position = UDim2.fromOffset(14, 14),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Card,
		})
		Corner(IconBox, 10)
		Gradient(IconBox, Theme.ElementTop, Theme.ElementBottom, 90)
		Stroke(IconBox, Theme.Line, 1, 0.3)
		local NotifyIcon = MakeAccentIcon(IconBox, Icon, 22)
		NotifyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		NotifyIcon.Position = UDim2.fromScale(0.5, 0.5)

		New("TextLabel", {
			Position = UDim2.fromOffset(66, 12),
			Size = UDim2.new(1, -80, 0, 22),
			Text = Title,
			Font = Enum.Font.GothamBold,
			TextSize = 17,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Card,
		})

		if InfoHeight > 0 then
			New("TextLabel", {
				Position = UDim2.fromOffset(66, 36),
				Size = UDim2.new(1, -80, 0, InfoHeight),
				Text = Info,
				Font = Enum.Font.GothamMedium,
				TextSize = 15,
				TextColor3 = Theme.Sub,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = Card,
			})
		end

		local Bar
		if Duration > 0 then
			local Track = New("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 14, 1, -8),
				Size = UDim2.new(1, -28, 0, 3),
				BackgroundColor3 = Theme.Line,
				BackgroundTransparency = 0.3,
				Parent = Card,
			})
			Corner(Track, 2)
			Bar = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = Track,
			})
			Corner(Bar, 2)
			local BarGrad = Gradient(Bar, Theme.AccentDark, Theme.AccentLight, 0)
			RegisterAccentGradient(BarGrad, 2)
		end

		local Hit = New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = Card,
		})

		local Closed = false
		local function Close()
			if Closed then return end
			Closed = true
			Tween(Card, { Position = UDim2.new(1, NotifyWidth + 40, 1, 0) }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.25, function()
				if not Slot.Parent then return end
				Tween(Slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)
				task.delay(0.32, function()
					if Slot.Parent then Slot.Destroy(Slot) end
				end)
			end)
		end
		Hit.Activated.Connect(Hit.Activated, Close)

		Tween(Slot, { Size = UDim2.new(1, 0, 0, Height) }, 0.3, Enum.EasingStyle.Quint)
		Tween(Card, { Position = UDim2.new(0, 0, 1, 0) }, 0.5, Enum.EasingStyle.Quint)

		if Duration > 0 then
			Tween(Bar, { Size = UDim2.new(0, 0, 1, 0) }, Duration, Enum.EasingStyle.Linear)
			task.delay(Duration, Close)
		end

		return { Close = Close }
	end
end

local function EnsureFolder(Path)
	pcall(function()
		if not (isfolder and makefolder) then return end
		local Built = ""
		for Part in string.gmatch(Path, "[^/\\]+") do
			Built = Built == "" and Part or (Built .. "/" .. Part)
			if not isfolder(Built) then makefolder(Built) end
		end
	end)
end

local function ConfigPath(Name)
	return WindowConfig.Folder .. "/" .. Name .. ".json"
end

local function AutoloadPath()
	return WindowConfig.Folder .. "/autoload.txt"
end

local function FetchConfigs()
	local ConfigList = {}
	pcall(function()
		if listfiles and isfolder and isfolder(WindowConfig.Folder) then
			for _, FilePath in ipairs(listfiles(WindowConfig.Folder)) do
				if string.sub(FilePath, -5) == ".json" then
					local Name = string.match(FilePath, "([^/\\]+)%.json$")
					if Name then
						ConfigList[#ConfigList + 1] = Name
					end
				end
			end
		end
	end)
	if #ConfigList == 0 then
		ConfigList[1] = "default"
	end
	return ConfigList
end

local function GetAutoloadConfig()
	local AutoName = "None"
	pcall(function()
		if isfile and readfile and isfile(AutoloadPath()) then
			local Read = readfile(AutoloadPath())
			if Read and Read ~= "" then
				AutoName = Read
			end
		end
	end)
	return AutoName
end

local function SaveConfig(Name)
	if not Name or Name == "" then return false end
	local SaveData = {}
	for K, V in pairs(Flags) do
		if typeof(V) == "Color3" then
			SaveData[K] = { __type = "Color3", R = V.R, G = V.G, B = V.B }
		else
			SaveData[K] = V
		end
	end
	local Ok, Enc = pcall(function() return HttpService.JSONEncode(HttpService, SaveData) end)
	if Ok and Enc then
		EnsureFolder(WindowConfig.Folder)
		pcall(function()
			if writefile then
				writefile(ConfigPath(Name), Enc)
			end
		end)
		return true
	end
	return false
end

local function LoadConfig(Name)
	if not Name or Name == "" then return false end
	local Loaded = false
	pcall(function()
		local Path = ConfigPath(Name)
		if isfile and readfile and isfile(Path) then
			local Content = readfile(Path)
			local Ok, Dec = pcall(function() return HttpService.JSONDecode(HttpService, Content) end)
			if Ok and type(Dec) == "table" then
				for K, V in pairs(Dec) do
					local RawValue = V
					if type(V) == "table" and V.__type == "Color3" then
						RawValue = Color3.new(V.R, V.G, V.B)
					end
					Flags[K] = RawValue
					if ControlBinds[K] then
						pcall(function() ControlBinds[K](RawValue) end)
					end
				end
				Loaded = true
			end
		end
	end)
	return Loaded
end

local function DeleteConfig(Name)
	if not Name or Name == "" then return false end
	local Deleted = false
	pcall(function()
		local Path = ConfigPath(Name)
		if isfile and delfile and isfile(Path) then
			delfile(Path)
			Deleted = true
		end
	end)
	return Deleted
end

local function SetAutoload(Name)
	if not Name or Name == "" then return false end
	local Done = false
	EnsureFolder(WindowConfig.Folder)
	pcall(function()
		if writefile then
			writefile(AutoloadPath(), Name)
			Done = true
		end
	end)
	return Done
end

local function ClearAutoload()
	local Done = false
	pcall(function()
		if isfile and delfile and isfile(AutoloadPath()) then
			delfile(AutoloadPath())
			Done = true
		end
	end)
	return Done
end

local function BuildWatermark()
	local Watermark = New("Frame", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 150,
		Parent = Gui,
	})
	Corner(Watermark, 9)
	Gradient(Watermark, Theme.CardTop, Theme.CardBottom, 90)
	local WatermarkStroke = Stroke(Watermark, Color3.new(1, 1, 1), 1, 0)
	Gradient(WatermarkStroke, Theme.LineLight, Theme.Line, 90, 0.2, 0.7)

	local WatermarkContainer = New("Frame", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 152,
		Parent = Watermark,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = WatermarkContainer,
	})
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = WatermarkContainer })

	local WatermarkAccent = New("Frame", {
		Position = UDim2.new(0, 8, 1, -2),
		Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 151,
		Parent = Watermark,
	})
	local WmGrad = New("UIGradient", {
		Color = ColorSequence.new(Theme.AccentDark, Theme.AccentLight),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = WatermarkAccent,
	})
	RegisterAccentGradient(WmGrad, 2)

	local WatermarkLogo = MakeAccentIcon(WatermarkContainer, WindowConfig.Logo, 16)
	WatermarkLogo.LayoutOrder = 1

	New("TextLabel", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = WindowConfig.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		LayoutOrder = 2,
		Parent = WatermarkContainer,
	})

	local function WatermarkSeparator(Order)
		return New("Frame", {
			Size = UDim2.fromOffset(1, 12),
			BackgroundColor3 = Theme.LineLight,
			BackgroundTransparency = 0.3,
			LayoutOrder = Order,
			Parent = WatermarkContainer,
		})
	end

	local function WatermarkSegment(Order, IconName)
		local Holder = New("Frame", {
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = Order,
			Parent = WatermarkContainer,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Holder,
		})
		local SegmentIcon = MakeIcon(Holder, { IconName }, 12, Theme.Muted)
		SegmentIcon.LayoutOrder = 1
		return New("TextLabel", {
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			RichText = true,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.Text,
			LayoutOrder = 2,
			Parent = Holder,
		})
	end

	local function WatermarkRich(Value, Unit)
		return string.format(
			'<font color="%s">%s</font> <font color="%s">%s</font>',
			ColorToHex(Theme.Text),
			tostring(Value),
			ColorToHex(Theme.Muted),
			Unit
		)
	end

	local function GetPing()
		local Value = 0
		pcall(function()
			local Item = Stats.Network.ServerStatsItem["Data Ping"]
			Value = Item.GetValue(Item)
		end)
		return math.floor(Value + 0.5)
	end

	WatermarkSeparator(3)
	local UserLabel = WatermarkSegment(4, "user")
	UserLabel.RichText = false
	UserLabel.Text = Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player"
	WatermarkSeparator(5)
	local FpsLabel = WatermarkSegment(6, "activity")
	FpsLabel.Text = WatermarkRich(60, "FPS")
	WatermarkSeparator(7)
	local PingLabel = WatermarkSegment(8, "wifi")
	PingLabel.Text = WatermarkRich(GetPing(), "ms")

	local Frames, Elapsed = 0, 0
	Connect(RunService.RenderStepped, function(Delta)
		Frames += 1
		Elapsed += Delta
		if Elapsed >= 0.5 then
			FpsLabel.Text = WatermarkRich(math.floor(Frames / Elapsed + 0.5), "FPS")
			PingLabel.Text = WatermarkRich(GetPing(), "ms")
			Frames = 0
			Elapsed = 0
		end
		Watermark.Visible = Flags[WatermarkKey] ~= false
	end)
end

local function NewModal(Title, Width, Height)
	local Modal = { Token = 0 }

	Modal.Overlay = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 100,
		Parent = Main,
	})
	Corner(Modal.Overlay, 10)

	Modal.Panel = New("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(Width, Height),
		BackgroundColor3 = Color3.fromRGB(38, 38, 40),
		GroupTransparency = 1,
		Active = true,
		Parent = Modal.Overlay,
	})
	Corner(Modal.Panel, 14)
	Stroke(Modal.Panel, Theme.LineLight, 1, 0.3)
	Modal.PanelScale = New("UIScale", { Scale = 0.92, Parent = Modal.Panel })

	Modal.Title = New("TextLabel", {
		Position = UDim2.fromOffset(26, 20),
		Size = UDim2.new(1, -100, 0, 38),
		Text = Title,
		Font = Enum.Font.GothamMedium,
		TextSize = 28,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Modal.Panel,
	})

	local CloseButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 18),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Parent = Modal.Panel,
	})
	local CloseIcon = MakeIcon(CloseButton, { "x" }, 20, Theme.Muted)
	CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	CloseIcon.Position = UDim2.fromScale(0.5, 0.5)
	CloseButton.MouseEnter.Connect(CloseButton.MouseEnter, function()
		Tween(CloseIcon, { ImageColor3 = Theme.Text, Rotation = 90 }, 0.25, Enum.EasingStyle.Back)
	end)
	CloseButton.MouseLeave.Connect(CloseButton.MouseLeave, function()
		Tween(CloseIcon, { ImageColor3 = Theme.Muted, Rotation = 0 }, 0.25, Enum.EasingStyle.Back)
	end)

	function Modal.Close()
		if not Modal.Overlay.Visible then return end
		Modal.Token += 1
		local My = Modal.Token
		if Modal.OnClose then Modal.OnClose() end

		Tween(Modal.Overlay, { BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		Tween(Modal.Panel, { Position = UDim2.fromScale(0.5, 0.52), GroupTransparency = 1 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Tween(Modal.PanelScale, { Scale = 0.95 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

		task.delay(0.26, function()
			if My == Modal.Token then
				Modal.Overlay.Visible = false
				if Modal.OnClosed then Modal.OnClosed() end
			end
		end)
	end

	function Modal.Open()
		CloseColor()
		if OpenDropdown then OpenDropdown() end
		for _, Other in ipairs(Modals) do
			if Other ~= Modal and Other.Overlay.Visible then Other.Close() end
		end
		Modal.Token += 1
		Modal.Overlay.Visible = true
		Modal.Overlay.BackgroundTransparency = 1
		Modal.Panel.Position = UDim2.fromScale(0.5, 0.54)
		Modal.Panel.GroupTransparency = 1
		Modal.PanelScale.Scale = 0.92
		if Modal.OnOpen then Modal.OnOpen() end

		Tween(Modal.Overlay, { BackgroundTransparency = OverlayTransparency }, 0.35, Enum.EasingStyle.Sine)
		Tween(Modal.Panel, { Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0 }, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		Tween(Modal.PanelScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		if Modal.OnOpened then Modal.OnOpened() end
	end

	CloseButton.Activated.Connect(CloseButton.Activated, Modal.Close)
	Modal.Overlay.Activated.Connect(Modal.Overlay.Activated, Modal.Close)

	Modals[#Modals + 1] = Modal
	return Modal
end

local function NewSideButton(Icons, Wide)
	if Wide then
		local Button = New("TextButton", {
			Position = UDim2.fromOffset(12, BaseHeight - 54),
			Size = UDim2.fromOffset(SidebarWidth - 24, 38),
			BackgroundColor3 = Color3.fromRGB(46, 48, 52),
			Parent = Sidebar,
		})
		Corner(Button, 6)
		local ButtonStroke = Stroke(Button, Theme.LineLight, 1, 0.7)
		local ButtonIcon = MakeIcon(Button, Icons, 18, Theme.Muted)
		ButtonIcon.AnchorPoint = Vector2.new(0, 0.5)
		ButtonIcon.Position = UDim2.new(0, 12, 0.5, 0)
		local ButtonText = New("TextLabel", {
			Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -48, 1, 0),
			Text = "Search...",
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Button,
		})
		Button.MouseEnter.Connect(Button.MouseEnter, function()
			Tween(ButtonStroke, { Transparency = 0.4 }, 0.2)
			Tween(ButtonIcon, { ImageColor3 = Theme.Sub }, 0.2)
			Tween(ButtonText, { TextColor3 = Theme.Sub }, 0.2)
		end)
		Button.MouseLeave.Connect(Button.MouseLeave, function()
			Tween(ButtonStroke, { Transparency = 0.7 }, 0.2)
			Tween(ButtonIcon, { ImageColor3 = Theme.Muted }, 0.2)
			Tween(ButtonText, { TextColor3 = Theme.Muted }, 0.2)
		end)
		return Button
	end

	local Size, Gap = 32, 6
	local Button = New("TextButton", {
		Position = UDim2.fromOffset(12 + (Size + Gap) * SideSlots, BaseHeight - 54 - 8 - Size),
		Size = UDim2.fromOffset(Size, Size),
		BackgroundColor3 = Color3.fromRGB(46, 48, 52),
		Parent = Sidebar,
	})
	SideSlots += 1
	Corner(Button, 6)
	local ButtonStroke = Stroke(Button, Theme.Line, 1, 1)
	local ButtonIcon = MakeIcon(Button, Icons, 16, Theme.Muted)
	ButtonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	ButtonIcon.Position = UDim2.fromScale(0.5, 0.5)

	Button.MouseEnter.Connect(Button.MouseEnter, function()
		Tween(ButtonStroke, { Transparency = 0.4 }, 0.2)
		Tween(ButtonIcon, { ImageColor3 = Theme.Accent }, 0.2)
	end)
	Button.MouseLeave.Connect(Button.MouseLeave, function()
		Tween(ButtonStroke, { Transparency = 1 }, 0.2)
		Tween(ButtonIcon, { ImageColor3 = Theme.Muted }, 0.2)
	end)
	return Button
end

local function SelectTab(Name)
	local Previous = Current
	Current = Name
	if OpenDropdown then OpenDropdown() end
	CloseColor()
	local PageBase = UDim2.fromOffset(SidebarWidth + 1, 0)
	local PageStart = UDim2.fromOffset(SidebarWidth + 1, 18)
	for _, Tab in ipairs(Tabs) do
		local On = Tab.Name == Name
		if On then
			if Previous ~= Name then
				Tab.Page.Position = PageStart
				Tab.Page.Visible = true
				Tween(Tab.Page, { Position = PageBase }, 0.3, Enum.EasingStyle.Quint)
			else
				Tab.Page.Visible = true
			end
		else
			Tab.Page.Visible = false
		end
		Tween(Tab.Button, { BackgroundTransparency = On and 0 or 1 })
		Tween(Tab.Stroke, { Transparency = On and 0.6 or 1 })
		Tab.Text.Font = On and Enum.Font.GothamBold or Enum.Font.GothamMedium
		Tween(Tab.Text, { TextColor3 = On and Color3.new(1, 1, 1) or Theme.Sub })
		Tween(Tab.Icon, { ImageColor3 = On and Color3.new(1, 1, 1) or Theme.Sub })
	end
end

local TabMeta = {}
TabMeta.__index = TabMeta

function TabMeta:AddSection(Title, Icon, Side)
	Side = Side == "Right" and "Right" or "Left"
	local Column = Side == "Right" and self.RightColumn or self.LeftColumn
	self.Counts[Side] += 1
	local Card, Holder = NewSection(Column, Title, Icon or "box", self.Counts[Side])
	Index[#Index + 1] = { Name = Title, Kind = "Section", Page = self.Name, Target = Holder, Rank = 0 }
	return NewContainer(Card, self.Name, self.Name .. "/" .. Title, Holder)
end

function TabMeta:AddLeftSection(Title, Icon)
	return self:AddSection(Title, Icon, "Left")
end

function TabMeta:AddRightSection(Title, Icon)
	return self:AddSection(Title, Icon, "Right")
end

function TabMeta:Select()
	SelectTab(self.Name)
end

local WindowMeta = {}
WindowMeta.__index = WindowMeta

function WindowMeta:AddTab(Name, Icon, Category)
	if Category and Category ~= LastCategory then
		TabOrder += 1
		local First = LastCategory == nil
		LastCategory = Category
		local CategoryLabel = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, First and 24 or 38),
			Text = Category,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			LayoutOrder = TabOrder,
			Parent = Items,
		})
		New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingBottom = UDim.new(0, 4), Parent = CategoryLabel })
	end
	TabOrder += 1

	local Button = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.SelectedTop,
		BackgroundTransparency = 1,
		LayoutOrder = TabOrder,
		Parent = Items,
	})
	Corner(Button, 6)
	local ButtonStroke = Stroke(Button, Theme.LineLight, 1, 1)
	local TabIcon = MakeIcon(Button, Icon or "layers", 20, Theme.Sub)
	TabIcon.Position = UDim2.fromOffset(12, 11)
	local TabText = New("TextLabel", {
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Text = Name,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Button,
	})

	local Page = New("Frame", {
		Position = UDim2.fromOffset(SidebarWidth + 1, 0),
		Size = UDim2.fromOffset(BaseWidth - SidebarWidth - 7, BaseHeight - 6),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = Content,
	})
	local Scroller = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = Page,
	})
	New("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 70), Parent = Scroller })

	local function NewColumn(X)
		local Column = New("Frame", {
			Position = UDim2.fromOffset(X, 0),
			Size = UDim2.fromOffset(335, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = Scroller,
		})
		New("UIListLayout", { Padding = UDim.new(0, 22), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Column })
		return Column
	end

	Tabs[#Tabs + 1] = { Name = Name, Category = Category, Button = Button, Stroke = ButtonStroke, Icon = TabIcon, Text = TabText, Page = Page, Scroller = Scroller }

	Button.Activated.Connect(Button.Activated, function()
		SelectTab(Name)
	end)
	Button.MouseEnter.Connect(Button.MouseEnter, function()
		if Current ~= Name then
			Tween(Button, { BackgroundTransparency = 0.6 })
			Tween(TabText, { TextColor3 = Theme.Text })
			Tween(TabIcon, { ImageColor3 = Theme.Text })
		end
	end)
	Button.MouseLeave.Connect(Button.MouseLeave, function()
		if Current ~= Name then
			Tween(Button, { BackgroundTransparency = 1 })
			Tween(TabText, { TextColor3 = Theme.Sub })
			Tween(TabIcon, { ImageColor3 = Theme.Sub })
		end
	end)

	local Tab = setmetatable({
		Name = Name,
		Counts = { Left = 0, Right = 0 },
		LeftColumn = NewColumn(16),
		RightColumn = NewColumn(364),
	}, TabMeta)

	if not Current then SelectTab(Name) end
	return Tab
end

function WindowMeta:SelectTab(Name)
	SelectTab(Name)
end

function WindowMeta:Notify(Options)
	if Notify then return Notify(Options) end
end

function WindowMeta:SetVisible(Visible)
	Main.Visible = Visible and true or false
end

function WindowMeta:Toggle()
	Main.Visible = not Main.Visible
end

function WindowMeta:SaveConfig(Name)
	return SaveConfig(Name)
end

function WindowMeta:LoadConfig(Name)
	return LoadConfig(Name)
end

function WindowMeta:Destroy()
	for _, Connection in ipairs(Connections) do
		pcall(function() Connection.Disconnect(Connection) end)
	end
	table.clear(Connections)
	pcall(function() Gui.Destroy(Gui) end)
	if Library.Window == self then Library.Window = nil end
end

function Library:Notify(Options)
	if Notify then return Notify(Options) end
end

function WindowMeta:LoadSettingManger()
	if self.SettingsLoaded then return end
	self.SettingsLoaded = true

	local Modal = NewModal("Settings", 480, 360)
	local Button = NewSideButton({ "settings", "sliders" })
	Button.Activated.Connect(Button.Activated, Modal.Open)

	local SettingsHolder = New("Frame", {
		Position = UDim2.fromOffset(24, 76),
		Size = UDim2.new(1, -48, 1, -90),
		BackgroundTransparency = 1,
		Parent = Modal.Panel,
	})
	local SettingsCard = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = SettingsHolder,
	})
	Corner(SettingsCard, 10)
	Gradient(SettingsCard, Theme.CardTop, Theme.CardBottom, 90)
	local SettingsCardStroke = Stroke(SettingsCard, Color3.new(1, 1, 1), 1, 0)
	Gradient(SettingsCardStroke, Theme.LineLight, Theme.Line, 90, 0.4, 0.8)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = SettingsCard })
	New("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), Parent = SettingsCard })

	local Settings = NewContainer(SettingsCard, "Settings", "Settings", nil, true)
	Settings:AddColorPicker("Accent Color", {
		Flag = "Settings/AccentColor",
		Default = Theme.Accent,
		Callback = UpdateAccentTheme,
	})
	Settings:AddSlider("UI Scale", {
		Flag = "Settings/UIScale",
		Min = 0.5,
		Max = 1.5,
		Default = 1,
		Increment = 0.05,
		Callback = function()
			UpdateScale()
		end,
	})
	Settings:AddToggle("Show Watermark", {
		Flag = WatermarkKey,
		Default = Flags[WatermarkKey] ~= false,
	})

	return Settings
end

function WindowMeta:LoadConfigManger()
	if self.ConfigLoaded then return end
	self.ConfigLoaded = true

	EnsureFolder(WindowConfig.Folder)

	local Modal = NewModal("Config Manager", 500, 480)
	local Button = NewSideButton({ "folder", "file-text", "archive" })
	Button.Activated.Connect(Button.Activated, Modal.Open)

	local AutoloadStatusLabel = New("TextLabel", {
		Position = UDim2.fromOffset(26, 62),
		Size = UDim2.new(1, -52, 0, 22),
		Text = "Autoload: None",
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Theme.AccentLight,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Modal.Panel,
	})
	RegisterAccentColor(AutoloadStatusLabel, "TextColor3", "Light")

	local function RefreshAutoloadStatus()
		AutoloadStatusLabel.Text = "Autoload: " .. GetAutoloadConfig()
	end

	local ConfigContainer = New("Frame", {
		Position = UDim2.fromOffset(24, 92),
		Size = UDim2.new(1, -48, 1, -110),
		BackgroundTransparency = 1,
		Parent = Modal.Panel,
	})

	local ConfigCard = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ConfigContainer,
	})
	Corner(ConfigCard, 10)
	Gradient(ConfigCard, Theme.CardTop, Theme.CardBottom, 90)
	local ConfigCardStroke = Stroke(ConfigCard, Color3.new(1, 1, 1), 1, 0)
	Gradient(ConfigCardStroke, Theme.LineLight, Theme.Line, 90, 0.4, 0.8)
	New("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = ConfigCard })

	local InputFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ConfigCard,
	})
	Corner(InputFrame, 7)
	Gradient(InputFrame, Theme.Field, Theme.Field, 90)
	Stroke(InputFrame, Theme.Line, 1, 0.3)
	local ConfigBox = New("TextBox", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Text,
		PlaceholderText = "Config Name...",
		PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = InputFrame,
	})

	local DropdownFrame = New("Frame", {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = ConfigCard,
	})
	Corner(DropdownFrame, 7)
	Gradient(DropdownFrame, Theme.Field, Theme.Field, 90)
	Stroke(DropdownFrame, Theme.Line, 1, 0.3)

	local DropdownValue = New("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Text = "Select Config",
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = DropdownFrame,
	})
	local DropdownChevron = MakeIcon(DropdownFrame, { "layout-panel-left", "panel-left", "layout-dashboard" }, 20, Theme.Muted)
	DropdownChevron.AnchorPoint = Vector2.new(1, 0.5)
	DropdownChevron.Position = UDim2.new(1, -10, 0.5, 0)
	local DropdownBtn = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = DropdownFrame,
	})

	local DropdownList = New("Frame", {
		Position = UDim2.new(0, 0, 1, 8),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(29, 30, 32),
		Visible = false,
		ZIndex = 50,
		Parent = DropdownFrame,
	})
	Corner(DropdownList, 8)
	Stroke(DropdownList, Theme.Line, 1, 0.2)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = DropdownList })
	New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = DropdownList })

	local function CloseConfigList()
		DropdownList.Visible = false
		DropdownFrame.ZIndex = 1
		ConfigCard.ZIndex = 1
	end

	local function RefreshConfigDropdown()
		for _, Child in ipairs(DropdownList.GetChildren(DropdownList)) do
			if Child.IsA(Child, "TextButton") then Child.Destroy(Child) end
		end
		for OrderIndex, ConfigName in ipairs(FetchConfigs()) do
			local ItemBtn = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				Text = ConfigName,
				Font = Enum.Font.GothamMedium,
				TextSize = 15,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = OrderIndex,
				Parent = DropdownList,
			})
			New("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = ItemBtn })
			ItemBtn.Activated.Connect(ItemBtn.Activated, function()
				DropdownValue.Text = ConfigName
				ConfigBox.Text = ConfigName
				CloseConfigList()
			end)
		end
	end

	DropdownBtn.Activated.Connect(DropdownBtn.Activated, function()
		if DropdownList.Visible then
			CloseConfigList()
		else
			DropdownList.Visible = true
			DropdownFrame.ZIndex = 50
			ConfigCard.ZIndex = 50
			RefreshConfigDropdown()
		end
	end)

	local ButtonContainer = New("Frame", {
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 1, -100),
		BackgroundTransparency = 1,
		Parent = ConfigCard,
	})
	New("UIGridLayout", {
		CellSize = UDim2.new(0.48, 0, 0, 42),
		CellPadding = UDim2.new(0.04, 0, 0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = ButtonContainer,
	})

	local function CreateActionBtn(Text, Order, Action)
		local Frame = New("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			LayoutOrder = Order,
			Parent = ButtonContainer,
		})
		Corner(Frame, 8)
		Gradient(Frame, Theme.ElementTop, Theme.ElementBottom, 90)
		local Line = Stroke(Frame, Theme.Line, 1, 0.3)
		local ActionButton = New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Theme.Text,
			Parent = Frame,
		})
		ActionButton.MouseEnter.Connect(ActionButton.MouseEnter, function()
			Tween(Line, { Transparency = 0 })
		end)
		ActionButton.MouseLeave.Connect(ActionButton.MouseLeave, function()
			Tween(Line, { Transparency = 0.3 })
		end)
		ActionButton.Activated.Connect(ActionButton.Activated, function()
			Line.Color = Theme.Accent
			Tween(Line, { Color = Theme.Line }, 0.35)
			if Action then Action() end
		end)
		return Frame
	end

	local function Target()
		local TargetName = ConfigBox.Text
		if TargetName == "" then TargetName = DropdownValue.Text end
		if TargetName == "Select Config" then TargetName = "" end
		return TargetName
	end

	CreateActionBtn("Save", 1, function()
		local TargetName = ConfigBox.Text
		if TargetName == "" then TargetName = "default" end
		if SaveConfig(TargetName) then
			DropdownValue.Text = TargetName
			RefreshConfigDropdown()
			Notify({ Title = "Config Manager", Info = "Saved config: " .. TargetName, Icon = "save", Duration = 3 })
		end
	end)

	CreateActionBtn("Load", 2, function()
		local TargetName = Target()
		if LoadConfig(TargetName) then
			Notify({ Title = "Config Manager", Info = "Loaded config: " .. TargetName, Icon = "folder", Duration = 3 })
		else
			Notify({ Title = "Config Manager", Info = "Failed to load: " .. TargetName, Icon = "x", Duration = 3 })
		end
	end)

	CreateActionBtn("Update", 3, function()
		local TargetName = Target()
		if SaveConfig(TargetName) then
			Notify({ Title = "Config Manager", Info = "Updated config: " .. TargetName, Icon = "check", Duration = 3 })
		end
	end)

	CreateActionBtn("Set Autoload", 4, function()
		local TargetName = Target()
		if SetAutoload(TargetName) then
			RefreshAutoloadStatus()
			Notify({ Title = "Config Manager", Info = "Set autoload to: " .. TargetName, Icon = "star", Duration = 3 })
		end
	end)

	CreateActionBtn("Remove Autoload", 5, function()
		if ClearAutoload() then
			RefreshAutoloadStatus()
			Notify({ Title = "Config Manager", Info = "Autoload removed", Icon = "trash-2", Duration = 3 })
		end
	end)

	CreateActionBtn("Delete", 6, function()
		local TargetName = Target()
		if DeleteConfig(TargetName) then
			if GetAutoloadConfig() == TargetName then
				ClearAutoload()
				RefreshAutoloadStatus()
			end
			DropdownValue.Text = "Select Config"
			ConfigBox.Text = ""
			RefreshConfigDropdown()
			Notify({ Title = "Config Manager", Info = "Deleted config: " .. TargetName, Icon = "trash", Duration = 3 })
		end
	end)

	Modal.OnOpen = function()
		RefreshAutoloadStatus()
		RefreshConfigDropdown()
	end
	Modal.OnClose = CloseConfigList

	task.defer(function()
		local AutoName = GetAutoloadConfig()
		if AutoName ~= "None" then
			LoadConfig(AutoName)
		end
	end)
end

function WindowMeta:LoadSerachManger()
	if self.SearchLoaded then return end
	self.SearchLoaded = true

	local Modal = NewModal("Search", 600, 500)
	Modal.Title.Size = UDim2.new(1, -200, 0, 38)
	local Button = NewSideButton({ "search" }, true)
	Button.Activated.Connect(Button.Activated, Modal.Open)

	local CountLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -62, 0, 29),
		Size = UDim2.fromOffset(120, 22),
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Modal.Panel,
	})

	local ModalSearch = New("Frame", {
		Position = UDim2.fromOffset(24, 76),
		Size = UDim2.new(1, -48, 0, 54),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Modal.Panel,
	})
	Corner(ModalSearch, 12)
	Gradient(ModalSearch, Theme.Field, Theme.Field, 90)
	local ModalStroke = Stroke(ModalSearch, Theme.Line, 1, 0.1)
	local ModalIcon = MakeIcon(ModalSearch, { "search" }, 24, Theme.Muted)
	ModalIcon.Position = UDim2.fromOffset(16, 15)
	local ModalBox = New("TextBox", {
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -66, 1, 0),
		BackgroundTransparency = 1,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.Muted,
		Font = Enum.Font.GothamMedium,
		TextSize = 20,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = ModalSearch,
	})

	ModalBox.Focused.Connect(ModalBox.Focused, function()
		Tween(ModalStroke, { Color = Theme.Accent, Transparency = 0 }, 0.25)
		Tween(ModalIcon, { ImageColor3 = Theme.Accent }, 0.25)
	end)
	ModalBox.FocusLost.Connect(ModalBox.FocusLost, function()
		Tween(ModalStroke, { Color = Theme.Line, Transparency = 0.1 }, 0.25)
		Tween(ModalIcon, { ImageColor3 = Theme.Muted }, 0.25)
	end)

	local Results = New("ScrollingFrame", {
		Position = UDim2.fromOffset(24, 146),
		Size = UDim2.new(1, -48, 1, -162),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = Modal.Panel,
	})
	RegisterAccentColor(Results, "ScrollBarImageColor3", "Accent")
	New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Results })
	New("UIPadding", { PaddingRight = UDim.new(0, 18), Parent = Results })

	local RefreshToken = 0
	local FirstEntry

	local FlashToken = 0
	local ActiveFlash

	local function Flash(TargetObject, Scroller)
		if not TargetObject or not TargetObject.Parent or not Scroller then return end

		if ActiveFlash then
			ActiveFlash()
			ActiveFlash = nil
		end

		FlashToken += 1
		local My = FlashToken
		local IsSection = TargetObject.GetAttribute(TargetObject, "SectionHolder") == true
		local Pad = IsSection and 5 or 3

		local Glow = New("Frame", {
			BackgroundColor3 = Theme.AccentLight,
			BackgroundTransparency = 1,
			ZIndex = 50,
			Parent = Scroller,
		})
		Corner(Glow, IsSection and 14 or 9)
		local GlowStroke = Stroke(Glow, Theme.AccentLight, 2, 1)

		local Connection

		local function Place()
			if not TargetObject.Parent or not Glow.Parent then return end
			local S = math.max(Scale.Scale, 0.01)
			local Rel = (TargetObject.AbsolutePosition - Scroller.AbsolutePosition) / S
			Glow.Position = UDim2.fromOffset(
				Rel.X - Pad + Scroller.CanvasPosition.X,
				Rel.Y - Pad + Scroller.CanvasPosition.Y - 16
			)
			Glow.Size = UDim2.fromOffset(
				TargetObject.AbsoluteSize.X / S + Pad * 2,
				TargetObject.AbsoluteSize.Y / S + Pad * 2
			)
		end

		local function Cleanup()
			if Connection then
				Connection.Disconnect(Connection)
				Connection = nil
			end
			if Glow.Parent then Glow.Destroy(Glow) end
		end

		ActiveFlash = Cleanup
		Place()
		Connection = RunService.RenderStepped.Connect(RunService.RenderStepped, Place)

		Tween(Glow, { BackgroundTransparency = 0.82 }, 0.15, Enum.EasingStyle.Quad)
		Tween(GlowStroke, { Transparency = 0.05 }, 0.15, Enum.EasingStyle.Quad)

		task.delay(0.7, function()
			if My ~= FlashToken or not Glow.Parent then return end
			Tween(Glow, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)
			Tween(GlowStroke, { Transparency = 1 }, 0.3, Enum.EasingStyle.Quad)
		end)

		task.delay(1.02, function()
			if My == FlashToken then
				ActiveFlash = nil
			end
			Cleanup()
		end)
	end

	local function GoTo(Entry)
		Modal.Close()
		SelectTab(Entry.Page)
		task.spawn(function()
			task.wait(0.08)
			local FoundScroller
			pcall(function()
				for _, Tab in ipairs(Tabs) do
					if Tab.Name == Entry.Page then
						local Scroller = Tab.Scroller
						FoundScroller = Scroller
						local Offset = Entry.Kind == "Section" and 16 or 70
						local Y = (Entry.Target.AbsolutePosition.Y - Scroller.AbsolutePosition.Y) / Scale.Scale + Scroller.CanvasPosition.Y - Offset
						Tween(Scroller, { CanvasPosition = Vector2.new(0, math.max(Y, 0)) }, 0.5, Enum.EasingStyle.Quint)
					end
				end
			end)
			task.wait(0.2)
			Flash(Entry.Target, FoundScroller)
		end)
	end

	local function Escape(Text)
		return (string.gsub(string.gsub(string.gsub(Text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
	end

	local function Highlight(Text, Query)
		if Query == "" then return Escape(Text) end
		local S, E = string.find(string.lower(Text), Query, 1, true)
		if not S then return Escape(Text) end
		return Escape(string.sub(Text, 1, S - 1))
			.. '<font color="' .. ColorToHex(Theme.AccentLight) .. '">' .. Escape(string.sub(Text, S, E)) .. "</font>"
			.. Escape(string.sub(Text, E + 1))
	end

	local function Refresh(Mode)
		RefreshToken += 1
		local My = RefreshToken
		local Opening = Mode == "open"

		for _, Child in ipairs(Results.GetChildren(Results)) do
			if Child.IsA(Child, "GuiObject") then Child.Destroy(Child) end
		end
		local Raw = ModalBox.Text
		local Query = string.lower(string.match(Raw, "^%s*(.-)%s*$"))
		Modal.Title.Text = Raw ~= "" and Raw or "Search"

		local Found = {}
		for Position, Entry in ipairs(Index) do
			if Entry.Target and Entry.Target.Parent then
				local Lower = string.lower(Entry.Name)
				local At = Query == "" and 1 or string.find(Lower, Query, 1, true)
				if At then
					Found[#Found + 1] = { Entry = Entry, Prefix = At == 1 and 0 or 1, Position = Position }
				end
			end
		end
		table.sort(Found, function(A, B)
			if A.Entry.Rank ~= B.Entry.Rank then return A.Entry.Rank < B.Entry.Rank end
			if A.Prefix ~= B.Prefix then return A.Prefix < B.Prefix end
			return A.Position < B.Position
		end)

		FirstEntry = Found[1] and Found[1].Entry or nil
		CountLabel.Text = #Found == 1 and "1 result" or (#Found .. " results")

		if #Found == 0 then
			local Empty = New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 90),
				Text = "No results found",
				Font = Enum.Font.GothamMedium,
				TextSize = 19,
				TextColor3 = Theme.Muted,
				TextTransparency = 1,
				Parent = Results,
			})
			Tween(Empty, { TextTransparency = 0 }, 0.3)
		end

		local Step = Opening and 0.035 or 0.012
		local Duration = Opening and 0.5 or 0.24
		local SlideFrom = Opening and 22 or 8

		for Number = 1, math.min(#Found, 60) do
			local Entry = Found[Number].Entry
			local Slot = New("Frame", {
				Size = UDim2.new(1, 0, 0, 62),
				BackgroundTransparency = 1,
				LayoutOrder = Number,
				Parent = Results,
			})
			local Row = New("Frame", {
				Position = UDim2.fromOffset(0, SlideFrom),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(46, 47, 50),
				BackgroundTransparency = 1,
				Parent = Slot,
			})
			Corner(Row, 10)
			local RowStroke = Stroke(Row, Theme.Line, 1, 1)
			local Bar = New("Frame", {
				Size = UDim2.fromOffset(4, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 12, 0.5, 0),
				BackgroundColor3 = Theme.Accent,
				Parent = Row,
			})
			RegisterAccentColor(Bar, "BackgroundColor3", "Accent")
			local TitleLabel = New("TextLabel", {
				Position = UDim2.fromOffset(28, 8),
				Size = UDim2.new(1, -44, 0, 26),
				RichText = true,
				Text = Highlight(Entry.Name, Query),
				Font = Enum.Font.GothamMedium,
				TextSize = 20,
				TextColor3 = Theme.Text,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Row,
			})
			local SubText = Entry.Page .. " · " .. Entry.Kind
			if Entry.Via then SubText = SubText .. " · in " .. Entry.Via end
			local SubLabel = New("TextLabel", {
				Position = UDim2.fromOffset(28, 34),
				Size = UDim2.new(1, -44, 0, 20),
				Text = SubText,
				Font = Enum.Font.GothamMedium,
				TextSize = 16,
				TextColor3 = Theme.Muted,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Row,
			})
			local Hit = New("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 5,
				Parent = Row,
			})
			Hit.MouseEnter.Connect(Hit.MouseEnter, function()
				Tween(Row, { BackgroundColor3 = Color3.fromRGB(54, 56, 60) }, 0.2)
				Tween(RowStroke, { Color = Theme.Accent, Transparency = 0.45 }, 0.2)
				Tween(Bar, { Size = UDim2.fromOffset(4, 40) }, 0.3, Enum.EasingStyle.Back)
				Tween(TitleLabel, { Position = UDim2.fromOffset(34, 8) }, 0.25, Enum.EasingStyle.Quint)
				Tween(SubLabel, { Position = UDim2.fromOffset(34, 34) }, 0.25, Enum.EasingStyle.Quint)
			end)
			Hit.MouseLeave.Connect(Hit.MouseLeave, function()
				Tween(Row, { BackgroundColor3 = Color3.fromRGB(46, 47, 50) }, 0.2)
				Tween(RowStroke, { Color = Theme.Line, Transparency = 0.6 }, 0.2)
				Tween(Bar, { Size = UDim2.fromOffset(4, 32) }, 0.2)
				Tween(TitleLabel, { Position = UDim2.fromOffset(28, 8) }, 0.25, Enum.EasingStyle.Quint)
				Tween(SubLabel, { Position = UDim2.fromOffset(28, 34) }, 0.25, Enum.EasingStyle.Quint)
			end)
			Hit.Activated.Connect(Hit.Activated, function()
				GoTo(Entry)
			end)

			task.delay(math.min(Number - 1, 12) * Step, function()
				if My ~= RefreshToken or not Row.Parent then return end
				Tween(Row, { BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				Tween(RowStroke, { Transparency = 0.6 }, Duration)
				Tween(TitleLabel, { TextTransparency = 0 }, Duration * 0.8)
				Tween(SubLabel, { TextTransparency = 0 }, Duration * 0.8)
				Tween(Bar, { Size = UDim2.fromOffset(4, 32) }, Duration, Enum.EasingStyle.Back)
			end)
		end
		Results.CanvasPosition = Vector2.new(0, 0)
	end

	ModalBox.GetPropertyChangedSignal(ModalBox, "Text").Connect(ModalBox.GetPropertyChangedSignal(ModalBox, "Text"), function()
		if Modal.Overlay.Visible then Refresh("type") end
	end)

	ModalBox.FocusLost.Connect(ModalBox.FocusLost, function(EnterPressed)
		if EnterPressed and Modal.Overlay.Visible and FirstEntry then
			GoTo(FirstEntry)
		end
	end)

	Modal.OnOpen = function()
		ModalBox.Text = ""
		Refresh("open")
	end
	Modal.OnOpened = function()
		task.defer(function()
			pcall(function() ModalBox.CaptureFocus(ModalBox) end)
		end)
	end
	Modal.OnClose = function()
		pcall(function() ModalBox.ReleaseFocus(ModalBox) end)
	end
	Modal.OnClosed = function()
		ModalBox.Text = ""
	end
end

WindowMeta.LoadConfigManager = WindowMeta.LoadConfigManger
WindowMeta.LoadSettingManager = WindowMeta.LoadSettingManger
WindowMeta.LoadSearchManager = WindowMeta.LoadSerachManger
WindowMeta.LoadSearchManger = WindowMeta.LoadSerachManger

local function ResetState()
	table.clear(Flags)
	table.clear(ControlBinds)
	table.clear(Index)
	table.clear(AccentBindings)
	table.clear(Tabs)
	table.clear(Modals)
	Theme.Accent, Theme.AccentLight, Theme.AccentDark = DefaultAccent[1], DefaultAccent[2], DefaultAccent[3]
	Current, LastCategory = nil, nil
	TabOrder, SideSlots = 0, 0
	OpenDropdown = nil
end

local function ResolveKey(Value)
	if typeof(Value) == "EnumItem" then return Value end
	if type(Value) == "string" then
		local Ok, Code = pcall(function() return Enum.KeyCode[Value] end)
		if Ok and Code then return Code end
	end
	return Enum.KeyCode.RightShift
end

function Library:CreateWindow(Config)
	Config = type(Config) == "table" and Config or {}

	if Library.Window then Library.Window:Destroy() end
	ResetState()

	local ShowWatermark = Config.ShowWaterMark
	if ShowWatermark == nil then ShowWatermark = Config.ShowWatermark end

	WindowConfig.Title = tostring(Config.Title or "Library")
	WindowConfig.Logo = Config.Logo or "moon"
	WindowConfig.Folder = tostring(Config.ConfigFolder or WindowConfig.Title)
	WindowConfig.ToggleKey = ResolveKey(Config.ToggleKey)

	Flags[WatermarkKey] = ShowWatermark ~= false

	pcall(function()
		local TargetGui = (gethui and gethui()) or CoreGui
		local Old = TargetGui.FindFirstChild(TargetGui, GuiName)
		if Old then Old.Destroy(Old) end
	end)

	Gui = New("ScreenGui", {
		Name = GuiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})

	local ok = pcall(function()
		Gui.Parent = (gethui and gethui()) or CoreGui
	end)
	if not ok or not Gui.Parent then
		Gui.Parent = Players.LocalPlayer.WaitForChild(Players.LocalPlayer, "PlayerGui")
	end

	Main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BaseWidth, BaseHeight),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Gui,
	})
	Corner(Main, 10)
	Gradient(Main, Theme.WindowTop, Theme.WindowBottom, 45)
	local MainStroke = Stroke(Main, Color3.new(1, 1, 1), 1, 0)
	Gradient(MainStroke, Theme.LineLight, Theme.Line, 90, 0.2, 0.7)

	Scale = New("UIScale", { Parent = Main })

	UpdateScale = function()
		local View = Gui.AbsoluteSize
		if View.X <= 0 or View.Y <= 0 then return end
		local UserMult = Flags["Settings/UIScale"] or 1
		Scale.Scale = math.clamp(math.min(View.X * 0.95 / BaseWidth, View.Y * 0.95 / BaseHeight) * UserMult, 0.1, 2)
	end
	UpdateScale()
	Gui.GetPropertyChangedSignal(Gui, "AbsoluteSize").Connect(Gui.GetPropertyChangedSignal(Gui, "AbsoluteSize"), UpdateScale)

	Content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(BaseWidth, BaseHeight),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local Divider = New("Frame", {
		Position = UDim2.fromOffset(SidebarWidth, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.LineLight,
		Parent = Main,
	})
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.12, 0.4),
			NumberSequenceKeypoint.new(0.88, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Divider,
	})

	Sidebar = New("Frame", {
		Size = UDim2.fromOffset(SidebarWidth, BaseHeight),
		BackgroundColor3 = Theme.SidebarBg,
		Parent = Main,
	})
	Corner(Sidebar, 10)
	New("Frame", {
		Position = UDim2.new(1, -16, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		BackgroundColor3 = Theme.SidebarBg,
		Parent = Sidebar,
	})
	New("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Line,
		Parent = Sidebar,
	})

	local Logo = New("Frame", {
		Position = UDim2.fromOffset(22, 18),
		Size = UDim2.fromOffset(206, 44),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})
	local LogoIcon = MakeAccentIcon(Logo, WindowConfig.Logo, 28)
	LogoIcon.Position = UDim2.fromOffset(0, 8)

	New("TextLabel", {
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Text = WindowConfig.Title,
		Font = Enum.Font.GothamMedium,
		TextSize = 24,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Logo,
	})

	local DragHandle = New("TextButton", {
		Size = UDim2.fromOffset(SidebarWidth, 76),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})

	local ItemsMask = New("Frame", {
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.fromOffset(SidebarWidth, 540),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Sidebar,
	})

	Items = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = ItemsMask,
	})
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Items })
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 2),
		Parent = Items,
	})

	BuildPicker()
	BuildNotify()
	BuildWatermark()

	local Dragging, DragStart, StartPosition = false, nil, nil
	DragHandle.InputBegan.Connect(DragHandle.InputBegan, function(Input)
		if IsPress(Input) then
			Dragging = true
			DragStart = Input.Position
			StartPosition = Main.Position
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if Dragging and IsMove(Input) then
			local Delta = Input.Position - DragStart
			local View = Gui.AbsoluteSize
			local CenterX = StartPosition.X.Scale * View.X + StartPosition.X.Offset + Delta.X
			local CenterY = StartPosition.Y.Scale * View.Y + StartPosition.Y.Offset + Delta.Y
			Main.Position = UDim2.fromOffset(
				math.clamp(CenterX, 0, View.X),
				math.clamp(CenterY, 0, View.Y)
			)
		end
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if IsPress(Input) then
			Dragging = false
		end
	end)

	local Toggler = New("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Gui,
	})
	Corner(Toggler, 12)
	Gradient(Toggler, Theme.CardTop, Theme.WindowBottom, 90)
	Stroke(Toggler, Theme.Line, 1)
	local TogglerIcon = MakeAccentIcon(Toggler, WindowConfig.Logo, 26)
	TogglerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	TogglerIcon.Position = UDim2.fromScale(0.5, 0.5)

	Toggler.Activated.Connect(Toggler.Activated, function()
		Main.Visible = not Main.Visible
	end)

	Connect(UserInputService.InputBegan, function(Input, Processed)
		if Input.KeyCode == Enum.KeyCode.Escape then
			for _, Modal in ipairs(Modals) do
				if Modal.Overlay.Visible then
					Modal.Close()
					return
				end
			end
			if ColorCatcher.Visible and not Processed then
				CloseColor()
			end
		elseif not Processed and Input.KeyCode == WindowConfig.ToggleKey then
			Main.Visible = not Main.Visible
		end
	end)

	local Window = setmetatable({ Flags = Flags, Gui = Gui, Main = Main }, WindowMeta)
	Library.Window = Window
	return Window
end

return Library
