-- Define a class which shows a UI the user can use to add comments ingame.

local AddCommentHud = {}
AddCommentHud.__index = AddCommentHud

local JournalWriter = require(script.Parent.JournalWriter)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BackgroundColor, BorderColor, TextColor, ButtonColor;
BackgroundColor = Color3.fromRGB(40, 40, 40)
BorderColor = Color3.fromRGB(0, 0, 0)
TextColor = Color3.fromRGB(200, 200, 200)
ButtonColor = Color3.fromRGB(0, 162, 255)

local MAIN_TEXT = "DevComment"
local CANCEL_TEXT = "Click on something to comment on it..."

function AddCommentHud.new()
	local self = setmetatable({}, AddCommentHud)

	local screen = Instance.new("ScreenGui")
	screen.Name = "DevCommentHud"

	local vertical = Instance.new("Frame")
	vertical.AutomaticSize = Enum.AutomaticSize.XY
	vertical.BackgroundColor3 = BackgroundColor
	vertical.Parent = screen
	vertical.AnchorPoint = Vector2.new(1, 0.5)
	vertical.Position = UDim2.new(1, -20, 0.35, 0)
	--vertical.Size = UDim2.new(0, 200, 0, 0)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = BorderColor
	stroke.Thickness = 1
	stroke.Parent = vertical

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 10)
	padding.Parent = vertical

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = vertical

	local mainText = Instance.new("TextLabel")
	mainText.Name = "MainText"
	mainText.Text = MAIN_TEXT
	mainText.Font = Enum.Font.Arial
	mainText.TextColor3 = TextColor
	mainText.BackgroundTransparency = 1
	mainText.TextSize = 16
	mainText.TextWrapped = true
	mainText.TextXAlignment = Enum.TextXAlignment.Left
	mainText.AutomaticSize = Enum.AutomaticSize.XY
	mainText.LayoutOrder = 1
	mainText.Parent = vertical
	self._mainText = mainText

	local buttons = Instance.new("Frame")
	buttons.Name = "ButtonList"
	buttons.BackgroundTransparency = 1
	buttons.AutomaticSize = Enum.AutomaticSize.XY
	buttons.LayoutOrder = 3
	buttons.Parent = vertical

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Padding = UDim.new(0, 10)
	buttonLayout.Parent = buttons

	local function makeButton()
		local button = Instance.new("TextButton")
		button.TextSize = 16
		button.TextColor3 = TextColor
		button.Font = Enum.Font.Arial
		button.BackgroundColor3 = ButtonColor
		button.AutomaticSize = Enum.AutomaticSize.XY

		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 8)
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.PaddingTop = UDim.new(0, 8)
		padding.Parent = button

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button

		return button
	end
	
	local yesButton = makeButton()
	yesButton.Name = "YesButton"
	yesButton.Text = "Add Comment"
	yesButton.LayoutOrder = 1
	yesButton.Parent = buttons
	yesButton.MouseButton1Click:Connect(function()
		-- Defer needed so that the mouse up we connect in beginAdding doesn't
		-- catch the same mouse up that the mouse up we're responding to here
		task.defer(function()
			self:_beginAdding()
		end)
	end)
	self._yesButton = yesButton

	local cancelButton = makeButton()
	cancelButton.Name = "CancelButton"
	cancelButton.Text = "Cancel"
	cancelButton.LayoutOrder = 2
	cancelButton.Parent = buttons
	cancelButton.Visible = false
	cancelButton.MouseButton1Click:Connect(function()
		self:_doneAdding()
	end)
	self._cancelButton = cancelButton

	screen.Parent = Players.LocalPlayer.PlayerGui
	self._screen = screen

	return self
end

function AddCommentHud:_beginAdding()
	self._adding = true
	self._mainText.Text = CANCEL_TEXT
	self._yesButton.Visible = false
	self._cancelButton.Visible = true

	local targetHighlight = Instance.new("Highlight")
	targetHighlight.OutlineColor = Color3.fromRGB(0, 162, 255)
	targetHighlight.OutlineTransparency = 0
	targetHighlight.FillTransparency = 1
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Parent = self._screen
	self._targetHighlight = targetHighlight

	self._releaseConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
			self:_click()
		end
	end)
	self._moveConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or
			input.UserInputType == Enum.UserInputType.Touch then
			self:_update()
		end
	end)

	self._oldIcon = UserInputService.MouseIcon
	UserInputService.MouseIcon = "rbxassetid://9524023207"
end

function AddCommentHud:_doneAdding()
	self._adding = false
	self._mainText.Text = MAIN_TEXT
	self._yesButton.Visible = true
	self._cancelButton.Visible = false

	self._targetHighlight:Destroy()

	self._releaseConnection:Disconnect()
	self._moveConnection:Disconnect()

	UserInputService.MouseIcon = self._oldIcon
end

function AddCommentHud:_getTarget(): (Instance?, Vector3?)
	local mouse = Players.LocalPlayer:GetMouse()
	local target = mouse.Target
	if not target then
		return nil, nil
	end
	return target, mouse.Hit.Position
end

function AddCommentHud:_update()
	local instance, position = self:_getTarget()
	if instance then
		self._targetHighlight.Adornee = instance
	else
		self._targetHighlight.Adornee = nil
	end
end

function AddCommentHud:_click()
	local instance, position = self:_getTarget()
	if instance then
		self:_doneAdding()
		self:_addComment(instance, position)
	end
end

function AddCommentHud:_addComment(instance: Instance, position: Vector3)
	-- Decide whether to do a positional comment or one on an object
	local targetPosition = instance:GetPivot().Position
	local dist = (targetPosition - position).Magnitude
	local radius = (0.5 * instance.Size.Magnitude)
	if radius > 30 or dist > 10 then
		-- We're too far from the object, just do a comment on the position
		JournalWriter.clientCreatePositionComment(position)
	else
		JournalWriter.clientCreateObjectComment(instance)
	end
end

function AddCommentHud:Destroy()
	if self._adding then
		self:_doneAdding()
	end
	self._screen:Destroy()
end


return AddCommentHud