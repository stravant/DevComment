local Version = {}

Version.PROTOCOL_VERSION = 1
Version.RUNTIME_VERSION = 3
Version.DEBUG_JOURNAL = false

Version.UpdateLog = {
	[1] = {},
	[2] = {},
	[3] = {
		"Added support for hiding comments at runtime, using a button on mobile and Tab on desktop.",
		"Made the ingame comment widget a bit more compact.",
	},
}

return Version