---九幽：黑暗领域
function jy_haly(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local buff = "modifier_dzz_JiuYou_haly_debuff"
	
	local path = "particles/dzz/jiuyou_haly.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
	SetParticleControlEx(pid,0,caster:GetAbsOrigin())
	SetParticleControlEx(pid,1,Vector(radius,0,0))
	
	local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	for key, unit in pairs(units) do
		AddDataDrivenModifier(ability,caster,unit,buff,{duration=duration})
	end
	
	--黑暗笼罩
	local halzAbility = caster:FindAbilityByName("dzz_JiuYou_halz")
	if halzAbility and halzAbility:GetLevel() > 0 then
		local buff = "modifier_dzz_JiuYou_halz"
		local radius = GetAbilitySpecialValueByLevel(halzAbility,"radius")
		local ratio = GetAbilitySpecialValueByLevel(halzAbility,"ratio")
		
		--临时的黑夜
		GameRules:BeginTemporaryNight(duration)
		
		units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius,DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED)
		if #units > 0 then
			for key, unit in pairs(units) do
				AddDataDrivenModifier(halzAbility,caster,unit,buff,{duration=duration})
				--水系增加输出伤害
				if Elements.GetAttackElement(unit) == Elements.water then
					local modifier = unit:FindModifierByNameAndCaster("modifier_multiple_damage_out",caster)
					if modifier then
						modifier:SetDuration(duration,true)
					else
						AddLuaModifier(caster,unit,"modifier_multiple_damage_out",{duration=duration},halzAbility)
					end
				end
			end
		end
	end
end

---九幽：破海珠
function jy_phz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	if ability._dummy then
		EntityHelper.kill(ability._dummy)
		ability._dummy = nil
	end
	local aura = "modifier_dzz_JiuYou_phz_aura"
	if ability.xxj_edi_special then
		aura = "modifier_dzz_JiuYou_phz_aura_group"
	end
	
	local dummy = CreateDummyUnit(point,caster)
	AddDataDrivenModifier(ability,caster,dummy,aura,{duration=duration})
	ability._dummy = dummy
	
	local path = "particles/dzz/jiuyou_pohaizhu.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy,duration)
	SetParticleControlEx(pid,2,point + Vector(0,0,200))
	
	TimerUtil.createTimerWithDelay(duration,function()
		EntityHelper.kill(dummy)
		ability._dummy = nil
	end)
end

---塔被移除，移除破海珠
function jy_phz_destroy(keys)
	local ability = keys.ability
	if ability._dummy then
		EntityHelper.kill(ability._dummy)
		ability._dummy = nil
	end
end


function jy_phz_debuff_create(keys)
	local target = keys.target
	
	local path = "particles/econ/items/oracle/oracle_fortune_ti7/oracle_fortune_ti7_ambient_ball_water.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN_FOLLOW,target)
	SetParticleControlEnt(pid,2,target,PATTACH_POINT_FOLLOW,"attach_hitloc",target:GetAbsOrigin())
	
	target.jy_phz_debuff = pid
end

function jy_phz_debuff_destroy(keys)
	local target = keys.target
	
	if target.jy_phz_debuff then
		ParticleManager:DestroyParticle(target.jy_phz_debuff,false)
		target.jy_phz_debuff = nil
	end
end