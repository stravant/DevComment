local JournalConsumer = {}
JournalConsumer.__index = JournalConsumer

local JournalShared = require(script.Parent.JournalShared)
local Version = require(script.Parent.Version)

local HasShownError = false
local IsOutOfDate = false

function JournalConsumer.new()
	local self = setmetatable({}, JournalConsumer)
	
	self._stepTask = task.spawn(function()
		while true do
			self:_step()
			task.wait(1)
		end
	end)

	return self
end

local function isTeamCreate()
	local client = game:FindFirstChild("NetworkClient")
	return client and #client:GetChildren() > 0
end

function JournalConsumer:_tryToTakeLock()
	-- Can't get the lock if I'm out of date
	if IsOutOfDate then
		return false
	end

	-- Get the lock folder
	if not self._lockFolder then
		self._lockFolder = workspace.Terrain:FindFirstChild("DevCommentLocks")
		if not self._lockFolder then
			self._lockFolder = Instance.new("Folder")
			self._lockFolder.Archivable = false
			self._lockFolder.Name = "DevCommentLocks"
			self._lockFolder.Parent = workspace.Terrain
		end
	end

	-- Look at the locks
	local bestLockValue = 0
	for _, lock in self._lockFolder:GetChildren() do
		-- Ignore stale locks
		if lock:GetAttribute("time") > os.time() - 10 then
			bestLockValue = math.max(bestLockValue, lock:GetAttribute("value"))
		end
	end

	-- Am I the best lock?
	if self._myLock and self._myLockValue == bestLockValue then
		-- Needs to have been at least three seconds since I created the lock
		-- before I try to do work so that it can replicate and different peers
		-- can acknowledge the value.
		return os.time() > self._createdMyLockAt + 3
	end

	if bestLockValue == 0 then
		-- I need to try becoming the lock holder
		if not self._myLock then
			local myLock = Instance.new("ObjectValue")
			myLock.Value = game.Players.LocalPlayer
			self._myLockValue = math.random()
			myLock:SetAttribute("value", self._myLockValue)
			local tm = os.time()
			myLock:SetAttribute("time", tm)
			myLock.Parent = self._lockFolder
			self._myLock = myLock
			self._createdMyLockAt = tm

			self._keepLockAlive = task.spawn(function()
				while true do
					if self._myLock then
						self._myLock:SetAttribute("time", os.time())
					end
					task.wait(2)
				end
			end)
		end

		-- Still return false in this case! We may have the best value, but
		-- someone else may be creating a lock at this moment. Allow enough time
		-- for locks to propagate before we start doing work.
		return false
	else
		-- Someone else is the lock holder
		return false
	end
end

function JournalConsumer:_releaseLock()
	self._myLock:Destroy()
	self._myLock = nil
	task.cancel(self._keepLockAlive)
	self._keepLockAlive = nil
end

function JournalConsumer:_doCheckForNewEntries()
	local mostRecentQuery = workspace:GetAttribute(JournalShared.MostRecentEntryAttribute)
	if not mostRecentQuery then
		mostRecentQuery = 0
	end
	local ds = JournalShared.getJournalDataStore()
	local st, err = pcall(function()
		local mostRecent = ds:GetAsync(JournalShared.MostRecentEntryIdKey) or 0
		if mostRecent > mostRecentQuery then
			for i = mostRecentQuery + 1, mostRecent do
				local entry = ds:GetAsync(tostring(i))
				if entry then
					if entry.version > Version.PROTOCOL_VERSION then
						IsOutOfDate = true
						warn("Other developers on your team have a more recent version of DevComment. Please update to the latest version to continue receiving comments from more recent versions.")
						self:_releaseLock()
						return
					end
					JournalShared.applyEntry(entry)
				else
					warn("DevComment error: Skipping missing journal entry " .. i)
				end
			end
			workspace:SetAttribute(JournalShared.MostRecentEntryAttribute, mostRecent)
		end
	end)
	if not st and not HasShownError then
		if err:find("Studio access to APIs is not allowed") then
			warn("DevComment: You must enable Studio access to DataStores for DevComment " ..
				"to pull comments made while testing or ingame: Turn on \"Enable Studio " ..
				"Access to API Services\" in Game Settings -> Security.")
		else
			warn("DevComment error: " .. err)
		end
		HasShownError = true
	end
end

function JournalConsumer:_step()
	-- Handle the step if either this is a local session, or it's a team
	-- create session and I have the lock on processing tho journal for this
	-- server.
	if not isTeamCreate() or self:_tryToTakeLock() then
		local curTime = os.time()
		local lastChecked = workspace:GetAttribute(JournalShared.MostRecentCheckTimeAttribute)
		if curTime > (lastChecked or 0) + 3 then
			workspace:SetAttribute(JournalShared.MostRecentCheckTimeAttribute, curTime)
			self:_doCheckForNewEntries()
		end
	end
end

function JournalConsumer:Destroy()
	-- Kill my lock
	if self._myLock then
		self._myLock:Destroy()
	end

	-- End the tasks
	task.cancel(self._stepTask)
	if self._keepLockAlive then
		task.cancel(self._keepLockAlive)
	end
end

return JournalConsumer