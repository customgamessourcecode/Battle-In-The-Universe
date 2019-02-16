---林静（天冰）
function group_xfzs_linjing(keys,valid)
	local caster = keys.caster
	if valid then
		--天冰-冰霜剑气：冰冻时间延长
		local bonusAbility = caster:FindAbilityByName("dzz_LingJing_bsjq")
		if bonusAbility then
			bonusAbility.group_bonus = true
		end
	else
		--天冰-冰霜剑气：冰冻时间延长
		local bonusAbility = caster:FindAbilityByName("dzz_LingJing_bsjq")
		if bonusAbility then
			bonusAbility.group_bonus = nil
		end
	end
end

---冥灵（水玲儿）
function group_xfzs_mingling(keys,valid)
	local caster = keys.caster
	if valid then
		--水玲儿-水龙卷：作用范围提升
		local first = "wwdx_MingLing_slj";
		local second = "wwdx_MingLing_slj_group";
		
		local ability1 = caster:FindAbilityByName(first)
		if ability1 then
			local lvl1 = ability1:GetLevel()
			
			local ability2 = caster:FindAbilityByName(second)
			if not ability2 then
				ability2 = caster:AddAbility(second)
			end
			if ability2 then
				caster:SwapAbilities(first,second,false,true)
				ability2:SetLevel(lvl1)
			end
		end
	else
		--水玲儿-水龙卷：作用范围提升
		local first = "wwdx_MingLing_slj_group";
		local second = "wwdx_MingLing_slj";
		
		local ability1 = caster:FindAbilityByName(first)
		if ability1 then
			local lvl1 = ability1:GetLevel()
			
			local ability2 = caster:FindAbilityByName(second)
			if not ability2 then
				ability2 = caster:AddAbility(second)
			end
			if ability2 then
				caster:SwapAbilities(first,second,false,true)
				ability2:SetLevel(lvl1)
			end
		end
	end
end

---应欢欢（冰清）
function group_xfzs_yinghuanhuan(keys,valid)
	local caster = keys.caster
	if valid then
		--冰清-冰雪消融：技能增强效果提升
		local bonusAbility = caster:FindAbilityByName("wdqk_YingHuanHuan_bingxuexiaorong")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_wdqk_YingHuanHuan_bingxuexiaorong_aura")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_wdqk_YingHuanHuan_bingxuexiaorong_aura_group",{})
		end
	else
		--冰清-冰雪消融：技能增强效果提升
		local bonusAbility = caster:FindAbilityByName("wdqk_YingHuanHuan_bingxuexiaorong")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_wdqk_YingHuanHuan_bingxuexiaorong_aura_group")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_wdqk_YingHuanHuan_bingxuexiaorong_aura",{})
		end
	end
end

---风霜之水
function group_xfzs_thinker(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	--记录已经符合条件的单位名称，有可能有多个同名单位，这里只记录一次即可。当有一组符合条件，所有同名单位都受到加成效果
	local names = {"tower_dzz_linjing","tower_wwdx_mingling","tower_wdqk_yinghuanhuan"}
	local needCount = #names
	local level = 9
	
	local validCount = 0
	local towers = Towermgr.getPlayerTowers(caster)
	if towers then
		for index, unit in pairs(towers) do
			for pos, unitName in pairs(names) do
				if EntityNotNull(unit) and unit:GetUnitName() == unitName and unit:GetLevel() == level then
					validCount = validCount + 1
					table.remove(names,pos)
					break;
				end
			end
		end
	end
	
	if validCount == needCount then
		if caster:FindModifierByName("modifier_group_xfzs_tooltip") then
			return;
		end
		
		if caster:GetUnitName() == "tower_dzz_linjing"  then
			group_xfzs_linjing(keys,true)
		elseif caster:GetUnitName() == "tower_wwdx_mingling" then
			group_xfzs_mingling(keys,true)
		elseif caster:GetUnitName() == "tower_wdqk_yinghuanhuan" then
			group_xfzs_yinghuanhuan(keys,true)
		end
		AddDataDrivenModifier(ability,caster,caster,"modifier_group_xfzs_tooltip",{})
	else
		if not caster:FindModifierByName("modifier_group_xfzs_tooltip") then
			return;
		end
		if caster:GetUnitName() == "tower_dzz_linjing"  then
			group_xfzs_linjing(keys,false)
		elseif caster:GetUnitName() == "tower_wwdx_mingling" then
			group_xfzs_mingling(keys,false)
		elseif caster:GetUnitName() == "tower_wdqk_yinghuanhuan" then
			group_xfzs_yinghuanhuan(keys,false)
		end
		caster:RemoveModifierByName("modifier_group_xfzs_tooltip")
	end
end
