---君念生：荣耀
function jns_ry_upgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	
	if not caster._listener_name and not Spawner.IsInfinite() then
		caster._listener_name = Spawner.RegisterWaveChangeListener(function()
			
			if Spawner.IsInfinite() then
				caster._listener_name = nil
				return true
			end
		
			local dps = (caster.dps_total_damage  or 0) * 5
			local max = GetAbilitySpecialValueByLevel(ability,"max")
			local gold = math.min(dps,max)
			if gold > 0 then
				gold = math.ceil(gold)
				
				--检查施法者是否经过了卡牌等级提升的强化
				local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
				if bonusModifier and bonusModifier:GetStackCount() > 0 then
					gold = gold * (1 + bonusModifier:GetStackCount() / 100)
				end
				
				PlayerUtil.AddGold(PlayerID,gold)
				PopupNum:PopupGoldGain(caster,gold)
				
				NotifyUtil.ShowSysMsg(PlayerID,{"ability_junniansheng_ry",":"..tostring(gold)},3)
			end
		end)
	end
end

---移除君念生的时候，销毁监听
function jns_ry_died(keys)
	local caster = keys.caster
	if caster._listener_name then
		Spawner.RemoveWaveChangeListener(caster._listener_name)
		caster._listener_name = nil
	end
end


---君念生：献祭
function jns_xj_cast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	
	local cost = GetAbilitySpecialValueByLevel(ability,"cost")
	if PlayerUtil.GetGold(PlayerID) >= cost then
		local lvl = GetAbilitySpecialValueByLevel(ability,"lvl")
		local boxName = keys["lvl"..tostring(lvl)]
		if boxName then
			--下面执行失败暂时先不返还金币
			PlayerUtil.SpendGold(PlayerID,cost)
			local item = ItemUtil.AddItem(caster,boxName,true)
			if item then
				NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_item","DOTA_Tooltip_ability_"..boxName},3)
			else
				DebugPrint("jns_xj_cast create item faild",boxName)
			end
		end
	else
		NotifyUtil.ShowError(PlayerID,"error_need_more_gold",2)
		ability:EndCooldown()
	end
end