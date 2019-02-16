---彩鳞：蛇潮
function cailin_sc(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	radius = 350
	local casterLoc = caster:GetAbsOrigin()
	local targetLoc = keys.target_points[1]
	
	local forwardVec = targetLoc - casterLoc
	forwardVec = forwardVec:Normalized()
	local velocityVec = Vector( forwardVec.x, forwardVec.y, 0 )
	
	local total = 30
	local collision_radius = 100
	
	local effect = "particles/dpcq/cailin_sc.vpcf"
	for var=1, total do
		local spawn_location = RandomPosInRadius(targetLoc,radius)
		CreateProjectileNoTarget(caster,ability,effect,spawn_location,length,collision_radius,collision_radius,velocityVec * 500,false)
	end
end

---彩鳞:蛇阵
function cailin_sz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local modifier = "modifier_dpcq_CaiLin_sz"
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local dummy = CreateDummyUnit(point,caster)
	ability._dummy = dummy
	AddDataDrivenModifier(ability,caster,dummy,modifier,{duration=duration})
	TimerUtil.createTimerWithDelay(duration,function()
		EntityHelper.remove(dummy)
		ability._dummy = nil
	end)
	
	local path = "particles/dpcq/cailin_sz.vpcf"
	local count = 15
	local step = 360 / count
	local pos = nil
	for num=1, count do
		if pos then
			local angle = math.rad(step)
			local x = (pos.x - point.x)*math.cos(angle) - (pos.y - point.y)*math.sin(angle) + point.x
			local y = (pos.x - point.x)*math.sin(angle) + (pos.y - point.y)*math.cos(angle) + point.y
			pos = GetGround(Vector(x,y,point.z),nil)
			
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy)
			SetParticleControlEx(pid,0,pos)
			ParticleManager:SetParticleControlForward(pid,3,point - pos)
		else
			pos = point+RandomVector(radius)
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy)
			SetParticleControlEx(pid,0,pos)
			ParticleManager:SetParticleControlForward(pid,3,point - pos)
		end
	end
	
	path = "particles/dpcq/cailin_sz_ring.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,dummy,duration)
	SetParticleControlEx(pid,7,point)
	SetParticleControlEx(pid,0,Vector(radius,0,0))
	
end

---彩鳞被收回，销毁蛇阵
function cailin_sz_destroy(keys)
	local ability = keys.ability
	if ability._dummy then
		EntityHelper.remove(ability._dummy)
		ability._dummy = nil
	end
end