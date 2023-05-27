
local JournalShared = {}

local initialized = false

local DataStore;

local newComment = require(script.Parent.newComment)
local Version = require(script.Parent.Version)

local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

function JournalShared.getJournalDataStore(): DataStore
	if not initialized then
		local st, err = pcall(function()
			DataStore = DataStoreService:GetDataStore("DevCommentJournal", tostring(game.PlaceId))
		end)
		if not st then
			warn(`Access to API services has not been enabled, can't send comments back to place file: {err}`)
		end
		initialized = true
	end
	return DataStore
end

JournalShared.MostRecentCheckTimeAttribute = "_devCommentLastChecked"
JournalShared.MostRecentEntryAttribute = "_devCommentMostRecent"
JournalShared.MostRecentEntryIdKey = "MostRecent"

local function getFrame(instance: Instance)
	if instance:IsA("PVInstance") then
		return instance:GetPivot()
	else
		local ancestor = instance:FindFirstAncestorWhichIsA("PVInstance")
		if ancestor then
			return ancestor:GetPivot()
		else
			return nil
		end
	end
end

local function findChildWithNameAndOffset(parent: Instance, name: string, expectedOffset: Vector3)
	local closestOffset = math.huge
	local closestChild = nil
	local frame = getFrame(parent)
	for _, ch in parent:GetChildren() do
		if ch.Name == name and ch:IsA("PVInstance") then
			local localOffset = frame:PointToObjectSpace(ch:GetPivot().Position)
			local distance = (localOffset - expectedOffset).Magnitude
			if distance < closestOffset then
				closestOffset = distance
				closestChild = ch
			end
		end
	end
	return closestChild
end

local function resolvePath(path: table)
	local current = workspace
	for _, pathPart in path do
		if pathPart.p then
			local pos = pathPart.p
			local decodedLocalPos = Vector3.new(pos[1], pos[2], pos[3])
			current = findChildWithNameAndOffset(current, pathPart.n, decodedLocalPos)
		else
			current = current:FindFirstChild(pathPart.n)
		end
		if not current then
			break
		end
	end
	return current
end

function JournalShared.applyEntry(entry)
	local extistingCommentsById = {}
	for _, comment in CollectionService:GetTagged("Comment") do
		extistingCommentsById[comment:GetAttribute("id")] = comment
	end

	if Version.DEBUG_JOURNAL then
		print(`Consuming journal entry {entry.action}, id {entry.id}`)
	end
	if entry.action == "added" then
		if extistingCommentsById[entry.id] then
			if not RunService:IsRunning() then
				warn(`Tried to add already existing comment`)
			end
			return false
		end
		local comment = newComment(entry.author, entry.id)
		comment:SetAttribute("id", entry.id)
		comment:SetAttribute("time", entry.time)
		if entry.position then
			comment:SetAttribute("position",
				Vector3.new(entry.position[1], entry.position[2], entry.position[3]))
		end
		comment.Parent = resolvePath(entry.path)
	elseif entry.action == "changed" then
		local comment = extistingCommentsById[entry.id]
		if comment then
			if comment.Name == entry.author and comment.Value == entry.text then
				-- No warn because redundant edits are fine
				return false
			end
			comment.Name = entry.author
			comment.Value = entry.text
		else
			warn(`Couldn't find comment with id {entry.id} to update`)
		end
	elseif entry.action == "deleted" then
		local comment = extistingCommentsById[entry.id]
		if comment then
			comment:Destroy()
		else
			if not RunService:IsRunning() then
				warn(`Couldn't find comment with id {entry.id} to delete`)
			end
			return false
		end
	end
	return true
end

return JournalShared