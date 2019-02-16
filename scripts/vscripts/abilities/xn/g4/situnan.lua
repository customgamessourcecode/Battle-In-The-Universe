---司徒南：寂灭指（KV调用）
function stn_jmz(keys)
	stn_jmz_damage(keys.caster,keys.ability,keys.target)
end


---司徒南：寂灭指伤害(LUA调用)
function stn_jmz_damage(caster,ability,target)
	local modifier = DealWithUnitDeath(target,function(attacker,attackAbility)
		if attackAbility == ability then
			local damage = target.stn_jmz_damage
			
			local radius = GetAbilitySpecialValueByLevel(ability,"damage_radius")
			local enemies = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
			if enemies and #enemies > 0 then
				local unit = enemies[1]
				
				local path = "particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf"
				local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,unit)
				SetParticleControlEx(pid,0,target:GetAbsOrigin())
				SetParticleControlEx(pid,1,unit:GetAbsOrigin())
				
				--伤害翻倍
				damage = damage * 2
				unit.stn_jmz_damage = damage
				
				stn_jmz_damage(caster,ability,unit)
			end
		end
	end,caster,ability)
	
	local damage = target.stn_jmz_damage
	if not damage then
		damage = GetAbilitySpecialValueByLevel(ability,"damage")
		target.stn_jmz_damage = damage
	end
	ApplyDamageEx(caster,target,ability,damage)
	--伤害后单位并没有死亡，则销毁掉该modifier。保证每次都是单独的逻辑
	if EntityIsAlive(target) then
		target.stn_jmz_damage = nil
		if modifier then
			modifier:Destroy()
		end
	end
end

---司徒南：黄泉升窍决
function stn_hqsqj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	---缓存起来，在塔被收回的时候，立刻销毁掉
	local dummys = ability._dummys
	if not dummys then
		dummys = {}
		ability._dummys = dummys
	end
	--移除掉已经消失的单位，要不然越堆越多
	RemoveDiedEntityInArray(dummys)
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local damageDummy = CreateDummyUnit(point,caster)
	AddDataDrivenModifier(ability,caster,damageDummy,"modifier_xn_SiTuNan_hqlqj",{duration=duration})
	table.insert(dummys,damageDummy)
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local randomRadius = radius / 2
	local pos = RandomPosInRadius(point,randomRadius,randomRadius) + Vector(0,0,150)
	
	local flyModel = CreateDummyUnit(pos,caster)
	table.insert(dummys,flyModel)
	flyModel.center = point
	flyModel.pos = pos
	local modelName = "models/heroes/dark_willow/dark_willow_wisp.vmdl"
	ChangeModelTemporary(flyModel,modelName,duration)
	AddDataDrivenModifier(ability,caster,flyModel,"modifier_xn_SiTuNan_hqlqj_fly",{duration=duration})
	--模拟飞行
	TimerUtil.createTimer(function()
		if EntityNotNull(flyModel) then
			local center = flyModel.center
			local pos = flyModel.pos
			
			local newPos = RotateVector2DWithCenter(center,pos,8)
			flyModel:SetForwardVector(GetForwardVector(pos,newPos))
			flyModel:SetAbsOrigin(newPos)
			flyModel.pos = newPos
			
			return 0.01
		end
	end)
	TimerUtil.createTimerWithDelay(duration,function()
		EntityHelper.remove(flyModel)
		EntityHelper.remove(damageDummy)
	end)
	
end

---塔被收回，立刻销毁虚拟单位
function stn_hqsqj_destroy(keys)
	local ability = keys.ability
	---缓存起来，在塔被收回的时候，立刻销毁掉
	local dummys = ability._dummys
	if dummys then
		ClearUnitArray(dummys)
	end
end
