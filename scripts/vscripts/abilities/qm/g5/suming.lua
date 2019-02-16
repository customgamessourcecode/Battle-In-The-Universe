
function sm_ssyy(keys)
	local caster = keys.caster
	local ability = keys.ability
	local bonus = GetAbilitySpecialValueByLevel(ability,"bonus")

	caster:GiveMana(bonus)
end


function sm_syststar(keys)
	local caster = keys.caster

	local ability = keys.ability

	local reduce = GetAbilitySpecialValueByLevel(ability,"reduce")

	caster.sm_syststar_start = true
	TimerUtil.createTimer(function()

			local count = caster:GetMana()
			if caster.sm_syststar_start == true and count > 20 then
				caster:ReduceMana(reduce)
				return 1
			end

			if ability:GetToggleState() == true then
				ability:ToggleAbility()
			end
	end )
end


function sm_syststop(keys)
	local caster = keys.caster
	caster.sm_syststar_start = false
	--停止声音
	--StopSoundOnEntity(caster,"Hero_Leshrac.Pulse_Nova")
end
