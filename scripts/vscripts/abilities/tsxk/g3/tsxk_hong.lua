---洪：幻境枪法
function tsxk_hong_hjqf(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local path = "particles/tsxk/g3/hong_hjqf_ring.vpcf"
	local pCount = 3
	local length = radius / pCount
	for var=1, pCount do
		local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,duration)
		SetParticleControlEx(pid,1,Vector(length * var,0,0))
		SetParticleControlEx(pid,7,point)
	end
	
	local count = 8
	local angle = 360 / 8
	
	local units = {}
	local pos = RandomPosInRadius(point,radius,radius)
	for var=1, count do
		local unit =  CreateDummyUnit(pos,caster)
		ChangeModelTemporary(unit,caster:GetModelName(),duration)
		unit:SetForwardVector(GetForwardVector(pos,point))
		--播放攻击动作，StartGesture,StartGestureWithPlaybackRate
		TimerUtil.createTimer(function()
			if EntityNotNull(unit) then
				unit:StartGesture(ACT_DOTA_ATTACK)
				return 2
			end
		end)
		table.insert(units,unit)
		
		pos = RotateVector2DWithCenter(point,pos,angle)
	end
	
	TimerUtil.createTimerWithDelay(duration,function()
		for key, unit in pairs(units) do
			EntityHelper.remove(unit)
		end
	end)
end