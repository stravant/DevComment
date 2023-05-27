local CollectionService = game:GetService("CollectionService")

type Binding = {
	Destroy: (Binding) -> nil,
}

type Class = {
	new: (any...) -> Binding,
}

return function(tag: string, class: Class)
	local bindingMap = {}
	local ancestryMap = {}

	local function onTagged(instance: Instance, existing: boolean)
		local binding = class.new(instance, existing)
		bindingMap[instance] = binding
		task.defer(function()
			ancestryMap[instance] = instance.AncestryChanged:Connect(function(subject, parent)
				if parent:IsDescendantOf(game) then
					-- Recreate the binding under the new parent
					binding:Destroy()
					binding = class.new(instance, existing)
					bindingMap[instance] = binding
				else
					-- Nothing to do, the binding will be destroyed in this case already
					-- thanks to the CollectionService signal
				end
			end)
		end)
	end

	local removedCn = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		local binding = bindingMap[instance]
		if binding then
			binding:Destroy()
			bindingMap[instance] = nil
		end
		local connection = ancestryMap[instance]
		if connection then
			connection:Disconnect()
			ancestryMap[instance] = nil
		end
	end)
	
	local addedCn = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		onTagged(instance, false)
	end)
	for _, instance in CollectionService:GetTagged(tag) do
		onTagged(instance, true)
	end

	return function()
		for instance, binding in bindingMap do
			binding:Destroy()
			bindingMap[instance] = nil
		end
		for instance, connection in ancestryMap do
			connection:Disconnect()
			ancestryMap[instance] = nil
		end
		removedCn:Disconnect()
		addedCn:Disconnect()
	end
end