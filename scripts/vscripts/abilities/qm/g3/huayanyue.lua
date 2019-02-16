---花颜月：万鬼朝拜
function hyy_wgcb(keys)
	local ability = keys.ability
	local caster = keys.caster

	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	local dummys = 	ability.dummys
	if not dummys then
		dummys = {}
		ability.dummys = dummys
	else
		for var=#dummys, 1,-1 do
			local dummy = dummys[var]
			EntityHelper.remove(dummy)
			table.remove(dummys,var)
		end
	end
	local center = caster:GetAbsOrigin()
	
	local moveSpeed = GetAbilitySpecialValueByLevel(ability,"move_speed")
	local moveInterval = 0.03
	local step = moveSpeed * moveInterval
	
	local glow = "particles/units/heroes/hero_death_prophet/death_prophet_spirit_glow.vpcf"
	local model = "particles/units/heroes/hero_death_prophet/death_prophet_spirit_model.vpcf"
	
	for var=1, count do
		local dummy = CreateDummyUnit(RandomPosInRadius(center,20,50),caster)
		AddDataDrivenModifier(ability,caster,dummy,"modifier_qm_HuaYanYue_wgcb_dummy",{})
		table.insert(dummys,dummy)
		
		CreateParticleEx(model,PATTACH_ABSORIGIN_FOLLOW,dummy)
		CreateParticleEx(glow,PATTACH_ABSORIGIN_FOLLOW,dummy)
		
		
		local point = RandomPosInRadius(center,radius,radius / 2)
		
		local direction = GetForwardVector(dummy:GetAbsOrigin(),point)
		dummy:SetForwardVector(direction)
		
		local returning = false
		local attackingUnit = nil
		local rotating1 = 0
		local rotating2 = 0
		
		TimerUtil.createTimer(function()
			if EntityNotNull(dummy) then
				local pos = dummy:GetAbsOrigin()
	
				local distance = GetDistance2D(pos,point)
				if distance <= 50 then
					returning = false
					local hasNewTarget = false
					local enemies = FindEnemiesInRadiusEx(caster,center,radius)
					if #enemies > 0 then
						for key, unit in pairs(enemies) do
							if unit ~= attackingUnit then
								point = unit:GetAbsOrigin()
								hasNewTarget = true;
								break;
							end
						end
					end
					if not hasNewTarget then
						if GetDistance2D(pos,center) < 50 then --如果当前是靠近中心的，选择一个外围的点，避免卡在中心点
							point = RandomPosInRadius(center,radius,radius / 2)
						else
							if RollPercent(50) then
								point = center
							else
								point = RandomPosInRadius(center,radius,radius / 2)
							end
						end
					end
				else
					distance = GetDistance2D(pos,center)
					if distance > radius and not returning then
						local hasNewTarget = false
						local enemies = FindEnemiesInRadiusEx(caster,center,radius)
						if #enemies > 0 then
							for key, unit in pairs(enemies) do
								if unit ~= attackingUnit then
									point = unit:GetAbsOrigin()
									hasNewTarget = true;
									break;
								end
							end
						end
						
						if not hasNewTarget then
							if RollPercent(50) then
								point = center
							else
								point = RandomPosInRadius(center,radius,radius / 2)
							end
						end
						returning = true
					else
						local forward = dummy:GetForwardVector()
						direction = GetForwardVector(pos,point)
						
						local angle_difference = RotationDelta(VectorToAngles(forward), VectorToAngles(direction)).y
						if math.abs(angle_difference) < 10 then
							forward = direction
							dummy:SetForwardVector(forward)
							rotating1 = 0
							rotating2 = 0
						elseif angle_difference > 0 then
							forward = RotateVector2D(forward,10)
							dummy:SetForwardVector(forward)
							rotating1 = rotating1 + 1
							
							--原地绕圈一周了，重新随机一个点。有些位置比较特殊，会一直原地旋转
							if rotating1 >= 36 then
								rotating1 = 0
								point = RandomPosInRadius(center,radius,radius / 2)
							end
							
						else
							forward = RotateVector2D(forward,-10)
							dummy:SetForwardVector(forward)
							rotating2 = rotating2 + 1
							
							--原地绕圈一周了，重新随机一个点
							if rotating2 >= 36 then
								rotating2 = 0
								point = RandomPosInRadius(center,radius,radius / 2)
							end
						end
						
						local newPos = pos + forward * step
						dummy:SetAbsOrigin(newPos)
					end
				end
				
				return moveInterval
			end
		end)
	end
end

---塔死亡（被收回），删掉所有的鬼魂
function hyy_wgcb_death( keys )
	local ability = keys.ability
	local caster = keys.caster

	StopSoundOnEntity(caster,"qm.hyy_wgcb")
	
	local dummys = ability.dummys
	if dummys then
		ClearUnitArray(dummys)
	end
end