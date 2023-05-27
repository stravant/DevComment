local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

return function(author: string, id: string)
	local comment = Instance.new("StringValue")
	CollectionService:AddTag(comment, "Comment")
	comment.Value = "<write comment here>"
	comment.Name = author
	comment:SetAttribute("id", id or HttpService:GenerateGUID())
	comment:SetAttribute("time", os.time())
	return comment
end