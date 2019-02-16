---秦霜（萧冰）
function group_fszs_qinshuang(keys,valid)
	local caster = keys.caster
	if valid then
		--萧冰-寒气侵袭：额外附加水系承伤提升效果
		local bonusAbility = caster:FindAbilityByName("xcb_qinShuang_hfcg")
		if bonusAbility then
			bonusAbility.group_bonus = true
		end
	else
		--萧冰-寒气侵袭：额外附加水系承伤提升效果
		local bonusAbility = caster:FindAbilityByName("xcb_qinShuang_hfcg")
		if bonusAbility then
			bonusAbility.group_bonus = nil
		end
	end
end

---曹雨生(习泽)
function group_fszs_cys(keys,valid)
	local caster = keys.caster
	if valid then
		--习泽-吞天魔盖：眩晕时间延长
		local bonusAbility = caster:FindAbilityByName("wmsj_CaoYuSheng_ttmg")
		if bonusAbility then
			bonusAbility.group_bonus = true
		end
	else
		--习泽-吞天魔盖：眩晕时间延长
		local bonusAbility = caster:FindAbilityByName("wmsj_CaoYuSheng_ttmg")
		if bonusAbility then
			bonusAbility.group_bonus = nil
		end
	end
end

---风霜之水
function group_fszs_thinker(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	--记录已经符合条件的单位名称，有可能有多个同名单位，这里只记录一次即可。当有一组符合条件，所有同名单位都受到加成效果
	local names = {"tower_xcb_qinshuang","tower_wmsj_caoyusheng"}
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
		if caster:FindModifierByName("modifier_group_fszs_tooltip") then
			return;
		end
		
		if caster:GetUnitName() == "tower_xcb_qinshuang"  then
			group_fszs_qinshuang(keys,true)
		elseif caster:GetUnitName() == "tower_wmsj_caoyusheng" then
			group_fszs_cys(keys,true)
		end
		AddDataDrivenModifier(ability,caster,caster,"modifier_group_fszs_tooltip",{})
	else
		if not caster:FindModifierByName("modifier_group_fszs_tooltip") then
			return;
		end
		if caster:GetUnitName() == "tower_xcb_qinshuang"  then
			group_fszs_qinshuang(keys,false)
		elseif caster:GetUnitName() == "tower_wmsj_caoyusheng" then
			group_fszs_cys(keys,false)
		end
		caster:RemoveModifierByName("modifier_group_fszs_tooltip")
	end
end
