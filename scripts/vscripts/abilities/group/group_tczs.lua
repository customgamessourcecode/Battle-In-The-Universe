---东伯雪鹰（季元正）
function group_tczs_dbxy(keys,valid)
	local caster = keys.caster
	
	if valid then
		--季元正-九转不灭术：触发几率提升
		local bonusAbility = caster:FindAbilityByName("xylz_DongBoXueYing_jzbms")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_xylz_DongBoXueYing_jzbms")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_xylz_DongBoXueYing_jzbms_group",{})
		end
		--季元正-浑源七击：增伤系数提升
		bonusAbility = caster:FindAbilityByName("xylz_DongBoXueYing_hyqj")
		if bonusAbility then
			bonusAbility.group_bonus = true
		end
	else
		--季元正-九转不灭术：触发几率提升
		local bonusAbility = caster:FindAbilityByName("xylz_DongBoXueYing_jzbms")
		if bonusAbility then
			caster:RemoveModifierByName("modifier_xylz_DongBoXueYing_jzbms_group")
			AddDataDrivenModifier(bonusAbility,caster,caster,"modifier_xylz_DongBoXueYing_jzbms",{})
		end
		--季元正-浑源七击：增伤系数提升
		bonusAbility = caster:FindAbilityByName("xylz_DongBoXueYing_hyqj")
		if bonusAbility then
			bonusAbility.group_bonus = nil
		end
	end
end
---纪宁（济苍生）
function group_tczs_jn(keys,valid)
	local caster = keys.caster
	
	if valid then
		--济苍生-神剑终极剑道·滴血：减甲效果提升
		local bonusAbility = caster:FindAbilityByName("mhj_JiNing_myzjjd_dx")
		if bonusAbility then
			bonusAbility.armor_special = "armor_group"
		end
		--济苍生-永恒剑道：持续时间提升
		bonusAbility = caster:FindAbilityByName("mhj_JiNing_yhzjjd")
		if bonusAbility then
			bonusAbility.duration_group = true
		end
	else
		--济苍生-神剑终极剑道·滴血：减甲效果提升
		local bonusAbility = caster:FindAbilityByName("mhj_JiNing_myzjjd_dx")
		if bonusAbility then
			bonusAbility.armor_special = nil
		end
		--济苍生-永恒剑道：持续时间提升
		bonusAbility = caster:FindAbilityByName("mhj_JiNing_yhzjjd")
		if bonusAbility then
			bonusAbility.duration_group = nil
		end
	end
end
---陆雪琪（陆冰心）
function group_tczs_lxq(keys,valid)
	local caster = keys.caster
	
	if valid then
		--陆冰心-天玄冰：水系承伤提升
		local bonusAbility = caster:FindAbilityByName("zx_luxueqi_txb")
		if bonusAbility then
			bonusAbility.xxj_edi_special = "ratio_group"
		end
		--陆冰心-御雷真诀：持续时间提升
		bonusAbility = caster:FindAbilityByName("zx_luxueqi_ylzj")
		if bonusAbility then
			bonusAbility.duration_group = true
		end
	else
		--陆冰心-天玄冰：水系承伤提升
		local bonusAbility = caster:FindAbilityByName("zx_luxueqi_txb")
		if bonusAbility then
			bonusAbility.xxj_edi_special = nil
		end
		--陆冰心-御雷真诀：持续时间提升
		bonusAbility = caster:FindAbilityByName("zx_luxueqi_ylzj")
		if bonusAbility then
			bonusAbility.duration_group = nil
		end
	end
end

---太初之水
function group_tczs_thinker(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	--记录已经符合条件的单位名称，有可能有多个同名单位，这里只记录一次即可。当有一组符合条件，所有同名单位都受到加成效果
	local names = {"tower_xylz_dongboxueying","tower_mhj_jining","tower_zx_luxueqi"}
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
		if caster:FindModifierByName("modifier_group_tczs_tooltip") then
			return;
		end
		
		if caster:GetUnitName() == "tower_xylz_dongboxueying"  then
			group_tczs_dbxy(keys,true)
		elseif caster:GetUnitName() == "tower_mhj_jining" then
			group_tczs_jn(keys,true)
		elseif caster:GetUnitName() == "tower_zx_luxueqi" then
			group_tczs_lxq(keys,true)
		end
		AddDataDrivenModifier(ability,caster,caster,"modifier_group_tczs_tooltip",{})
	else
		if not caster:FindModifierByName("modifier_group_tczs_tooltip") then
			return;
		end
		if caster:GetUnitName() == "tower_xylz_dongboxueying"  then
			group_tczs_dbxy(keys,false)
		elseif caster:GetUnitName() == "tower_mhj_jining" then
			group_tczs_jn(keys,false)
		elseif caster:GetUnitName() == "tower_zx_luxueqi" then
			group_tczs_lxq(keys,false)
		end
		caster:RemoveModifierByName("modifier_group_tczs_tooltip")
	end
end

