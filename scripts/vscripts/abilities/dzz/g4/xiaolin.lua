---萧霖：控火诀
function xl_khj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	ability.td_is_trap = true
	
	local direction = GetForwardVector(caster:GetAbsOrigin(),point)
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	--垂直放置
	local startPos = RotateVector2DWithCenter(point,point - direction * (length / 2),90)
	direction = RotateVector2D(direction,90)

	local dummys = 	ability.dummys
	if not dummys then
		dummys = {}
		ability.dummys = dummys
	else
		for var=#dummys, 1,-1 do
			local dummy = dummys[var]
			if dummy.pid then
				ParticleManager:DestroyParticle(dummy.pid,true)
			end
			EntityHelper.kill(dummy)
			table.remove(dummys,var)
		end
	end
	local path = "particles/econ/items/batrider/batrider_ti8_immortal_mount/batrider_ti8_immortal_firefly_path_front_b.vpcf";
	local diameter = 120
	local count = math.ceil(length / diameter)
	for index=1, count do
		local dummy = CreateDummyUnit(startPos + direction * (diameter * index - radius),caster)
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy)
		dummy.pid = pid
		
		if index == 1 then
			EmitSound(dummy,"Hero_Batrider.Firefly.loop")
		end
		
		AddDataDrivenModifier(ability,caster,dummy,"modifier_dzz_XiaoLin_khj_dummy",{})
		table.insert(dummys,dummy)
	end
end

---塔移除后，控火诀销毁
function xl_khj_destroy(keys)
	local ability = keys.ability
	local dummys = 	ability.dummys
	if dummys then
		for var=#dummys, 1,-1 do
			local dummy = dummys[var]
			if dummy.pid then
				ParticleManager:DestroyParticle(dummy.pid,true)
			end
			EntityHelper.kill(dummy,true)
			table.remove(dummys,var)
		end
	end
end

---萧林：火毒
function xl_khj_think_hd(keys)
	local caster = keys.caster
	local target = keys.target
	
	local hdAbility = caster:FindAbilityByName("dzz_XiaoLin_hd")
	if hdAbility and hdAbility:GetLevel() > 0 then
		local delay = GetAbilitySpecialValueByLevel(hdAbility,"delay")
	
		local modifier = target:FindModifierByNameAndCaster("modifier_dzz_XiaoLin_khj_damage",caster)
		if modifier then
			if modifier:GetStackCount() < delay then
				modifier:IncrementStackCount()
			end
			if modifier:GetStackCount() >= delay and not target:HasModifier("modifier_dzz_XiaoLin_hd") then
				AddDataDrivenModifier(hdAbility,caster,target,"modifier_dzz_XiaoLin_hd",{})
			end
		end
	end
end

---萧林：火焰枷锁
function xl_khj_think_hyjs(keys)
	local caster = keys.caster
	local target = keys.target
	
	local jsAbility = caster:FindAbilityByName("dzz_XiaoLin_hyjs")
	if jsAbility and jsAbility:GetLevel() > 0 and not target:HasModifier("modifier_dzz_XiaoLin_hyjs_resist") then
		local chance = GetAbilitySpecialValueByLevel(jsAbility,"chance")
		local duration = GetAbilitySpecialValueByLevel(jsAbility,"duration")
		if RollPercent(chance) then
			local path = "particles/units/heroes/hero_shadowshaman/shadowshaman_shackle_net.vpcf"
			local pid = CreateParticleEx(path,PATTACH_POINT,target,duration)
			ParticleManager:SetParticleControlEnt(pid,1,target,PATTACH_POINT_FOLLOW,"attach_hitloc",target:GetAbsOrigin(),true)
			
			AddDataDrivenModifier(jsAbility,caster,target,"modifier_dzz_XiaoLin_hyjs",{})
		end
	end
end