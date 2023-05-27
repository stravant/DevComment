# DevComment

Add, edit, and remove comments on 3d space objects in a Roblox place in Edit, testing, or even in a live game, and have them reflected back to your editing sessions.

<img>DevForumSplash.png</img>

Plugin in Roblox marketplace: https://create.roblox.com/marketplace/asset/13437876391/Stravant-DevComment

DevForum discussion thread: https://devforum.roblox.com/t/stravant-devcomment-sync-3d-space-comments-between-edit-test-and-live-games/2394717

# Structure

## Hot reloader

`loader.server.lua` exists to allow live-editing reloading of the plugin as you edit it in VSCode. If DEVELOPMENT is set to true in `loader.server.lua`, then the plugin will be reloaded every time you save a file as long as you're serving the plugin via debug.project.json. This is done by having the main entry point of the plugin actually be the "main" ModuleScript, which can be reloaded by the loader script. A mock plugin is passed in whose Unloading is fired when the plugin is reloaded.

## RuntimeElements

The SetupDialog module contains a RuntimeElements list, which is a list of the elements are needed to drive runtime viewing adding, and editing of comments. Most of the modules are shared between runtime and edit time usage, and those are the ones recorded in the list. When creating the DevComment runtime folder to insert into the place, the modules contained in the list are copied into that folder from the plugin itself.
