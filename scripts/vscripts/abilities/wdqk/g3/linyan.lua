---林炎：火虎
function linyan_hh(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]

	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	local speed = GetAbilitySpecialValueByLevel(ability,"speed")
	
	
	local casterOrigin = caster:GetAbsOrigin()
	local direction = GetForwardVector(casterOrigin,point)
	local vVelocity = direction * speed
	
	local effect = "particles/units/heroes/hero_jakiro/jakiro_dual_breath_fire.vpcf"
	CreateProjectileNoTarget(caster,ability,effect,casterOrigin,length,width/2,width/2,vVelocity,false)
end

---林炎：火蟒
function linyan_hm(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
		ability._pid = nil
	end
	if ability._dummys then
		ClearUnitArray(ability._dummys,true)
		ability._dummys = nil
	end
	
	---垂直放置
	local direction = RotateVector2D(GetForwardVector(caster:GetAbsOrigin(),point),90)
	local startPos = point - direction * length / 2
	local endPos = point + direction * length / 2
	
	local particleName = "particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf"
	local pid = CreateParticleEx(particleName,PATTACH_ABSORIGIN,caster,duration)
	ParticleManager:SetParticleControl( pid, 0, startPos )
	ParticleManager:SetParticleControl( pid, 1, endPos )
	ParticleManager:SetParticleControl( pid, 2, Vector( duration, 0, 0 ) )
	ability._pid = pid
	
	local diameter = radius * 2
	local dummys = {}
	local count = math.ceil(length / diameter)
	for index=1, count do
		local dummy = CreateDummyUnit(startPos + direction * (diameter * index - radius),caster)
		AddDataDrivenModifier(ability,caster,dummy,"modifier_wdqk_LinYan_hm_dummy",{})
		table.insert(dummys,dummy)
	end
	ability._dummys = dummys
	
	TimerUtil.createTimerWithDelay(duration,function()
		for key, dummy in pairs(dummys) do
			EntityHelper.kill(dummy)
		end
		ability._dummys = nil
		ability._pid = nil
	end)
end

---塔移除，火蟒移除
function linyan_hm_destroy(keys)
	local ability = keys.ability
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
		ability._pid = nil
	end
	if ability._dummys then
		ClearUnitArray(ability._dummys,true)
		ability._dummys = nil
	end
end