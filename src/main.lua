return function(plugin: Plugin)
	local createSharedToolbar = require(script.Parent.createSharedToolbar)
	local bind = require(script.Parent.bind)
	local Comment = require(script.Parent.Comment)
	local JournalConsumer = require(script.Parent.JournalConsumer)
	local SetupDialog = require(script.Parent.SetupDialog)
	local AccessList = require(script.Parent.AccessList)
	local RenderstepTracker = require(script.Parent.RenderstepTracker)
	local StudioCommentPlacer = require(script.Parent.StudioCommentPlacer)

	local StudioService = game:GetService("StudioService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")

	local onMainButtonClicked;

	-- Make CommentScreenGui under CoreGui
	local commentScreenGui = Instance.new("ScreenGui")
	commentScreenGui.Name = "CommentScreenGui"
	commentScreenGui.Parent = CoreGui
	commentScreenGui.ResetOnSpawn = false

	-- GeomTools toolbar sharing setup
	local sharedToolbarSettings = {}
	sharedToolbarSettings.CombinerName = "GeomToolsToolbar"
	sharedToolbarSettings.ToolbarName = "GeomTools"
	sharedToolbarSettings.ButtonName = "DevCmnt"
	sharedToolbarSettings.ButtonIcon = "rbxassetid://13517198920"
	sharedToolbarSettings.ButtonTooltip = "Add comments on parts, models, or at locations."
	sharedToolbarSettings.ClickedFn = function() onMainButtonClicked() end
	createSharedToolbar(plugin, sharedToolbarSettings)

	-- Add me as a commenter if I'm not there already
	AccessList.addAccess(StudioService:GetUserId())

	-- Spawn off a task looking for the username
	local loggedInUsername;
	task.spawn(function()
		loggedInUsername = Players:GetNameFromUserIdAsync(StudioService:GetUserId())
	end)

	local commentPlacer = StudioCommentPlacer.new(plugin, commentScreenGui)
	function onMainButtonClicked()
		sharedToolbarSettings.Button:SetActive(true)
		if commentPlacer:placeComment(loggedInUsername) then
			sharedToolbarSettings.Button:SetActive(false)
		end
	end
	local deactivationConnection = plugin.Deactivation:Connect(function()
		sharedToolbarSettings.Button:SetActive(false)
	end)

	-- If we need to insert a copy of the runtime, show the dialog requesting
	-- permission to do so (we need script injection permissions to do this)
	local setupDialog;
	if SetupDialog.needsSetup() then
		setupDialog = SetupDialog.new()
	end

	-- Consume the journal in edit mode
	local journalConsumer;
	if not RunService:IsRunning() then
		journalConsumer = JournalConsumer.new()
	end

	-- Bind the comment UI
	local unbindComment;
	if not RunService:IsRunning() then
		unbindComment = bind("Comment", Comment)
	end

	-- Track how recently a renderstep has happened
	-- (used to know whether the window is visible)
	RenderstepTracker.install()

	-- Handle teardown
	plugin.Unloading:Once(function()
		deactivationConnection:Disconnect()
		RenderstepTracker.uninstall()
		commentPlacer:Destroy()
		if unbindComment then
			unbindComment()
		end
		if journalConsumer then
			journalConsumer:Destroy()
		end
		commentScreenGui:Destroy()
		if setupDialog then
			setupDialog:Destroy()
		end
	end)
end