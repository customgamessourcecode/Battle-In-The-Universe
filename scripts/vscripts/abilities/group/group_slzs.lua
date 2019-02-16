---九幽
function group_slzs_jiuyou(keys,valid)
	local caster = keys.caster
	if valid then
		--魅魔-破海珠：承伤系数提升
		local bonusAbility = caster:FindAbilityByName("dzz_JiuYou_phz")
		if bonusAbility then
			bonusAbility.xxj_edi_special = "ratio_group"
		end
	else
		--魅魔-破海珠：承伤系数提升
		local bonusAbility = caster:FindAbilityByName("dzz_JiuYou_phz")
		if bonusAbility then
			bonusAbility.xxj_edi_special = nil
		end
	end
end

---周佚
function group_slzs_zhouyi(keys,valid)
	local caster = keys.caster
	if valid then
		--周佚-水之世界：承伤系数提升
		local bonusAbility = caster:FindAbilityByName("xn_ZhouYi_szsj")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_xn_ZhouYi_szsj")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_xn_ZhouYi_szsj_group",{})
			bonusAbility.xxj_edi_special = "ratio_group"
		end
	else
		--周佚-水之世界：承伤系数提升
		local bonusAbility = caster:FindAbilityByName("xn_ZhouYi_szsj")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_xn_ZhouYi_szsj_group")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_xn_ZhouYi_szsj",{})
			bonusAbility.xxj_edi_special = nil
		end
	end
end
---纱罗之水
function group_slzs_thinker(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	--记录已经符合条件的单位名称，有可能有多个同名单位，这里只记录一次即可。当有一组符合条件，所有同名单位都受到加成效果
	local names = {"tower_dzz_jiuyou","tower_xn_zhouyi"}
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
		if caster:FindModifierByName("modifier_group_slzs_tooltip") then
			return;
		end
		
		if caster:GetUnitName() == "tower_dzz_jiuyou"  then
			group_slzs_jiuyou(keys,true)
		elseif caster:GetUnitName() == "tower_xn_zhouyi" then
			group_slzs_zhouyi(keys,true)
		end
		AddDataDrivenModifier(ability,caster,caster,"modifier_group_slzs_tooltip",{})
	else
		if not caster:FindModifierByName("modifier_group_slzs_tooltip") then
			return;
		end
		if caster:GetUnitName() == "tower_dzz_jiuyou"  then
			group_slzs_jiuyou(keys,false)
		elseif caster:GetUnitName() == "tower_xn_zhouyi" then
			group_slzs_zhouyi(keys,false)
		end
		caster:RemoveModifierByName("modifier_group_slzs_tooltip")
	end
end
