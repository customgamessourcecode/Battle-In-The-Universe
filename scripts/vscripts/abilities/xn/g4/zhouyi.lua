---周佚：雨之仙剑
function zy_ysxz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local path = "particles/terrain_fx/classical_fountain001_water.vpcf"
	local sound = "Hero_Razor.Storm.Loop"
	
	local dummy = CreateDummyUnit(target:GetAbsOrigin(),caster)
	EmitSound(dummy,sound)
	
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,dummy)
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			DamageEnemiesWithinRadius(dummy:GetAbsOrigin(),radius,caster,damage,ability)
			duration = duration - interval
			return interval
		else
			StopSoundOn(sound,dummy)
			EntityHelper.remove(dummy)
		end
	end)
end