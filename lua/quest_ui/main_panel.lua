if CLIENT then
	local tag = "QuestGUI"

	surface.CreateFont(tag .. "Title", {
		font = "Roboto Bk",
		size = 26,
		weight = 800
	})
	surface.CreateFont(tag .. "Desc", {
		font = "Roboto",
		size = 20,
		weight = 500
	})

	local PANEL = {}
	PANEL.Width = 300
	PANEL.Height = 300

	function PANEL:Init()
		self:SetPos(0, 0)
		self:SetSize(0, 0)

		self.Alpha = 0
		self:NoClipping(false)

		self.Buttons = vgui.Create("EditablePanel", self)
		self.Buttons:Dock(BOTTOM)
		self.Buttons:SetTall(48)

		self.Confirm = vgui.Create("DButton", self.Buttons)
		self.Confirm:Dock(LEFT)
		self.Confirm:SetFont(tag .. "Title")
		self.Confirm:SetText("Turn in")
		self.Confirm.Paint = function(s, w, h)
			if s:IsHovered() then
				if s:IsDown() then
					s:SetTextColor(Color(64, 128, 64, 255))
				else
					s:SetTextColor(Color(64, 192, 64, 255))
				end
			else
				s:SetTextColor(Color(64, 164, 64, 225))
			end
		end
		self.Confirm.DoClick = function()
			net.Start("QuestAddPlayer")
			net.SendToServer()
			self:Close()
			Quest.ShowDialog({"Good luck!\nCome back when you are done."})
		end

		self.Cancel = vgui.Create("DButton", self.Buttons)
		self.Cancel:Dock(RIGHT)
		self.Cancel:SetFont(tag .. "Title")
		self.Cancel:SetText("Bye")
		self.Cancel.DoClick = function()
			self:Close()
		end
		self.Cancel.Paint = function(s, w, h)
			if s:IsHovered() then
				if s:IsDown() then
					s:SetTextColor(Color(128, 64, 64, 255))
				else
					s:SetTextColor(Color(192, 64, 64, 255))
				end
			else
				s:SetTextColor(Color(164, 64, 64, 225))
			end
		end

		self.Tasks = {}
	end

	function PANEL:PerformLayout()
		self.Confirm:SetWide(self:GetWide() * 0.5)
		self.Cancel:SetWide(self:GetWide() * 0.5)
	end

	local shadowDist = 3
	local function WordWrap(str, maxW)
		local strSep = str:Split(" ")
		local buf = ""
		local wBuf = 0
		for k, word in next, strSep do
			local txtW, txtH = surface.GetTextSize(word .. (k == #strSep and "" or " "))
			wBuf = wBuf + txtW
			if wBuf > maxW then
				buf = buf .. "\n"
				wBuf = 0
			end
			buf = buf .. word .. " "
		end

		return buf
	end
	function PANEL:Paint(w, h)
		if not IsValid(self.NPC) then return end

		local eyes = self.NPC:LookupAttachment("eyes")
		if not eyes then self:Remove() return end

		eyes = self.NPC:GetAttachment(eyes)
		if not LocalPlayer():IsLineOfSightClear(eyes.Pos) then self:Close() end
		if LocalPlayer():GetPos():Distance(eyes.Pos) > 164 then self:Close() end

		DisableClipping(true)
		surface.DisableClipping(true)

		surface.SetAlphaMultiplier(self.Alpha)
		draw.RoundedBox(0, shadowDist, shadowDist, w, h, Color(0, 0, 0, 192))
		draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 225))

		-- local x, y = self:GetPos()
		local triW, triH = 24, 16
		local tri = {
			{
				x = w,
				y = h * 0.5 - triH * 0.5
			},
			{
				x = w + triW,
				y = h * 0.5
			},
			{
				x = w,
				y = h * 0.5 + triH * 0.5
			}
		}
		local triShadow = table.Copy(tri)
		for _, vert in next, triShadow do
			vert.x = vert.x + shadowDist
			vert.y = vert.y + shadowDist
		end
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 192)
		surface.DrawPoly(triShadow)
		surface.SetDrawColor(40, 40, 40, 225)
		surface.DrawPoly(tri)

		surface.DisableClipping(false)
		DisableClipping(false)

		local x, y = 8, 12

		surface.SetFont(tag .. "Title")
		local txt = WordWrap(self.Quest, self:GetWide() - x * 2)
		local txtW, txtH = surface.GetTextSize(txt)
		draw.DrawText(txt, tag .. "Title", x, y, Color(194, 225, 128, 255))

		y = y + txtH + 8
		surface.SetFont(tag .. "Desc")
		local txt = WordWrap(self.Description, self:GetWide() - x * 2)
		local txtW, txtH = surface.GetTextSize(txt)
		draw.DrawText(txt, tag .. "Desc", x, y, Color(225, 225, 225, 255))

		-- ✔
		-- ✘
		y = y + txtH + 12
		x = x + 4
		for _, task in next, self.Tasks do
			local txt
			if task.IsFinished then
				txt = "✔"
				surface.SetTextColor(0, 192, 0, 225)
			else
				txt = "✘"
				surface.SetTextColor(192, 0, 0, 225)
			end
			surface.SetTextPos(x, y)
			surface.SetFont(tag .. "Desc")
			surface.DrawText(txt)

			x = x + 16 + 4
			surface.SetFont(tag .. "Desc")
			local txt = WordWrap(task.Name, self:GetWide() - x * 2)
			local txtW, txtH = surface.GetTextSize(txt)
			draw.DrawText(txt, tag .. "Desc", x, y, Color(225, 225, 225, 225))
			x = x - 16 - 4
			y = y + txtH + 4
		end
	end

	local animTime = 3
	function PANEL:Think()
		if not IsValid(self.NPC) then return end

		-- Reinventing the wheel because garry animations suck dick
		if self.Opening and not self.Closing then
			self:SetWide(Lerp(FrameTime() * animTime, self:GetWide(), self.Width))
			self:SetTall(Lerp(FrameTime() * animTime, self:GetTall(), self.Height))
			self.Alpha = Lerp(FrameTime() * animTime, self.Alpha, 1)
		elseif self.Closing then
			self:SetWide(Lerp(FrameTime() * animTime, self:GetWide(), 0))
			self:SetTall(Lerp(FrameTime() * animTime, self:GetTall(), 0))
			self.Alpha = Lerp(FrameTime() * animTime, self.Alpha, 0)

			if self.Alpha < 0.05 then
				self:Remove()
			end
		end

		local eyes = self.NPC:LookupAttachment("eyes")
		if not eyes then return end

		eyes = self.NPC:GetAttachment(eyes)
		local pos = eyes.Pos - eyes.Ang:Right() * -10
		local scrPos = pos:ToScreen()
		local x, y = scrPos.x, scrPos.y
		x = x - self:GetWide() - 16
		y = y - self:GetTall() * 0.5

		self:SetPos(x, y)
	end

	function PANEL:Setup(npc, quest, desc, tasks)
		self.NPC = npc
		self.Quest = quest
		self.Description = desc
		self.Tasks = tasks

		self:Open()
	end

	function PANEL:Open()
		-- self:MakePopup()
		gui.EnableScreenClicker(true)
		self:SetKeyboardInputEnabled(true)
		self:SetMouseInputEnabled(true)
		self.Opening = true
	end

	function PANEL:Close()
		gui.EnableScreenClicker(false)
		self:SetKeyboardInputEnabled(false)
		self:SetMouseInputEnabled(false)
		self.Closing = true
	end

	vgui.Register("QuestMainPanel", PANEL, "EditablePanel")
end

if SERVER then
	util.AddNetworkString("QuestAddPlayer")

	net.Receive("QuestAddPlayer",function(_,ply)
		if Quest then
			Quest.AddPlayer(Quest.ActiveQuest,ply)
		end
	end)
end