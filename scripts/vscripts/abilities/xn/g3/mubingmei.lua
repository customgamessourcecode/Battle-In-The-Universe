---木冰眉：暴风雪
function mbm_snowStorm(keys)
	local ability = keys.ability
	local abililtyLevel = ability:GetLevel() - 1
	local caster = keys.caster
	
	local point = keys.target_points[1]
	
	local duration = ability:GetLevelSpecialValueFor("duration", abililtyLevel)
	local radius = ability:GetLevelSpecialValueFor("radius", abililtyLevel)
	local damage = ability:GetLevelSpecialValueFor("damage", abililtyLevel)
	
	local dummy = CreateDummyUnit(point,caster)
	AddDataDrivenModifier(ability,caster,dummy,"modifier_xn_MuBingMei_bfx_thinker",{})
	
	StartSoundEvent("hero_Crystal.freezingField.wind",dummy)
	
	local particle = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"
	local pid = CreateParticleEx(particle,PATTACH_ABSORIGIN,dummy)
	SetParticleControlEx(pid,0,point)
	SetParticleControlEx(pid,1,Vector(radius,1,1))
	
	local path = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
	TimerUtil.createTimer(function()
		if duration > 0 then
			local count = 10
			local interval = 1 / count
			TimerUtil.createTimer(function()
				if count > 0 then
					local p = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,dummy)
					local loc = RandomPosInRadius(point,radius)
					SetParticleControlEx(p,0,loc)
					EmitSoundOnLoc(loc,"hero_Crystal.freezingField.explosion",caster)
					count = count -1 
					return interval
				end
			end)
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			duration = duration - 1
			return 1
		else
			StopSoundEvent("hero_Crystal.freezingField.wind",dummy)
			EntityHelper.remove(dummy)
		end
	end)
end

---木冰眉：召唤水元素修改属性
function mbm_sys(keys)
	local ability = keys.ability
	local caster = keys.caster
	local unit = keys.target
	
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local model = "models/heroes/morphling/morphling.vmdl"
	local sound = "Hero_Morphling.attack"
	
	AddLuaModifier(caster,unit,"td_model_change",{model=model,sound=sound},ability)
	unit:SetBaseDamageMin(damage)		
	unit:SetBaseDamageMax(damage)
end