--极星祖神：星魂
function jxzs_xh_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local dummys = caster.dummyUnits
	if not dummys then
		dummys = {}
		caster.dummyUnits = dummys
	end
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	
	if #dummys < count then
		local dummy = CreateDummyUnit(caster:GetAbsOrigin(),caster)
		AddDataDrivenModifier(ability,caster,dummy,"modifier_xylz_JiXingZuShen_xh_dummy",{})
		
		local path = "particles/units/heroes/hero_wisp/wisp_guardian_.vpcf"
		dummy.pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW, dummy)
		
		table.insert(dummys,dummy)
		
		if #dummys == 1 then
			ability.first_create_time = GameRules:GetGameTime()
		end
	end
end

---更新星魂的位置
function jxzs_xh_update(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local units = caster.dummyUnits
	if units and #units > 0 and ability.first_create_time then
		local elapsedTime	= GameRules:GetGameTime() - ability.first_create_time
		
		local casterOrigin = caster:GetAbsOrigin()
		
		local radius = GetAbilitySpecialValueByLevel(ability,"radius")
		local duration = GetAbilitySpecialValueByLevel(ability,"duration")
		--local interval = GetAbilitySpecialValueByLevel(ability,"update_interval")
		local angle = 360 / duration
		
		local currentRotationAngle	= elapsedTime * angle
		local rotationAngleOffset	= 360 / #units
		
		for k,unit in pairs(units) do
			-- Rotate
			local rotationAngle = currentRotationAngle - rotationAngleOffset * ( k - 1 )
			local relPos = Vector( 0, radius, 0 )
			relPos = RotatePosition( Vector(0,0,0), QAngle( 0, -rotationAngle, 0 ), relPos )
	
			local absPos = GetGroundPosition( relPos + casterOrigin, unit )
	
			unit:SetAbsOrigin( absPos )
	
			ParticleManager:SetParticleControl( unit.pid, 1, Vector( radius, 0, 0 ) )
		end
	end
end

---星魂碰撞
function jxzs_xh_hit(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	ApplyDamageEx(caster,target,ability,damage)
	
	---星怨buff
	local bonusBuff = ability.bonusBuff
	if not bonusBuff then
		bonusBuff = caster:FindModifierByName("modifier_xylz_JiXingZuShen_xy")
		ability.bonusBuff = bonusBuff
	end
	if bonusBuff then
		local bonusAbility = bonusBuff:GetAbility()
		local duration = GetAbilitySpecialValueByLevel(bonusAbility,"duration")
		local maxStack = GetAbilitySpecialValueByLevel(bonusAbility,"maxStack")
		
		local targetDebuff = target:FindModifierByName("modifier_xylz_JiXingZuShen_xy_debuff")
		if not targetDebuff then
			targetDebuff = AddDataDrivenModifier(bonusAbility,caster,target,"modifier_xylz_JiXingZuShen_xy_debuff",{})
		end
		if targetDebuff then
			--每次刷新持续时间，并叠加层数
			targetDebuff:SetDuration(duration,true)
			if targetDebuff:GetStackCount() < maxStack then
				targetDebuff:IncrementStackCount()
			end
		end
	end
end

---极星祖神：星爆
function jxzs_xb(keys)
	local ability = keys.ability;
	local caster = keys.caster;
	
	local units = caster.dummyUnits;
	if units and #units > 0 then
		local count = #units
		local radius = GetAbilitySpecialValueByLevel(ability,"radius")
		local damage = GetAbilitySpecialValueByLevel(ability,"damage") * count
		
		local path = "particles/units/heroes/hero_wisp/wisp_guardian_explosion.vpcf"
		for index=count, 1, -1 do
			local unit = units[index]
			EmitSound(unit,"Hero_Wisp.Spirits.Target")
			CreateParticleEx(path,PATTACH_ABSORIGIN,unit)
			EntityHelper.remove(unit)
			table.remove(units,index)
		end
		
		local enemies = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
		for key, enemy in pairs(enemies) do
			ApplyDamageEx(caster,enemy,ability,damage)
		end
	else
		ability:EndCooldown()
	end
end


---塔被移除的时候移除星魂
function jxzs_xh_destroy(keys)
	local caster = keys.caster;
	
	local units = caster.dummyUnits;
	if units then
		ClearUnitArray(units,true)
	end
end