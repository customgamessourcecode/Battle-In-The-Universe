---古雍-三分剑气斩
function gy_sfjqz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local angle = 60
	
	local vector = GetForwardVector(caster:GetAbsOrigin(),point)
	
	local effectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf"
	
	local distance = GetAbilitySpecialValueByLevel(ability,"distance")
	local beginRadius = GetAbilitySpecialValueByLevel(ability,"beginRadius")
	local endRadius = GetAbilitySpecialValueByLevel(ability,"endRadius")
	local speed = GetAbilitySpecialValueByLevel(ability,"speed")
	
	for var=1, 3 do
		local vVelocity = RotateVector2D(vector,angle * var - 120) * speed
		local info = {
			Source = caster,
			Ability = ability,
			EffectName = effectName,
			vSpawnOrigin = caster:GetAbsOrigin(),
			fDistance = distance,
			fStartRadius = beginRadius,
			fEndRadius = endRadius,
			vVelocity = vVelocity,
			bHasFrontalCone = true,
			bReplaceExisting = true,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			fExpireTime = GameRules:GetGameTime() + 20,
			bDeleteOnHit = false,
		}
		ProjectileManager:CreateLinearProjectile(info)
	end
end