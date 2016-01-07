-----------------------------------------------------------------------------------------------------
-- QuickDrawTracker
--- © 2015 Vim Exe @ Jabbit (vicious owes me a hundred hookers)
--
--- QuickDrawTracker is free software, all files licensed under the GPLv3. See LICENSE for details.

QuickDrawTracker = {
	name = "QuickDraw Tracker",
	version = {0,4},
	settings = {
		enabled = true,
		nSlot = 1,
		nTimeout = 1,
	},

	nCount = 0,
	bTickedOnce = false,
}

function QuickDrawTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("QuickDrawTracker.xml")
	self.wndTracker = Apollo.LoadForm(self.xmlDoc, "QuickDrawTracker", nil, self)
	self.wndTracker:SetSizingMinimum(45,45)
	self.wndCount = self.wndTracker:FindChild("Count")

	Apollo.RegisterSlashCommand("qdt", "OnSlashCommand", self)

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	-- Wait 0s to let OnRestore() fire
	ApolloTimer.Create(0, false, "DelayedInit", self)
end

function QuickDrawTracker:DelayedInit()
	self.wndTracker:FindChild("TrackerBtn"):SetContentId(self.settings.nSlot-1)
	if self.settings.enabled then self:Activate() end
end

function QuickDrawTracker:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = "QuickDraw Tracker"})
	Event_FireGenericEvent("WindowManagementAdd", {strName = "QuickDraw Tracker", wnd = self.wndTracker})
end

function QuickDrawTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
    return {version = self.version, settings = self.settings}
end

function QuickDrawTracker:OnRestore(eType, tSave)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tSave.version == self.version then self.settings = tSave.settings end
end

function QuickDrawTracker:OnSlashCommand(strCmd, strArg)
	if strArg == "on"  and not self.settings.enabled then self:Activate(); return end
	if strArg == "off" and     self.settings.enabled then self:Deactivate(); return end
	if tonumber(strArg) ~= nil then
		self.wndTracker:FindChild("TrackerBtn"):SetContentId(tonumber(strArg)-1)
		self.settings.nSlot = tonumber(strArg)
		return
	end
	Print("QuickDrawTracker:")
	Print("/qdt [on/off]: activates or deactivates QuickDrawTracker.")
	Print("/qdt n: sets icon to n-th LAS slot (should be set to Quick Draw LAS slot)")
end

---

function QuickDrawTracker:Activate()
	Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnterOrExitCombat", self)
	self.wndTracker:Show(true)
	self.tmrOutOfCombat = ApolloTimer.Create(self.settings.nTimeout, false, "Reset", self)
	Print("QuickDrawTracker: On")
	self.settings.enabled = true
end

function QuickDrawTracker:Deactivate()
	Apollo.RemoveEventHandler("CombatLogDamage", self)
	Apollo.RemoveEventHandler("UnitEnteredCombat", self)
	self.wndTracker:Show(false)
	self.tmrOutOfCombat = nil
	Print("QuickDrawTracker: Off")
	self.settings.enabled = false
end

function QuickDrawTracker:SetCount(nCount)
	self.nCount = nCount
	if nCount == 0 then self.wndCount:SetText(0) end
	if (nCount+2) % 3 == 0 then self.wndCount:SetText((nCount+2)/3) end
end

function QuickDrawTracker:Reset()
	self:SetCount(0)
	self.bTickedOnce = false
end

--- Event Callbacks

function QuickDrawTracker:OnCombatLogDamage(e)
	local unitFocus = GameLib.GetPlayerUnit():GetAlternateTarget()
	if e.unitTarget == unitFocus then

		if e.bTargetKilled then	self:Reset(); return end

		if e.unitCaster and e.unitCaster:IsThePlayer() then
			local strSpellName = e.splCallingSpell:GetName()

			if strSpellName == "Quick Draw" then self:SetCount(self.nCount+1)
			elseif strSpellName == "Ignite" then
				if e.bPeriodic then
					if not self.bTickedOnce then
						self:SetCount(0)
						self.bTickedOnce = true
					end
				else
					self.bTickedOnce = false
				end
			end
		end
	end
end

function QuickDrawTracker:OnEnterOrExitCombat(unit, bInCombat)
	if unit:IsThePlayer() then
		if bInCombat then self.tmrOutOfCombat:Stop() else self.tmrOutOfCombat:Start() end
	end
end

Apollo.RegisterAddon(QuickDrawTracker)
