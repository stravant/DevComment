local AccessList = {}

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ACCESS_LIST_NAME = "DevCommentAccessList"
local REMOTE_NAME = "DevCommentHasAccess"

function AccessList.clientQueryHasAccess(): boolean
	-- Client testing
	if Players.LocalPlayer.UserId <= 0 then
		return true
	end
	return ReplicatedStorage:FindFirstChild(REMOTE_NAME):InvokeServer()
end

function AccessList.hasAccess(userId: number): boolean
	local list = ServerStorage:FindFirstChild(ACCESS_LIST_NAME)
	return list:GetAttribute(tostring(userId)) == true
end

function AccessList.createRemote()
	local remote = Instance.new("RemoteFunction")
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage
	remote.OnServerInvoke = function(player: Player)
		return AccessList.hasAccess(player.UserId)
	end
end

function AccessList.addAccess(userId: number)
	local commenters = ServerStorage:FindFirstChild(ACCESS_LIST_NAME)
	if commenters then
		-- Remove duplicate copies of the commenters list (two copies of the plugin
		-- may add the list at the same time)
		for _, child in ServerStorage:GetChildren() do
			if child.Name == ACCESS_LIST_NAME and child ~= commenters then
				child.Parent = nil
			end
		end
	else
		commenters = Instance.new("Configuration")
		commenters.Name = ACCESS_LIST_NAME
		commenters.Parent = ServerStorage
	end

	if commenters:GetAttribute(tostring(userId)) == nil then
		commenters:SetAttribute(tostring(userId), true)
	end
end

return AccessList