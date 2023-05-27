local RenderstepTracker = {}

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local id = HttpService:GenerateGUID(false)
local mostRecentStep = 0

function RenderstepTracker.install()
	RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value + 1, function()
		mostRecentStep = tick()
	end)
end

function RenderstepTracker.uninstall()
	RunService:UnbindFromRenderStep(id)
end

function RenderstepTracker.recentlyStepped(): boolean
	local elapsed = tick() - mostRecentStep
	return elapsed < 0.2
end

return RenderstepTracker