--!strict
---	Manages the cleaning of events and other things.
-- Useful for encapsulating state and make deconstructors easy
-- @classmod Maid
-- @see Signal
export type Maid = {
	isMaid: (any) -> boolean,
	new: () -> Maid,
	_tasks: {[number]: any},
	bind: (inst: Instance) -> Maid,
	[any]: any?,
	_GiveTask: <T>(self: Maid, task: T) -> number,
	GiveTask: <T>(self: Maid, task: T) -> T,
	GivePromise: (self: Maid, any) -> nil,
	DoCleaning: (self:Maid) -> nil,
	Destroy: (self: Maid) -> nil,
	ClassName: "Maid",
}

local Maid: Maid = {} :: any
Maid.ClassName = "Maid"

local MaidTaskUtils = require(script.Parent.MaidTaskUtils)



--- Returns a new Maid object
-- @constructor Maid.new()
-- @treturn Maid
function Maid.new(): Maid
	local self:{[any]: any?} = {
		_tasks = {}
	}
	local s: any = setmetatable(self, Maid)
	return s
end

function Maid.bind(inst: Instance): Maid
	local maid = Maid.new()
	maid:GiveTask(inst.Destroying:Connect(function()
		maid:Destroy()
	end))
	return maid
end

function Maid.isMaid(value)
	return type(value) == "table" and value.ClassName == "Maid"
end

--- Returns Maid[key] if not part of Maid metatable
-- @return Maid[key] value
function Maid:__index(index)
	if Maid[index] then
		return Maid[index]
	else
		return self._tasks[index]
	end
end

--- Add a task to clean up. Tasks given to a maid will be cleaned when
--  maid[index] is set to a different value.
-- @usage
-- Maid[key] = (function)         Adds a task to perform
-- Maid[key] = (event connection) Manages an event connection
-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
--                                it is destroyed.
function Maid:__newindex(index, newTask)
	if Maid[index] ~= nil then
		error(("'%s' is reserved"):format(tostring(index)), 2)
	end

	local tasks = self._tasks
	local oldTask = tasks[index]

	if oldTask == newTask then
		return
	end

	tasks[index] = newTask

	if oldTask then
		MaidTaskUtils.doTask(oldTask, index)
		-- if type(oldTask) == "function" then
		-- 	oldTask()
		-- elseif typeof(oldTask) == "RBXScriptConnection" then
		-- 	oldTask:Disconnect()
		-- elseif oldTask.Destroy then
		-- 	oldTask:Destroy()
		-- end
	end
end

--- Same as indexing, but uses an incremented number as a key.
-- @param task An item to clean
-- @treturn number taskId
function Maid:_GiveTask<T>(task: T)
	if not task then
		error("Task cannot be false or nil", 2)
	end

	local taskId = #self._tasks+1
	self[taskId] = task

	if type(task) == "table" and (not task.Destroy) then
		warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
	end

	return taskId
end

function Maid:GiveTask<T>(task: T): T
	self:_GiveTask(task)
	return task
end

function Maid:GivePromise(promise)
	if not promise:IsPending() then
		return promise
	end

	local newPromise = promise.resolved(promise)
	local id = self:_GiveTask(newPromise)
	

	-- Ensure GC
	newPromise:Finally(function()
		self[id] = nil
	end)

	return newPromise
end

--- Cleans up all tasks.
-- @alias Destroy
function Maid:DoCleaning()
	local tasks = self._tasks

	-- Disconnect all events first as we know this is safe
	for index, job in pairs(tasks) do
		if typeof(job) == "RBXScriptConnection" then
			tasks[index] = nil
			job:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
	local index, job = next(tasks)
	while job ~= nil do
		if index ~= nil then
			tasks[index] = nil
		end
		MaidTaskUtils.doTask(job, index)
		-- if type(job) == "function" then
		-- 	job()
		-- elseif typeof(job) == "RBXScriptConnection" then
		-- 	job:Disconnect()
		-- elseif job.Destroy then
		-- 	job:Destroy()
		-- end
		index, job = next(tasks)
	end
	return nil
end


--- Alias for DoCleaning()
-- @function Destroy
Maid.Destroy = Maid.DoCleaning

return Maid
