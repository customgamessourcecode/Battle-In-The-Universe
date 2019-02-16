
function tq_yyntbj(keys)

	local caster = keys.caster

	local ability = keys.ability

	local duration = GetAbilitySpecialValueByLevel(ability,"duration")

	local damage = GetAbilitySpecialValueByLevel(ability,"damage") / 10

	local path = "particles/phoenix/phoenix_sunray.vpcf"

	local path2 = "particles/units/heroes/heroes_underlord/abyssal_underlord_darkrift_target.vpcf"

	local pid =  CreateParticleEx(path,PATTACH_OVERHEAD_FOLLOW,caster,duration)

	local pid2 = CreateParticleEx(path2,PATTACH_OVERHEAD_FOLLOW,caster,duration)

	SetParticleControlEx( pid2, 1, caster:GetAbsOrigin())

	local count = 0

	TimerUtil.createTimer(function()
		if count < duration * 10 then

			local casterOrigin	= caster:GetAbsOrigin()

			local casterForward	= caster:GetForwardVector()

			casterOrigin = casterOrigin + casterForward * 1000

			SetParticleControlEx( pid, 1, casterOrigin)

			local units = FindEnemiesInLineEx(caster,caster:GetAbsOrigin(),casterOrigin,200,DOTA_UNIT_TARGET_FLAG_NONE)

			for key, unit in pairs(units) do
				ApplyDamageEx(caster,unit,ability,damage)
			end

			count = count + 1
		end
		return 0.1
	end )

end
