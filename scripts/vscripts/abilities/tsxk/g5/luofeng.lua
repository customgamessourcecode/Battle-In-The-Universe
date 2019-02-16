function lf_myc(keys)
	local ability = keys.ability
	local caster = keys.caster
	local startLoc = caster:GetAbsOrigin()
	local point = keys.target_points[1]
	
	local forward = GetForwardVector(startLoc,point)
	
	local distance = GetAbilitySpecialValueByLevel(ability,"distance")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local speed = GetAbilitySpecialValueByLevel(ability,"speed")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	
	local effect = "particles/tsxk/g1/luofeng_myc.vpcf"
	
	CreateProjectileNoTarget(caster,ability,effect,startLoc,distance,radius,radius,forward * speed)
end

---罗峰：星辰塔
function lf_xct(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local modifier = "modifier_tsxk_LuoFeng_xct"
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local delay = 0.5
	local path = "particles/tsxk/g1/luofeng_xct.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
	SetParticleControlEx(pid,0,point)
	SetParticleControlEx(pid,1,point + Vector(0,0,600))
	SetParticleControlEx(pid,2,Vector(delay,0,0))
	SetParticleControlEx(pid,4,Vector(0.5,0.5,0.5))
	
	TimerUtil.createTimerWithDelay(delay,function()
		caster:StopSound("Hero_Invoker.ChaosMeteor.Loop")
		EmitSoundOnLoc(point,"Hero_Invoker.ChaosMeteor.Impact",caster)
		local units = FindEnemiesInRadiusEx(caster,point,radius)
		if units and #units > 0 then
			for key, unit in pairs(units) do
				ApplyDamageEx(caster,unit,ability,damage)
				AddDataDrivenModifier(ability,caster,unit,modifier)
			end
		end
	end)
	
end

---罗峰：弑吴羽翼
function lf_swyy(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local distance = GetAbilitySpecialValueByLevel(ability,"distance")
	local speed = GetAbilitySpecialValueByLevel(ability,"speed")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	local interval = duration / count
	
	local effect = "particles/tsxk/g1/luofeng_swyy.vpcf"
	local forward = GetForwardVector(caster:GetAbsOrigin(),point)
	local startLoc = caster:GetAbsOrigin() + forward * 100
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			--随机方向
			local vVelocity = speed * RotateVector2D(forward,RandomInt(-10,10))
			EmitSound(caster,"Hero_Silencer.GlaivesOfWisdom")
			CreateProjectileNoTarget(caster,ability,effect,startLoc,distance,radius,radius,vVelocity)
			duration = duration - interval
			return interval
		end
	end)
end