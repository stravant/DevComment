
local StudioCommentPlacer = {}
StudioCommentPlacer.__index = StudioCommentPlacer

local JournalWriter = require(script.Parent.JournalWriter)
local newComment = require(script.Parent.newComment)

local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

function StudioCommentPlacer.new(plugin, screen: ScreenGui)
	local self = setmetatable({
		_screen = screen,
		_plugin = plugin,
		_placing = false,
	}, StudioCommentPlacer)

	return self
end

-- Returns whether the comment was already placed
function StudioCommentPlacer:placeComment(username: string?): boolean
	self._username = username
	local object = Selection:Get()[1]
	if object and object:IsA("PVInstance") then
		self:_addComment(object, object:GetPivot().Position)
		return true
	else
		self:_begin()
		return false
	end
end

function StudioCommentPlacer:_addComment(instance: Instance, position: Vector3)
	-- Decide whether to do a positional comment or one on an object
	local targetPosition = instance:GetPivot().Position
	local dist = (targetPosition - position).Magnitude
	local radius = (0.5 * instance.Size.Magnitude)
	if radius > 30 or dist > 10 then
		-- We're too far from the object, just do a comment on the position
		if RunService:IsRunning() and RunService:IsClient() then
			-- Testing: Do it over network
			JournalWriter.clientCreatePositionComment(position)
		else
			-- Edit mode: Create comment directly
			local nc = newComment(self._username or "Anonymous")
			nc:SetAttribute("position", position)
			nc.Parent = workspace.Terrain
			ChangeHistoryService:SetWaypoint("Add comment at position")
		end
	else
		if RunService:IsRunning() and RunService:IsClient() then
			-- Testing: Do it over network
			JournalWriter.clientCreateObjectComment(instance)
		else
			-- Edit mode: Create comment directly
			local nc = newComment(self._username or "Anonymous")
			nc.Parent = instance
			ChangeHistoryService:SetWaypoint("Add comment on object")
		end
	end
end

function StudioCommentPlacer:_begin()
	self._placing = true

	self._plugin:Activate(true)
	local mouse = self._plugin:GetMouse() :: PluginMouse
	mouse.Icon = "rbxassetid://9524023207"

	local targetHighlight = Instance.new("Highlight")
	targetHighlight.OutlineColor = Color3.fromRGB(0, 162, 255)
	targetHighlight.OutlineTransparency = 0
	targetHighlight.FillTransparency = 1
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Parent = self._screen
	self._targetHighlight = targetHighlight

	self._releaseConnection = mouse.Button1Up:Connect(function()
		self:_click()
	end)
	self._moveConnection = mouse.Move:Connect(function()
		self:_update()
	end)
end

function StudioCommentPlacer:_getTarget(): (Instance?, Vector3?)
	local mouse = self._plugin:GetMouse()
	local target = mouse.Target
	if not target then
		return nil, nil
	end
	return target, mouse.Hit.Position
end

function StudioCommentPlacer:_update()
	self._plugin:GetMouse().Icon = "rbxasset://SystemCursors/Cross"
	local instance, position = self:_getTarget()
	if instance then
		self._targetHighlight.Adornee = instance
	else
		self._targetHighlight.Adornee = nil
	end
end

function StudioCommentPlacer:_click()
	local instance, position = self:_getTarget()
	if instance then
		self:_done()
		self:_addComment(instance, position)
	end
end

function StudioCommentPlacer:_done()
	self._placing = false

	self._plugin:GetMouse().Icon = ""
	self._plugin:Deactivate()

	self._targetHighlight:Destroy()
	self._releaseConnection:Disconnect()
	self._moveConnection:Disconnect()
end

function StudioCommentPlacer:Destroy()
	if self._placing then
		self:_done()
	end
end

return StudioCommentPlacer

