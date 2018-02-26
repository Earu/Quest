
if SERVER then
	AddCSLuaFile("quest_core/main.lua")
	AddCSLuaFile("quest_core/loader.lua")
	AddCSLuaFile("quest_core/quest_npc.lua")
	AddCSLuaFile("quest_ui/main_panel.lua")
end

include("quest_core/main.lua")
include("quest_core/quest_npc.lua")
include("quest_ui/main_panel.lua")