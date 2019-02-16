---青帝：青莲屏障。目前的实现方式，只会在穿过的时候触发一次，如果一直站在屏障范围内，不会持续受到伤害
function qd_qlpz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local direction = GetForwardVector(caster:GetAbsOrigin(),point)
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	local diameter = radius * 2
	
	local startPos = point - direction * length / 2
	local endPost = point + direction * length / 2
	
	if ability.particle then
		ParticleManager:DestroyParticle(ability.particle,true)
	end
	--重新创建特效，每次设置位置的话，不好使
	local path = "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
	SetParticleControlEx(pid,0,startPos)
	SetParticleControlEx(pid,1,endPost)
	ability.particle = pid

	local dummys = 	ability.dummys
	if not dummys then
		dummys = {}
		ability.dummys = dummys
	else
		for var=#dummys, 1,-1 do
			EntityHelper.remove(dummys[var])
			table.remove(dummys,var)
		end
	end
	
	local count = math.ceil(length / diameter)
	for index=1, count do
		local dummy = CreateDummyUnit(startPos + direction * (diameter * index - radius),caster)
		AddDataDrivenModifier(ability,caster,dummy,"modifier_zt_QingDi_qlpz_aura",{})
		table.insert(dummys,dummy)
	end
end

---塔收回，移除青莲屏障
function qd_qlpz_destroy(keys)
	local ability = keys.ability
	local dummys = 	ability.dummys
	if dummys then
		ClearUnitArray(dummys)
	end
	if ability.particle then
		ParticleManager:DestroyParticle(ability.particle,true)
	end
end

---青帝：万古青天一株莲
function qd_wgqtyzl_start(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	
	if ability._dummys then
		ClearUnitArray(ability._dummys)
		ability._dummys = nil
	end
	
	
	local direction = GetForwardVector(caster:GetAbsOrigin(),point)
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local diameter = radius * 2
	--垂直放置
	local startPos = RotateVector2DWithCenter(point,point - direction * count * radius,90)
	direction = RotateVector2D(direction,90)
	
	local model = "particles/zt/qingdi_flower.vpcf"
	
	local dummys = {}
	
	for index=1, count do
		local dummy = CreateDummyUnit(startPos + direction * (diameter * index - radius),caster)
		
		AddDataDrivenModifier(ability,dummy,dummy,"modifier_zt_QingDi_wgqtyzl_dummy",{})
		
		local pid = CreateParticleEx(model,PATTACH_ABSORIGIN,dummy)
		SetParticleControlEx(pid,0,dummy:GetAbsOrigin())
		SetParticleControlEx(pid,1,Vector(duration,0,0))
		
		table.insert(dummys,dummy)
	end
	
	ability._dummys = dummys
	
	TimerUtil.createTimerWithDelay(duration,function()
		local damageAbility = caster:FindAbilityByName("zt_QingDi_wlxkyst")
		
		local radius = nil
		local damage = nil
		if damageAbility and damageAbility:GetLevel() > 0 then
			radius = GetAbilitySpecialValueByLevel(damageAbility,"radius")
			damage = GetAbilitySpecialValueByLevel(damageAbility,"damage")
		end
		
		for key, unit in pairs(dummys) do
			
			if radius and damage then
				EmitSound(unit,"Hero_StormSpirit.StaticRemnantExplode")
				
				local path = "particles/zt/qingdi_flower_explosion/qingdi_flower_explosion.vpcf"
				CreateParticleEx(path,PATTACH_ABSORIGIN,unit)
				
				DamageEnemiesWithinRadius(unit:GetAbsOrigin(),radius,caster,damage,damageAbility)
			end
			EntityHelper.remove(unit)
		end
	end)
	
end

---青帝：青莲检查
function qd_wgqtyzl_check(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	--一朵花，只禁锢一个
	if not caster:HasModifier("modifier_zt_QingDi_wgqtyzl_dummy_rooting") then
		local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
		if units and #units > 0 then
			local duration = GetAbilitySpecialValueByLevel(ability,"root_duration")
			
			local unit = nil
			for key, var in pairs(units) do
				if not var.TD_IsBoss and not unit:HasModifier("modifier_zt_QingDi_wgqtyzl_debuff") then
					unit = var;
					break;
				end
			end
			
			if unit then
				AddDataDrivenModifier(ability,caster,unit,"modifier_zt_QingDi_wgqtyzl_debuff",{})
			
				local path = "particles/econ/items/lone_druid/lone_druid_cauldron_retro/lone_druid_bear_entangle_body_retro_cauldron.vpcf"
				local pid = CreateParticleEx(path,PATTACH_POINT_FOLLOW,unit,duration)
				SetParticleControlEnt(pid,0,unit,PATTACH_POINT_FOLLOW,"attach_hitloc",unit:GetAbsOrigin())
			end
		end
	end
end

---塔收回，移除效果
function qd_wgqtyzl_destroy(keys)
	local ability = keys.ability
	if ability._dummys then
		ClearUnitArray(ability._dummys)
	end
end