---圣主：雷霆道伤害
function sz_ldt_damage(source,unit,ability,damage,particle,jumpChance,jumpRadius,jumpDelay)
	local caster = ability:GetCaster()
	
	EmitSound(unit,"Hero_Zuus.ArcLightning.Target")

	local pid = CreateParticleEx(particle,PATTACH_CUSTOMORIGIN,unit)
	local casterLoc = source:GetAbsOrigin()
	local targetLoc = unit:GetAbsOrigin()
	SetParticleControlEx(pid,0,Vector(casterLoc.x,casterLoc.y,casterLoc.z + source:GetBoundingMaxs().z))
	SetParticleControlEx(pid,1,Vector(targetLoc.x,targetLoc.y,targetLoc.z + unit:GetBoundingMaxs().z))
	
	ApplyDamageEx(caster,unit,ability,damage)
	
	if jumpChance and jumpRadius then
		if RandomLessInt(jumpChance) then
			local units = FindEnemiesInRadiusEx(caster,unit:GetAbsOrigin(),jumpRadius)
			if #units > 0 then
				for key, newUnit in pairs(units) do
					if newUnit ~= unit then
						TimerUtil.createTimerWithDelay(jumpDelay,function()
							sz_ldt_damage(unit,newUnit,ability,damage,particle,jumpChance,jumpRadius,jumpDelay)					
						end)
						break;
					end
				end
			end
		end
	end
end

---圣主：雷霆道
function sz_ltd(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local radius = ability:GetCastRange()
	local jumpChance = nil
	local jumpRadius = nil
	local jumpDelay = nil
	local bonusBuff = caster:FindModifierByName("modifier_xylz_ShengZhu_lthmd")
	if bonusBuff then
		jumpChance = GetAbilitySpecialValueByLevel(bonusBuff:GetAbility(),"chance")
		jumpRadius = GetAbilitySpecialValueByLevel(bonusBuff:GetAbility(),"radius")
		jumpDelay = GetAbilitySpecialValueByLevel(bonusBuff:GetAbility(),"delay")
		if jumpDelay == 0 then
			jumpDelay = 0.3 -- 不加延迟的话运气好一瞬间触发很多特效就卡死了
		end
	end
	
	local path = "particles/units/heroes/hero_zuus/zuus_arc_lightning_.vpcf"
	sz_ldt_damage(caster,target,ability,damage,path,jumpChance,jumpRadius,jumpDelay)
	
	count = count -1 
	if count > 0 then
		local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
		for key, unit in pairs(units) do
			if count > 0 and unit ~= target then
				sz_ldt_damage(caster,unit,ability,damage,path,jumpChance,jumpRadius,jumpDelay)
				count = count - 1
			end
		end
	end
end
