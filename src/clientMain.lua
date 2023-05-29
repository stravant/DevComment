local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local bind = require(script.Parent.bind)
local Comment = require(script.Parent.Comment)
local AccessList = require(script.Parent.AccessList)
local RenderstepTracker = require(script.Parent.RenderstepTracker)
local AddCommentHud = require(script.Parent.AddCommentHud)

-- Don't show comments or let people comment if they don't have access
if not AccessList.clientQueryHasAccess() then
	return
end

-- Make CommentScreenGui under PlayerGui
local commentScreenGui = Instance.new("ScreenGui")
commentScreenGui.Name = "CommentScreenGui"
commentScreenGui.Parent = Players.LocalPlayer.PlayerGui
commentScreenGui.ResetOnSpawn = false

local unbind, addCommentHud;

local function teardown()
	unbind()
	unbind = nil
	RenderstepTracker.uninstall()
	addCommentHud:Destroy()
end

local function setup()
	-- Track rendersteps
	RenderstepTracker.install()

	-- Bind comments
	unbind = bind("Comment", Comment)

	-- Add the comment HUD
	addCommentHud = AddCommentHud.new(teardown)
end

-- Toggle visibility when the tab key is pressed
ContextActionService:BindAction("ToggleCommentVisibility", function()
	if unbind then
		teardown()
	else
		setup()
	end
end, false, Enum.KeyCode.Tab)

setup()
