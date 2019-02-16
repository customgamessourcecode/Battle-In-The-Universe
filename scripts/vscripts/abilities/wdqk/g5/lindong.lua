---林动：吞噬祖符
function ld_tszf(keys)
	local ability = keys.ability
	local caster = keys.caster 
	local target = keys.target
	
	local delay = GetAbilitySpecialValueByLevel(ability,"delay")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	local modelScale = target:GetModelScale()
	target:SetModelScale(0)
	
	TimerUtil.createTimerWithDelay(delay,function()
		target:SetModelScale(modelScale)
		
		local path = "particles/units/heroes/hero_shadow_demon/shadow_demon_loadout.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target)
		SetParticleControlEx(pid,0,target:GetAbsOrigin())
		SetParticleControlEx(pid,2,target:GetAbsOrigin())
		SetParticleControlEx(pid,3,Vector(radius,0,0))
	end)
end

---林动：祖符之眼
function ld_zfzy( keys )
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
		
	local center = target:GetAbsOrigin()

	local speed = GetAbilitySpecialValueByLevel(ability,"speed") / 10
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local units = FindEnemiesInRadiusEx(caster,center,radius)

	for i,unit in ipairs(units) do
		local unitPos = unit:GetAbsOrigin()
		local direction = GetForwardVector(unitPos,center)
		
		
		local newPos = unitPos + speed * direction
		
		local distance = GetDistance2D(unitPos,center)
		if distance <= speed then
			newPos = center
		end
		
		if CanFindPath(unitPos,newPos) then
			Teleport(unit,newPos)
		end
	end
end