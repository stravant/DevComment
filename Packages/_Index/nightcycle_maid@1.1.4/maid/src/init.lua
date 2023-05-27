local Maid = require(script.Maid)
local MaidTaskUtils = require(script.MaidTaskUtils)

export type Maid = Maid.Maid

export type MaidConstructor = {
	isValidTask: (job: any) -> boolean,
	doTask: (job: any, key: any?) -> nil,
	delayed: (time: number, job: any) -> (()->nil),
	new: () -> Maid,
}

local interface: MaidConstructor = {
	isValidTask = MaidTaskUtils.isValidTask,
	doTask = MaidTaskUtils.doTask,
	delayed = MaidTaskUtils.delayed,
	new = Maid.new,
}

return interface