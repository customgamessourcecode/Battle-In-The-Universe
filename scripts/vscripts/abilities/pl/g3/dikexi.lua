function dkx_fireStorm(keys)
	local ability = keys.ability
	local level = ability:GetLevel() - 1
	local caster = keys.caster
	
	local point = keys.target_points[1]
	
	local duration = ability:GetLevelSpecialValueFor("duration", level)
	local radius = ability:GetLevelSpecialValueFor("radius", level)
	local damage = ability:GetLevelSpecialValueFor("damage", level)
	
	local particle = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			for var=1, 6 do
				local p = CreateParticleEx(particle,PATTACH_CUSTOMORIGIN,caster)
				SetParticleControlEx(p,0,RandomPosInRadius(point,radius))
			end
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			duration = duration - 1
			return 1
		end
	end)
end