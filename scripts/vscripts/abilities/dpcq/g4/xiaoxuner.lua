---萧薰儿：金帝焚天炎
function xye_jdfty(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = caster:Script_GetAttackRange()
	
	local enemies =  FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	if enemies and #enemies > 0 then
		local target = enemies[RandomInt(1,#enemies)]
		if EntityIsAlive(target) then
			local speed = GetAbilitySpecialValueByLevel(ability,"projetile_speed")
			local effect = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf"
			CreateProjectileWithTarget(caster,target,ability,effect,speed)
		end
	end
end

---萧薰儿：金帝焚天斩
function xye_jdftz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage_radius = GetAbilitySpecialValueByLevel(ability,"damage_radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local interval = duration / count
	
	local path = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient_hit.vpcf"
	TimerUtil.createTimer(function()
		if count > 0 then
			local pos = RandomPosInRadius(point,radius)
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
			SetParticleControlEx(pid,0,pos)
			
			EmitSoundOnLocationForAllies(pos,"Hero_SkywrathMage.MysticFlare.Target",caster)
			
			DamageEnemiesWithinRadius(pos,damage_radius,caster,damage,ability)
			
			count = count - 1
			return interval
		end
	end)	
end