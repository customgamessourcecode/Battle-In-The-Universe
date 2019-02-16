--伉俪情深效果
function zx_group_klqs(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	--记录已经符合条件的单位名称，有可能有多个同名单位，这里只记录一次即可。当有一组符合条件，所有同名单位都受到加成效果
	local names = {"tower_zx_tianbuyi","tower_zx_suru"}
	local level = 6
	
	local nameMap = {}
	local validCount = 0
	local towers = Towermgr.getPlayerTowers(caster)
	if towers then
		for index, unit in pairs(towers) do
			for key, unitName in pairs(names) do
				if EntityNotNull(unit) and unit:GetUnitName() == unitName and unit:GetLevel() == level and not nameMap[unitName] then
					nameMap[unitName] = true
					validCount = validCount + 1
					break;
				end
			end
		end
	end
	
	nameMap = nil
	
	if validCount == #names then
		if caster:GetUnitName() == "tower_zx_suru" then
			if caster:HasModifier("modifier_zx_group_klqs_sr") then
				return;
			end
			local first = "zx_SuRu_syj";
			local second = "zx_SuRu_syj_high";
			
			local ability1 = caster:FindAbilityByName(first)
			if ability1 then
				local lvl1 = ability1:GetLevel()
				
				local ability2 = caster:FindAbilityByName(second)
				if not ability2 then
					ability2 = caster:AddAbility(second)
				end
				if ability2 then
					caster:SwapAbilities(first,second,false,true)
					--移除掉旧的光环modifier，在下次设置level的时候会重新添加上。不能删除技能，否则光环不会正常消失（光环图标也显示异常）
					caster:RemoveModifierByNameAndCaster("modifier_"..first,caster)
					ability2:SetLevel(lvl1)
					AddDataDrivenModifier(ability,caster,caster,"modifier_zx_group_klqs_sr",{})
				end
			end
		else
			AddDataDrivenModifier(ability,caster,caster,"modifier_zx_group_klqs_tby",{})
		end
	else
		if caster:GetUnitName() == "tower_zx_suru" then
			if not caster:HasModifier("modifier_zx_group_klqs_sr") then
				return;
			end
		
			local first = "zx_SuRu_syj_high";
			local second = "zx_SuRu_syj";
			
			local ability1 = caster:FindAbilityByName(first)
			if ability1 then
				local lvl1 = ability1:GetLevel()
				
				local ability2 = caster:FindAbilityByName(second)
				if not ability2 then
					ability2 = caster:AddAbility(second)
				end
				if ability2 then
					caster:SwapAbilities(first,second,false,true)
					--移除掉旧的光环modifier，在下次设置level的时候会重新添加上。不能删除技能，否则光环不会正常消失（光环图标也显示异常）
					caster:RemoveModifierByNameAndCaster("modifier_"..first,caster)
					ability2:SetLevel(lvl1)
					caster:RemoveModifierByName("modifier_zx_group_klqs_sr")
				end
			end
		else
			caster:RemoveModifierByName("modifier_zx_group_klqs_tby")
		end
	end
	
end