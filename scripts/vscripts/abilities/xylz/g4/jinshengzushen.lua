---金圣祖神-回音击
function jszs_hyj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	
	local units = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
	if #units > 1 then
		damage = damage + damage * (#units - 1) * ratio / 100 
	end
	ApplyDamageEx(caster,units,ability,damage)
end

---金圣祖神：裂地沟壑
function jszs_ldgh_create(keys)
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local offset = GetAbilitySpecialValueByLevel(ability,"start_offset")
	
	local casterLoc = caster:GetAbsOrigin()
	local forward = GetForwardVector(casterLoc,point)
	local startPos = casterLoc + forward * offset
	local endPos = startPos + forward * length
	
	FakeWall.CreateCuboid(ability,startPos,length,width,forward,duration,function()
		local path = "particles/econ/items/earthshaker/earthshaker_gravelmaw/earthshaker_fissure_gravelmaw_gold.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
		SetParticleControlEx(pid,0,startPos)
		SetParticleControlEx(pid,1,endPos)
		SetParticleControlEx(pid,2,Vector(duration, 0, 0 ))
	end)
end
