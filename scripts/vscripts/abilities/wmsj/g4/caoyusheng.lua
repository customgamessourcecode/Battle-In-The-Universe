---曹雨生（习泽）：渡劫纹
function cys_djw(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	


	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local path = "particles/units/heroes/hero_razor/razor_rain_storm.vpcf"
	local sound = "Hero_Razor.Storm.Loop"
	
	local dummy = CreateDummyUnit(point,caster)
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

---曹雨生（习泽）:吞天魔盖
function cys_ttmg(keys)
	local caster = keys.caster
	local ability = keys.ability
	local units = keys.target_entities
	
	if units and #units > 0 then
		local damage = GetAbilitySpecialValueByLevel(ability,"damage")
		local duration = 0
		if ability.group_bonus then
			--风霜之水组合效果
			duration = GetAbilitySpecialValueByLevel(ability,"stunDuration_group")
		else
			duration = GetAbilitySpecialValueByLevel(ability,"stunDuration")
		end
		
		for _, target in pairs(units) do
			ApplyDamageEx(caster,target,ability,damage)
			AddDataDrivenModifier(ability,caster,target,"modifier_wmsj_CaoYuSheng_ttmg",{duration=duration})
		end
	end
	
end
