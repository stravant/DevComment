local Players = game:GetService("Players")

local bind = require(script.Parent.bind)
local Comment = require(script.Parent.Comment)
local AccessList = require(script.Parent.AccessList)
local RenderstepTracker = require(script.Parent.RenderstepTracker)
local AddCommentHud = require(script.Parent.AddCommentHud)

-- Don't show comments or let people comment if they don't have access
if not AccessList.clientQueryHasAccess() then
	return
end

-- Track rendersteps
RenderstepTracker.install()

-- Make CommentScreenGui under PlayerGui
local commentScreenGui = Instance.new("ScreenGui")
commentScreenGui.Name = "CommentScreenGui"
commentScreenGui.Parent = Players.LocalPlayer.PlayerGui
commentScreenGui.ResetOnSpawn = false

-- Add the comment HUD
AddCommentHud.new()

-- Bind comments
bind("Comment", Comment)