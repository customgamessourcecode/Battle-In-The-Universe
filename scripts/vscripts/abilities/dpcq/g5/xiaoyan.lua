---萧炎：焰分噬浪尺
function xy_yfslc(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = caster:Script_GetAttackRange()
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local speed = GetAbilitySpecialValueByLevel(ability,"projectile_speed")
	
	local enemies = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	if enemies and #enemies > 0 then
		local effectName = "particles/world_tower/tower_upgrade/ti7_dire_tower_projectile.vpcf"
		for key, unit in pairs(enemies) do
			if count <= 0 then
				break;
			end
			CreateProjectileWithTarget(caster,unit,ability,effectName,speed)
			count = count - 1
		end
	end
end

---萧炎：佛怒火莲
function xy_fnhl(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")

	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	local damageRadius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	--特效半径
	local radius = damageRadius * 2
	
	local path1 = keys.particle
	local path2 = keys.particle2
	local preSound = keys.preSound
	local finalSound = keys.finalSound
	local modifeir = keys.modifier
	
	local pid = CreateParticleEx(path1,PATTACH_ABSORIGIN,caster)
	SetParticleControlEx(pid,0,point)
	SetParticleControlEx(pid,1,Vector(duration,0,0))
	
	TimerUtil.createTimerWithDelay(duration,function()
		ParticleManager:DestroyParticle(pid, true)
	
		pid = CreateParticleEx(path2,PATTACH_ABSORIGIN,caster)
		SetParticleControlEx(pid,0,point)
		if finalSound then
			if preSound then
				StopSoundOn(preSound,caster)
				SetParticleControlEx(pid,3,Vector(radius,0,0))
			end
			EmitSoundOnLoc(point,finalSound,caster)
		end
		local enemies = FindEnemiesInRadiusEx(caster,point,damageRadius)
		if enemies and #enemies > 0 then
			local level = caster:GetLevel()
			ratio = level * level * ratio
			for key, unit in pairs(enemies) do
				local realDamage = caster:GetAverageTrueAttackDamage(unit) * ratio + damage
				ApplyDamageEx(caster,unit,ability,realDamage)
				if modifeir then
					AddDataDrivenModifier(ability,caster,unit,modifeir,{})
				end
				
			end
		end
	end)
end