local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Version = require(script.Parent.Version)

local SetupDialog = {}
SetupDialog.__index = SetupDialog

SetupDialog.DeclinedSetupAttribute = "DevCommentDeclinedSetup"

function SetupDialog.needsSetup()
	if not RunService:IsEdit() then
		return false
	end
	-- Is it a template?
	if game.CreatorId == 0 then
		return false
	end
	-- Do we have an existing up to date version?
	local existing = ReplicatedStorage:FindFirstChild("DevComment")
	if existing and existing:GetAttribute("Version") >= Version.RUNTIME_VERSION then
		return false
	end
	-- Did they already decline?
	local declined = ReplicatedStorage:GetAttribute(SetupDialog.DeclinedSetupAttribute)
	if declined then
		return false
	end
	return true
end

function SetupDialog.needsUpdate()
	local existing = ReplicatedStorage:FindFirstChild("DevComment")
	return existing and existing:GetAttribute("Version") < Version.RUNTIME_VERSION
end

local RuntimeElements = {
	"Version",
	"bind",
	"Comment",
	"JournalWriter",
	"JournalShared",
	"newComment",
	"AccessList",
	"RenderstepTracker",
	"AddCommentHud",
}

function SetupDialog.doSetup()
	-- Clear existing installs in ReplicatedStorage
	for _, child in ReplicatedStorage:GetChildren() do
		if child.Name == "DevComment" then
			child:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = "DevComment"
	folder:SetAttribute("Version", Version.RUNTIME_VERSION)

	-- Main elements
	for _, name in RuntimeElements do
		local element = script.Parent[name]:Clone()
		element.Parent = folder
	end

	-- Client and server runtime
	local clientRuntime = Instance.new("Script")
	clientRuntime.RunContext = Enum.RunContext.Client
	clientRuntime.Name = "clientMain"
	clientRuntime.Source = script.Parent.clientMain.Source
	clientRuntime.Parent = folder

	local serverRuntime = Instance.new("Script")
	serverRuntime.RunContext = Enum.RunContext.Server
	serverRuntime.Name = "serverMain"
	serverRuntime.Source = script.Parent.serverMain.Source
	serverRuntime.Parent = folder

	local st, err = pcall(function()
		folder.Parent = ReplicatedStorage
	end)
	return st
end

local Theme = settings().Studio.Theme
local BackgroundColor = Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
local BorderColor = Theme:GetColor(Enum.StudioStyleGuideColor.Border)
local TextColor = Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
local ButtonColor = Theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)

local MAIN_TEXT =
"Setup DevComment for this game? This will insert a runtime into ReplicatedStorage " ..
"which allows comments to be displayed, added, and edited in testing or in the " ..
"live game. The additions and changes will be replicated back to the next or current "..
"editing session via DataStores.\n\n" ..
"Developers who opened the place with the plugin installed will be able to see " ..
"and add comments. Additional testers who haven't can be manually be added."

local UPDATE_TEXT =
"Your DevComment runtime must be updated, do you want to update it now?"

local INJECTION_NOTE =
"Note: You will be asked for script injection permission if you haven't granted it yet."

function SetupDialog.new()
	local self = setmetatable({}, SetupDialog)

	local screen = Instance.new("ScreenGui")
	screen.Name = "DevCommentSetup"

	local vertical = Instance.new("Frame")
	vertical.AutomaticSize = Enum.AutomaticSize.Y
	vertical.BackgroundColor3 = BackgroundColor
	vertical.Parent = screen
	vertical.AnchorPoint = Vector2.new(0.5, 0.5)
	vertical.Position = UDim2.new(0.5, 0, 0.5, 0)
	vertical.Size = UDim2.new(0, 500, 0, 0)
	
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
	if SetupDialog.needsUpdate() then
		mainText.Text = UPDATE_TEXT
	else
		mainText.Text = MAIN_TEXT
	end
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

	local injectionText = Instance.new("TextLabel")
	injectionText.Name = "InjectionText"
	injectionText.Text = INJECTION_NOTE
	injectionText.Font = Enum.Font.Arial
	injectionText.TextColor3 = TextColor
	injectionText.BackgroundTransparency = 1
	injectionText.TextSize = 12
	injectionText.TextWrapped = true
	injectionText.TextXAlignment = Enum.TextXAlignment.Center
	injectionText.AutomaticSize = Enum.AutomaticSize.XY
	injectionText.LayoutOrder = 2
	injectionText.Parent = vertical
	self._injectionText = injectionText

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
	yesButton.Text = "Install"
	yesButton.LayoutOrder = 1
	yesButton.Parent = buttons
	yesButton.MouseButton1Click:Connect(function()
		self:_performSetup()
	end)
	self._yesButton = yesButton

	local noButton = makeButton()
	noButton.Name = "NoButton"
	noButton.Text = "No Thanks"
	noButton.LayoutOrder = 2
	noButton.Parent = buttons
	noButton.MouseButton1Click:Connect(function()
		self:_declineSetup()
	end)
	self._noButton = noButton

	screen.Parent = game:GetService("CoreGui")
	self._screen = screen

	return self
end

function SetupDialog:_requestPermission()
	self._mainText.Text = "Please grant script injection permission and then proceed."
	self._injectionText.Visible = false
	self._yesButton.Text = "Proceed"
	self._noButton.Visible = false
end

function SetupDialog:_performSetup()
	if SetupDialog.doSetup() then
		self._screen:Destroy()
	else
		self:_requestPermission()
	end
end

function SetupDialog:_declineSetup()
	ReplicatedStorage:SetAttribute(SetupDialog.DeclinedSetupAttribute, true)
	self._screen:Destroy()
end

function SetupDialog:Destroy()
	self._screen:Destroy()
end

return SetupDialog