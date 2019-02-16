local m = {}

function m.sendSAToClient(_,keys)
	local PlayerID,unitIndex = keys.PlayerID,keys.index
	local result = {}
	local unit = EntityHelper.findEntityByIndex(unitIndex)
	if unit then
		result.index = unitIndex
		result.evasion = unit:GetEvasion() * 100 --接口返回的是一个小数
		result.damageOut = 0
		result.damageIn = 0
		
		local modifiers = unit:FindAllModifiers()
		if modifiers then
			for key, modifier in pairs(modifiers) do
				if modifier.GetModifierTotalDamageOutgoing_Percentage then
					local value = modifier:GetModifierTotalDamageOutgoing_Percentage()
					result.damageOut = result.damageOut + value
				end
				if modifier.GetModifierIncomingDamage_Percentage then
					local value = modifier:GetModifierIncomingDamage_Percentage()
					result.damageIn = result.damageIn + value
				end
			end
		end
		
		--回血，客户端的接口乱乱的，通过服务器去获取
		--data.healthRegen, data.healthRegenBonus
		result.healthRegen = unit:GetBaseHealthRegen()
		result.healthRegenBonus = unit:GetHealthRegen() - unit:GetBaseHealthRegen()
		
		--元素属性
		result.element = Elements.GetUnitElement(unitIndex)
		
		local armor = unit.custom_armor_data
		if armor then
			result.armor_base = armor.base
			result.armor_bonus = armor.bonus
		end
	end
	
	SendToClient(PlayerID,"custom_set_special_attribute",result)
	
--	SetNetTableValue("unit_info",tostring(unitIndex),{data=result})
--	if not unit._unit_info_death_checker then
--		unit._unit_info_death_checker = DealWithUnitDeath(unit,function()
--			SetNetTableValue("unit_info",tostring(unitIndex),nil)
--		end)
--	end
	
end

local init = function()
	RegisterEventListener("custom_get_special_attribute",m.sendSAToClient)
end

init()
return m