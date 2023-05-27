---
-- @module MaidTaskUtils
-- @author Quenty

local MaidTaskUtils = {}

function MaidTaskUtils.isValidTask(job): boolean
	return type(job) == "function"
		or typeof(job) == "RBXScriptConnection"
		or type(job) == "table" and type(job.Destroy) == "function"
end

function MaidTaskUtils.doTask(job, key: any?): nil
	if type(job) == "function" then
		job()
	elseif typeof(job) == "RBXScriptConnection" then
		job:Disconnect()
	elseif typeof(job) == "Instance" then
		local function isDestroyed(x: any): boolean
			-- if x.Parent then return false end
			local _, result = pcall(function() x.Parent = x end)
			return result:match("locked") and true or false
		end
		if not isDestroyed(job) then
			pcall(function()
				job:Destroy()
			end)
		end
	elseif type(job) == "table" and type(job.Destroy) == "function" then
		job:Destroy()
	else
		print("Job info:", typeof(job))
		print("Key", key)
		if typeof(job) == "table" then
			for k, v in pairs(job) do
				print("\t"..tostring(k)..": "..tostring(v))
			end
		end
		error("Bad job")
	end
	return nil
end

function MaidTaskUtils.delayed(time, job): () -> nil
	assert(type(time) == "number", "Bad time")
	assert(MaidTaskUtils.isValidTask(job), "Bad job")

	return function()
		task.delay(time, function()
			MaidTaskUtils.doTask(job)
		end)
	end
end

return MaidTaskUtils