local ENT = {
	Base 				  = "base_ai",
	Type 				  = "ai",
	PrintName 			  = "QuestGiver",
	Author 				  = "Earu",
	Contact 			  = "",
	Purpose 			  = "Daily quests for everyone!",
	Instructions 		  = "",
	ms_notouch 		 	  = true,
	IsMSNPC 			  = true,
	RenderGroup			  = RENDERGROUP_BOTH,
	AutomaticFrameAdvance = true,
	Spawnable 			  = false,
}

ENT.Initialize = function(self)
	self:SetModel("models/odessa.mdl")

	if SERVER then
		self:SetHealth(1000)
		self:SetHullType(HULL_HUMAN)
		self:SetHullSizeNormal()
		self:SetSolid(SOLID_BBOX)
		self:SetMoveType(MOVETYPE_STEP)
		self:CapabilitiesAdd(bit.bor(CAP_USE,CAP_ANIMATEDFACE,CAP_TURN_HEAD))
		self:AddEFlags(EFL_NO_DISSOLVE)
		self:SetUseType(SIMPLE_USE)
		timer.Simple(0,function()
			self:StartActivity(ACT_IDLE)
		end)
	end
end

ENT.GetGender = function(self)
	self.__gender = self.__gender or (self:GetModel():lower():find("female",1,true)
		or self:GetModel():lower():find("alyx",1,true))
		and "female" or "male"
	return self.__gender
end

if SERVER then
	util.AddNetworkString("QuestOpenMenu")

	ENT.AcceptInput = function(self,event,activator,caller)
		if Quest then
			local quest = Quest.ActiveQuest
			if event == "Use" then
				local isblacklisted = quest.Blacklist[caller:SteamID()] ~= nil 
				local isongoing = quest.Players[caller] ~= nil
					and quest.Blacklist[caller:SteamID()] or false
				local tasks = {}
				for _,v in ipairs(quest.Tasks) do
					table.insert(tasks, { Name = v.Description, IsFinished = v.Execute(caller) })
				end
				net.Start("QuestOpenMenu")
				net.WriteBool(isblacklisted)
				net.WriteBool(isongoing)
				net.WriteEntity(self)
				net.WriteString(quest.PrintName)
				net.WriteString(quest.Description)
				net.WriteTable(tasks)
				net.Send(caller)
			end
		end

	end

	ENT.PlaySound = function(self,sndtype,a,b,c)
		local now = RealTime()
		if (self.nexttalk or 0)>now then return false end

		local sound = sndtype

		self:EmitSound(sound,100,math.random(96,104))

		local dur = SoundDuration(sound)
		dur = dur and dur > 0 and dur or 0.3

		self.nexttalk = now + dur + 0.3
		return true
	end

	ENT.StopThat = function(self)
		local female = self:GetGender()=="female"
		if( female ) then
			self:PlaySound("vo/trainyard/female01/cit_hit0"..math.random(1, 3)..".wav")
			else
			self:PlaySound("vo/trainyard/male01/cit_hit0"..math.random(1, 3)..".wav")
		end
	end

	ENT.OnTakeDamage = function(self,dmg)
		local v = dmg:GetAttacker()
		local mdl = self:GetModel()

		self:StopThat()
		if self:IsOnFire() then
			self:Extinguish()
		end

		if not IsValid(v) then return end
		if not v:IsPlayer() then
			v = v.CPPIGetOwneer and v:CPPIGetOwner() or nil
			if not IsValid(v) or not v:IsPlayer() then
				return
			end
		end

		local id = v:UserID()..'pl_lua_npc_kill'
		if timer.Exists(id) then
			return
		end

		timer.Create(id,1,1, function()
			timer.Remove(id)
			if IsValid(v) and v:IsPlayer() then
				if v:Alive() then
					if v:IsValid() then
						v:EmitSound("ambient/explosions/explode_2.wav")
					end

					local weapon = v:GetActiveWeapon()
					weapon = IsValid(weapon) and weapon:GetClass() or nil
					local info = DamageInfo()
					info:SetInflictor(game.GetWorld())
					info:SetAttacker(self:IsValid() and self or v:IsValid() and v or game.GetWorld())
					info:SetDamage(v:Health())
					if not self:IsValid() then
						shoulddamage = true
					end
					v:TakeDamageInfo(info)

					local ent = v:GetRagdollEntity()

					if not IsValid(ent) then return end
					ent:SetName("dissolvemenao"..tostring(ent:EntIndex()))

					local e=ents.Create'env_entity_dissolver'
					e:SetKeyValue("target","dissolvemenao"..tostring(ent:EntIndex()))
					e:SetKeyValue("dissolvetype","1")
					e:Spawn()
					e:Activate()
					e:Fire("Dissolve",ent:GetName(),0)
					SafeRemoveEntityDelayed(e,0.1)
					if self:IsValid() then
						if MetAchievements and MetaWorks.FireEvent then MetaWorks.FireEvent("ms_npcdissolve", v, self, weapon) end
					end
				end
			end
		end)

	end

	ENT.RunBehaviour = function(self)
	end
end

if CLIENT then

	ENT.Draw = function(self)
		self:DrawModel()
	end
	
	ENT.OnReceivedMenu = function(self,name,desc,tasks)
		self.Panel = vgui.Create("QuestMainPanel")
		self.Panel:Setup(self,name,desc,tasks)
	end

	net.Receive("QuestOpenMenu",function()
		local blacklisted = net.ReadBool()
		local ongoing = net.ReadBool()
		local ent = net.ReadEntity()
		local questname = net.ReadString()
		local questdesc = net.ReadString()
		local tasks = net.ReadTable()
		if Quest then
			if blacklisted then
				Quest.ShowDialog({"Sorry folk. I have no other quests for you today!",
				"Come back later!"})
			else
				if not ongoing then
					if not IsValid(ent.Panel) then
						ent:OnReceivedMenu(questname,questdesc,tasks)
					end
				else
					Quest.ShowDialog({"Hey there, you are not even done with your current quest!",
					"Come back later when you are done!"})
				end
			end
		end
	end)

end

scripted_ents.Register(ENT,"lua_npc_quest")