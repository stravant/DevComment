local JournalWriter = require(script.Parent.JournalWriter)
local AccessList = require(script.Parent.AccessList)

-- Create remotes
JournalWriter.createRemote()
AccessList.createRemote()