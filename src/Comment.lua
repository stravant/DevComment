local Comment = {}
Comment.__index = Comment

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CHS = game:GetService("ChangeHistoryService")

local RenderstepTracker = require(script.Parent.RenderstepTracker)

local function addWaypoint(name: string)
	if not RunService:IsRunning() then
		CHS:SetWaypoint(name)
	end
end

local JournalWriter = require(script.Parent.JournalWriter)

local GuiRoot;
if RunService:IsServer() then
	if RunService:IsStudio() then
		GuiRoot = game:GetService("CoreGui")
	else
		GuiRoot = nil
	end
else
	if RunService:IsRunning() then
		GuiRoot = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	else
		GuiRoot = game:GetService("CoreGui")
	end
end

local BackgroundColor, BorderColor, TextColor;
local ButtonColor = Color3.fromRGB(0, 116, 189)
if RunService:IsRunning() then
	BackgroundColor = Color3.fromRGB(40, 40, 40)
	BorderColor = Color3.fromRGB(0, 0, 0)
	TextColor = Color3.fromRGB(200, 200, 200)
else
	local Theme = settings().Studio.Theme
	BackgroundColor = Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	BorderColor = Theme:GetColor(Enum.StudioStyleGuideColor.Border)
	TextColor = Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
end

local EDIT_BUTTONS = {
	{
		name = "EditButton",
		icon = "rbxassetid://12088489240",
		color = ButtonColor,
	},
	{
		name = "DeleteButton",
		icon = "rbxassetid://8589294669", --"rbxassetid://6710235956",
		color =Color3.fromRGB(200, 0, 0),
	},
	-- {
	-- 	name = "ConfigureButton",
	-- 	icon = "rbxassetid://183390139",
	-- },
}
local function createBillboard(comment: StringValue, onClicked)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DebugBillboardGui"
	billboardGui.SizeOffset =  Vector2.new(0, 0.5)
	billboardGui.ExtentsOffset = Vector3.new(0, 1, 0)
	--billboardGui.AlwaysOnTop = true
	billboardGui.Brightness = 1.7
	billboardGui.StudsOffset = Vector3.new(0, 0, 0.01)
	billboardGui.Active = true

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 0.5, 0)
	background.Position = UDim2.new(0.5, 0, 1, 0)
	background.AnchorPoint = Vector2.new(0.5, 1)
	background.BackgroundTransparency = 0.15
	background.BorderSizePixel = 0
	background.BackgroundColor3 = BackgroundColor
	background.Parent = billboardGui

	local textBox = Instance.new("TextBox")
	textBox.TextEditable = false
	textBox.Name = "EditText"
	textBox.TextScaled = true
	textBox.TextSize = 32
	textBox.BackgroundTransparency = 1
	textBox.BorderSizePixel = 0
	textBox.TextColor3 = TextColor
	textBox.Size = UDim2.new(1, 0, 1, 0)
	textBox.Parent = background
	textBox.Font = Enum.Font.Arial
	textBox.ClearTextOnFocus = false
	textBox.Visible = false

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "CommentText"
	textLabel.TextScaled = true
	textLabel.TextSize = 32
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.TextColor3 = TextColor
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Parent = background
	textLabel.Font = Enum.Font.Arial

	textBox.FocusLost:Connect(function(enterPressed)
		if textBox.TextEditable then
			textBox.Visible = false
			onClicked("DoneButton")
		end
	end)

	local editFrame = Instance.new("Frame")
	editFrame.Active = true
	editFrame.Name = "EditFrame"
	editFrame.BackgroundColor3 = BackgroundColor
	editFrame.Position = UDim2.fromScale(1, 0)
	editFrame.AnchorPoint = Vector2.new(0, 1)

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Parent = editFrame
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local editCorner = Instance.new("UICorner")
	editCorner.CornerRadius = UDim.new(0.1, 0)
	editCorner.Parent = editFrame

	local editStroke = Instance.new("UIStroke")
	editStroke.Color = BorderColor
	editStroke.Thickness = 2
	editStroke.Parent = editFrame

	for i, button in EDIT_BUTTONS do
		local editButton = Instance.new("ImageButton")
		editButton.Name = button.name
		editButton.BackgroundTransparency = 1
		editButton.Image = button.icon
		CollectionService:AddTag(editButton, "EditButton")
		editButton.LayoutOrder = i
		editButton.Size = UDim2.fromScale(1 / #EDIT_BUTTONS, 1)
		editButton.Parent = editFrame
		editButton.ImageColor3 = button.color

		editButton.MouseButton1Click:Connect(function()
			onClicked(button.name)
		end)
	end

	local editAspect = Instance.new("UIAspectRatioConstraint")
	editAspect.AspectRatio = #EDIT_BUTTONS
	editAspect.Parent = editFrame

	editFrame.Parent = background

	local uiAspectRatio = Instance.new("UIAspectRatioConstraint")
	uiAspectRatio.Parent = background

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = background

	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = background

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = BorderColor
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = background
	uiStroke.Thickness = 2

	billboardGui.Size = UDim2.fromOffset(0, 0)
	billboardGui.Parent = GuiRoot.CommentScreenGui

	local position = comment:GetAttribute("position")
	if position then
		billboardGui.Adornee = workspace.Terrain
		billboardGui.ExtentsOffset = Vector3.zero
		billboardGui.StudsOffsetWorldSpace = position + Vector3.yAxis * 2
	else
		billboardGui.Adornee = comment.Parent
	end

	return billboardGui
end

local EDIT_FRAME_HEIGHT_STUDS = 2
local TEXT_HEIGHT_STUDS = 2.5
local PADDING_PERCENT_OF_LINE_HEIGHT = 0.3
local function updateText(billboard, comment: StringValue)
	local text = `{comment.Name}: {comment.Value}`

	local background = billboard.Background
	local editFrame = background.EditFrame
	local textLabel = background.CommentText :: TextLabel
	textLabel.Text = tostring(text)

	local contentText = textLabel.ContentText

	local textSize = TextService:GetTextSize(
		contentText,
		textLabel.TextSize,
		textLabel.Font,
		Vector2.new(650, 1e6))

	local lines = textSize.Y/textLabel.TextSize

	local paddingOffset = textLabel.TextSize*PADDING_PERCENT_OF_LINE_HEIGHT
	local paddedHeight = textSize.Y + 2*paddingOffset
	local paddedWidth = textSize.X + 2*paddingOffset
	local aspectRatio = paddedWidth / paddedHeight

	local uiAspectRatio = background.UIAspectRatioConstraint
	uiAspectRatio.AspectRatio = aspectRatio

	local uiPadding = background.UIPadding
	uiPadding.PaddingBottom = UDim.new(paddingOffset / paddedHeight, 0)
	uiPadding.PaddingTop = UDim.new(paddingOffset / paddedHeight, 0)
	uiPadding.PaddingLeft = UDim.new(paddingOffset / paddedWidth, 0)
	uiPadding.PaddingRight = UDim.new(paddingOffset / paddedWidth, 0)

	local uiCorner = background.UICorner
	uiCorner.CornerRadius = UDim.new(paddingOffset / paddedHeight / 2, 0)

	local height = lines*TEXT_HEIGHT_STUDS * TEXT_HEIGHT_STUDS*PADDING_PERCENT_OF_LINE_HEIGHT
	local width = height*aspectRatio

	billboard.Size = UDim2.new(width * 2, 0, height * 2, 0)

	local x = EDIT_FRAME_HEIGHT_STUDS / (width) * 2
	local y = EDIT_FRAME_HEIGHT_STUDS / (height)
	editFrame.Size = UDim2.fromScale(x, y)

	local position = comment:GetAttribute("position")
	if position then
		billboard.StudsOffsetWorldSpace = position + Vector3.yAxis * 2
	end
end

function Comment.new(comment: StringValue, existing: boolean)
	local self = setmetatable({
		_comment = comment
	}, Comment)

	-- See if there's an existing comment with the same ID, if there is, delete
	-- it to avoid duplicates due to ping-back when creating comments on the
	-- client.
	local existingComment;
	for _, existing in comment.Parent:GetChildren() do
		if existing ~= comment and existing:GetAttribute("id") == comment:GetAttribute("id") then
			existingComment = existing
			break
		end
	end
	if existingComment then
		existingComment:Destroy()
	end

	self._changedCn = comment.Changed:Connect(function()
		self:_onChanged()
	end)
	self._attributeCn = comment:GetAttributeChangedSignal("position"):Connect(function()
		self:_onChanged()
	end)

	self._billboard = createBillboard(comment, function(action)
		if action == "EditButton" then
			self:_beginEdit()
		elseif action == "DeleteButton" then
			self:_delete()
		elseif action == "ConfigureButton" then
			self:_configure()
		elseif action == "DoneButton" then
			self:_doneEdit(false)
		end
	end)
	self._background = self._billboard.Background
	updateText(self._billboard, comment)
	
	-- Notify journal
	if not existing and RunService:IsRunning() then
		JournalWriter.handleAdded(comment)
	end

	-- If I added it, edit right away
	local localPlayer = Players.LocalPlayer
	if not existing and (not localPlayer or (localPlayer and comment.Name == localPlayer.Name)) then
		-- Only begin the edit if they're looking at this view
		if RenderstepTracker.recentlyStepped() then
			self:_beginEdit()
		end
	end

	return self
end

function Comment:_beginEdit()
	local label: TextLabel = self._background.CommentText
	local editor: TextBox = self._background.EditText
	if editor.TextEditable then
		return
	end
	label.Visible = false
	editor.Visible = true

	-- Handle touch
	self._touchKeyboardCn = UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
		if UserInputService.OnScreenKeyboardVisible and not self._touchEditingScreen then
			local touchEditingScreen = Instance.new("ScreenGui")
			touchEditingScreen.Name = "DevCommentTouchEditor"
			touchEditingScreen.ResetOnSpawn = false
			--touchEditingScreen.IgnoreGuiInset = true
			
			local frame = Instance.new("Frame")
			frame.Name = "TouchEditingFrame"
			frame.Size = UDim2.fromScale(0.9, 0.4)
			frame.Position = UDim2.fromScale(0.5, 0)
			frame.AnchorPoint = Vector2.new(0.5, 0)
			frame.Parent = touchEditingScreen
			frame.BackgroundTransparency = 1

			local padding = Instance.new("UIPadding")
			padding.Parent = frame
			padding.PaddingTop = UDim.new(0, 10)
			
			local touchEditor = Instance.new("TextBox")
			touchEditor.Name = "TouchEditor"
			touchEditor.TextColor3 = TextColor
			touchEditor.BackgroundColor3 = BackgroundColor
			touchEditor.BackgroundTransparency = 0.15
			touchEditor.TextEditable = true
			touchEditor.Text = ""
			touchEditor.Font = Enum.Font.Arial
			touchEditor.TextSize = 28
			touchEditor.MultiLine = false
			touchEditor.PlaceholderText = "Enter comment..."
			touchEditor.Size = UDim2.fromScale(1, 0)
			touchEditor.Position = UDim2.fromScale(0, 0)
			touchEditor.AutomaticSize = Enum.AutomaticSize.Y
			touchEditor.Parent = frame

			local stroke = Instance.new("UIStroke")
			stroke.Color = BorderColor
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = touchEditor
			stroke.Thickness = 2

			local padding = Instance.new("UIPadding")
			padding.Parent = touchEditor
			padding.PaddingLeft = UDim.new(0, 10)
			padding.PaddingRight = UDim.new(0, 10)
			padding.PaddingTop = UDim.new(0, 20)
			padding.PaddingBottom = UDim.new(0, 20)

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.05, 0)
			corner.Parent = touchEditor
			
			touchEditor.FocusLost:Connect(function()
				self:_doneEdit(true)
			end)
			
			touchEditingScreen.Parent = GuiRoot
			self._touchEditingScreen = touchEditingScreen

			label.Visible = true
			editor.Visible = false

			touchEditor:CaptureFocus()
		end
	end)

	-- Make the text editable
	editor.TextEditable = true
	editor:CaptureFocus()
	editor.Text = ""

	self._cancelOnChange = self._comment.Changed:Connect(function()
		self:_doneEdit()
	end)
end

function Comment:_doneEdit(fromKeyboard)
	-- Swapped to onscreen keyboard, don't care about the defocus of the main
	-- comment textbox.
	if self._touchEditingScreen and not fromKeyboard then
		return
	end

	self._touchKeyboardCn:Disconnect()
	self._cancelOnChange:Disconnect()
	
	-- Make the text uneditable
	local label: TextLabel = self._background.CommentText
	local editor: TextBox = self._background.EditText

	-- If we were touch editing put the billboard back where it belongs
	local finalText;
	if self._touchEditingScreen then
		finalText = self._touchEditingScreen.TouchEditingFrame.TouchEditor.Text
		self._touchEditingScreen:Destroy()
		self._touchEditingScreen = nil
	else
		finalText = editor.Text
	end

	label.Visible = true
	editor.Visible = false

	editor.TextEditable = false
	if finalText == "" then
		-- Update text back to original
		updateText(self._billboard, self._comment)
	else
		self._comment.Value = finalText
		addWaypoint("Edited comment")
	end
end

function Comment:_delete()
	JournalWriter.handleDelete(self._comment)
	self._comment.Parent = nil
	addWaypoint("Delete comment")
end

function Comment:_configure()
	-- TODO:
end

function Comment:_onChanged()
	updateText(self._billboard, self._comment)

	-- Notify journal
	JournalWriter.handleChange(self._comment)
end

function Comment:Destroy()
	self._changedCn:Disconnect()
	self._attributeCn:Disconnect()
	self._billboard:Destroy()
end

return Comment
