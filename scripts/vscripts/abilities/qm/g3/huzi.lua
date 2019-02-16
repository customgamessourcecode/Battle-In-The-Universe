---陷阱类技能施法（类似一个kv的thinker类buff）
--在指定点创建一个虚拟单位，给单位赋予光环效果，永久存在，直到释放可释放数量达到最大数量以后又释放新的
function hz_jgl_spell(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local modifier = caster:FindModifierByName("modifier_qm_HuZi_jgl")
	if modifier and modifier:GetStackCount() > 0 then
		local lifetime = GetAbilitySpecialValueByLevel(ability,"lifetime")
		local activateDelay = GetAbilitySpecialValueByLevel(ability,"activate_delay")
		
		local dummy = CreateDummyUnit(point,caster,false,true,false)
		
		AddDataDrivenModifier(ability,caster,dummy,"modifier_qm_HuZi_jgl_activate_delay",{})
		
		local path = "particles/units/heroes/hero_techies/techies_stasis_trap_plant.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy)
		SetParticleControlEx(pid,0,point)
		SetParticleControlEx(pid,1,point)
		
		path = "particles/units/heroes/hero_techies/techies_stasis_trap_apear.vpcf"
		pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy)
		SetParticleControlEx(pid,3,point)
		
		--特效是1秒
		TimerUtil.createTimerWithDelay(1,function()
			MakeUnitTemporary(dummy,lifetime,ability)
			ChangeModelTemporary(dummy,"models/heroes/techies/fx_techiesfx_stasis.vmdl")
		end)
		
		modifier:DecrementStackCount()
	end
end

---陷阱类技能升级，增加能量点数
function hz_jgl_charge(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local maxCount = GetAbilitySpecialValueByLevel(ability,"count")
	local modifier = caster:FindModifierByName("modifier_qm_HuZi_jgl")
	if modifier and modifier:GetStackCount() < maxCount then
		modifier:IncrementStackCount()
	end
end

function hz_jgl_checker(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target

	if #keys.target_entities > 0 and not target:HasModifier("modifier_qm_HuZi_jgl_explode_delay") then
		local delay = GetAbilitySpecialValueByLevel(ability,"explode_delay")
		local path = "particles/neutral_fx/roshan_death_timer_arc_head.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target,delay,true)
		SetParticleControlEx(pid,3,target:GetAbsOrigin() + Vector(0,0,50))
		AddDataDrivenModifier(ability,caster,target,"modifier_qm_HuZi_jgl_explode_delay",{duration=delay})
	end
end

---陷阱触发
function hz_jgl_explode(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local path = "particles/units/heroes/hero_techies/techies_stasis_trap_explode.vpcf"
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	if EntityNotNull(target) then
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
		SetParticleControlEx(pid,0,target:GetAbsOrigin())
		
		EmitSound(target,"Hero_Techies.StasisTrap.Stun")
		
		local units = FindEnemiesInRadiusEx(target,target:GetAbsOrigin(),radius)
		if #units > 0 then
			for key, unit in pairs(units) do
				AddDataDrivenModifier(ability,caster,unit,"modifier_qm_HuZi_jgl_debuff",{})
			end
		end
		
		EntityHelper.remove(target)
	end
end