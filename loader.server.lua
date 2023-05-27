local DEVELOPMENT = false

-- When not in development, just directly run the plugin
if not DEVELOPMENT then
	require(script.Parent.Src.main)(plugin)
	return
end

-- Otherwise, mock the plugin to allow reloading...

local Signal = require(script.Parent.Packages.Signal)
local Maid = require(script.Parent.Packages.Maid)

local MockToolbars = {}

local function makeMockToolbar(name)
	local mockToolbar = setmetatable({
		_instance = plugin:CreateToolbar(name),
		Buttons = {},
		CreateButton = function(self, id, tooltip, icon, text)
			local button = self.Buttons[id]
			if not button then
				button = self._instance:CreateButton(id, tooltip, icon, text)
				self.Buttons[id] = button
			end
			return button
		end,
	}, {
		__index = function(self, key)
			return self._instance[key]
		end,
		__newindex = function(self, key, value)
			self._instance[key] = value
		end,
	})
	return mockToolbar
end

local MockPlugin = setmetatable({
	_instance = plugin,
	Unloading = Signal.new(),
	CreateToolbar = function(self, name)
		local mockToolbar = MockToolbars[name]
		if not mockToolbar then
			mockToolbar = makeMockToolbar(name)
			MockToolbars[name] = mockToolbar
		end
		return mockToolbar
	end,
	GetMouse = function(self)
		return plugin:GetMouse()
	end,
}, {
	__index = function(self, key)
		return plugin[key]
	end,
	__newindex = function(self, key, value)
		plugin[key] = value
	end,
})

local originalSrc = script.Parent.Src
local originalPackages = script.Parent.Packages
local currentContainer;
local loading = false

local function unload()
	loading = true
	if currentContainer then
		MockPlugin.Unloading:Fire()
		currentContainer:Destroy()
		currentContainer = nil
	end
	loading = false
end

local function load()
	loading = true
	currentContainer = Instance.new("Folder")
	currentContainer.Name = "MockPlugin"
	currentContainer.Archivable = false
	originalSrc:Clone().Parent = currentContainer
	originalPackages:Clone().Parent = currentContainer
	require(currentContainer.Src.main)(MockPlugin)
	loading = false
end

local function reload()
	print("Reload...")
	unload()
	load()
end

local unloadingMaid = Maid.new()
unloadingMaid:GiveTask(unload)

-- Deferred reloading task
local reloadTask;
local function queueReload()
	if not reloadTask then
		reloadTask = task.delay(0.5, function()
			reloadTask = nil
			reload()
		end)
	end
end
unloadingMaid:GiveTask(script.Parent.DescendantRemoving:Connect(function(desc)
	if reloadTask then
		task.cancel(reloadTask)
	end
end))

-- Listen for any descendants being added / removed / changing
for _, desc in script.Parent:GetDescendants() do
	unloadingMaid:GiveTask(desc.Changed:Connect(function()
		if not loading then
			queueReload()
		end
	end))
end
script.Parent.DescendantAdded:Connect(function(desc)
	if not loading then
		queueReload()
		unloadingMaid:GiveTask(desc.Changed:Connect(function()
			if not loading then
				queueReload()
			end
		end))
	end
end)
script.Parent.DescendantRemoving:Connect(function(desc)
	if not loading then
		queueReload()
	end
end)

plugin.Unloading:Connect(function()
	unloadingMaid:Destroy()
end)

local ReloadToolbar = plugin:CreateToolbar("Reload")
local ReloadButton = ReloadToolbar:CreateButton("Reload", "Reload", "", "Reload")
ReloadButton.Click:Connect(reload)

load()