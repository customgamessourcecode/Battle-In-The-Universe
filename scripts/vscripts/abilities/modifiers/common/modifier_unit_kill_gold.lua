--组合型单位符合条件后增加buff
if modifier_unit_kill_gold == nil then
	modifier_unit_kill_gold = class({})
	
	local m = modifier_unit_kill_gold;
	
	--无敌保持
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE;
	end
	
	function m:IsHidden()
		return true;
	end
	
	--是否可以被净化
	function m:IsPurgable()
		return false;
	end
	
	function m:AllowIllusionDuplicate()
		return true;
	end
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_EVENT_ON_DEATH
	  }
	  return funcs;
	end
	
	function m:OnDeath(keys)
		if IsServer() then
			local unit = keys.attacker
			local diedUnit = keys.unit
			if diedUnit and diedUnit:GetTeamNumber() == TEAM_ENEMY and not diedUnit._modifier_unit_kill_gold then
				diedUnit._modifier_unit_kill_gold = true;--不知道为啥会进来两次，暂时先不研究了
				local PlayerID = PlayerUtil.GetOwnerIDForDummy(unit)
				local hero = PlayerUtil.GetHero(PlayerID)
				if hero then
					local ratio = 0
					local modifiers = hero:FindAllModifiersByName("td_multiple_gold_gain_percentage")
					if modifiers and #modifiers > 0 then
						for _, modifier in pairs(modifiers) do
							local value = modifier:GetGoldGainPercentage() or 0
							ratio = value / 100 + ratio
						end
					end
					local gold = diedUnit:GetGoldBounty()
					gold = gold * (1 + ratio);
					--增加金币
					PlayerUtil.AddGold(PlayerID,gold)
					ShowOverheadMsg(diedUnit,OVERHEAD_ALERT_GOLD,gold,PlayerUtil.GetPlayer(PlayerID,true))
				end
			end
		end
	end
end

