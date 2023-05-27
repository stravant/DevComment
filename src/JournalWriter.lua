local JournalWriter = {}

local JournalShared = require(script.Parent.JournalShared)
local Version = require(script.Parent.Version)
local AccessList = require(script.Parent.AccessList)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "DevCommentAddToJournal"

function JournalWriter.journal(entry: table)
	local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
	remote:FireServer(entry)
end

type PathPart = {n: string, p: Vector3?}

local function hasSiblingsWithSameName(instance: Instance): boolean
	local parent = instance.Parent
	if not parent then
		return false
	end
	for _, child in parent:GetChildren() do
		if child.Name == instance.Name and child ~= instance then
			return true
		end
	end
	return false
end

local function getPath(current: Instance): {PathPart}
	local path = {}
	while current and current ~= workspace do
		if hasSiblingsWithSameName(current) then
			if current:IsA("PVInstance") then
				local currentPosition = current:GetPivot().Position
				local ancestorPV = current:FindFirstAncestorWhichIsA("PVInstance")
				local localPosition = ancestorPV:GetPivot():PointToObjectSpace(currentPosition)
				local encodedPosition = {localPosition.X, localPosition.Y, localPosition.Z}
				table.insert(path, 1, {n = current.Name, p = encodedPosition})
			else
				-- Same name siblings and not a PVInstance means we can't identify it
				return nil
			end
		else
			table.insert(path, 1, {n = current.Name})
		end
		current = current.Parent
	end
	return path
end

local addedThisSession = {}
function JournalWriter.handleAdded(comment: Instance)
	if not RunService:IsRunning() then
		return
	end

	local id = comment:GetAttribute("id")
	if addedThisSession[id] then
		return
	end
	addedThisSession[id] = true

	if Version.DEBUG_JOURNAL then
		print("Journaling add")
	end
	local position = comment:GetAttribute("position")
	JournalWriter.journal({
		action = "added",
		id = id,
		author = comment.Name,
		path = getPath(comment.Parent),
		position = if position then {position.X, position.Y, position.Z} else nil,
		time = comment:GetAttribute("time"),
		version = Version.PROTOCOL_VERSION,
	})
end

function JournalWriter.handleChange(comment: Instance)
	if not RunService:IsRunning() then
		return
	end

	if Version.DEBUG_JOURNAL then
		print("Journaling change")
	end
	JournalWriter.journal({
		action = "changed",
		id = comment:GetAttribute("id"),
		author = comment.Name,
		text = comment.Value,
		version = Version.PROTOCOL_VERSION,
	})
end

function JournalWriter.handleDelete(comment: Instance)
	if not RunService:IsRunning() then
		return
	end

	if Version.DEBUG_JOURNAL then
		print("Journaling delete")
	end
	JournalWriter.journal({
		action = "deleted",
		id = comment:GetAttribute("id"),
		version = Version.PROTOCOL_VERSION,
	})
end

function JournalWriter.clientCreateObjectComment(parent: Instance)
	ReplicatedStorage:WaitForChild(REMOTE_NAME):FireServer({
		action = "added",
		id = HttpService:GenerateGUID(),
		author = Players.LocalPlayer.Name,
		path = getPath(parent),
		time = os.time(),
		version = Version.PROTOCOL_VERSION,
	})
end

function JournalWriter.clientCreatePositionComment(position: Vector3)
	ReplicatedStorage:WaitForChild(REMOTE_NAME):FireServer({
		action = "added",
		id = HttpService:GenerateGUID(),
		author = Players.LocalPlayer.Name,
		path = getPath(workspace.Terrain),
		position = {position.X, position.Y, position.Z},
		time = os.time(),
		version = Version.PROTOCOL_VERSION,
	})
end

function JournalWriter.createRemote()
	local remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage
	remote.OnServerEvent:Connect(function(player: Player, entry: table)
		if not AccessList.hasAccess(player.UserId) then
			warn(`Player {player.Name} tried to add comment but is not allowed`)
			return
		end

		-- Apply the entry to the server too
		local applied = JournalShared.applyEntry(entry)
		if applied then
			--print(`Applied {entry.action} on server, journaling it`)
			local ds = JournalShared.getJournalDataStore()
			local id = ds:IncrementAsync(JournalShared.MostRecentEntryIdKey)
			ds:SetAsync(tostring(id), entry)
		else
			--print(`{entry.action} not applied on server, discarded`)
		end
	end)
end

return JournalWriter