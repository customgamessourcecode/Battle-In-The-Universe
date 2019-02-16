---牧尘：四神星宿经
function mc_ssxxj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local center = keys.target_points[1]
	
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	radius = 350
	
	local units = ability.units
	if not units then
		units = {}
		ability.units = units
	else
		for var=#units, 1 , -1 do
			local unit = units[var]
			EntityHelper.remove(unit)
			table.remove(units,var)
		end
	end
	
	local auraUnit = CreateDummyUnit(center,caster)
	AddDataDrivenModifier(ability,caster,auraUnit,"modifier_dzz_MuChen_ssxxj_dummy",{})
	table.insert(units,auraUnit)
	
	local path = "particles/dzz/muchen_ssxxj_ring.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,auraUnit)
	SetParticleControlEx(pid,1,Vector(radius,radius,radius))
	
	--青龙，东
	local model = "models/unit/long/long_body.vmdl"
	local pos = center + Vector(1,0,0) * radius
	local unit = CreateDummyUnit(pos,caster)
	unit:SetForwardVector(GetForwardVector(pos,center))--这个模型方向是反的
	unit:SetModelScale(3)
	ChangeModelTemporary(unit,model)
	unit:SetAbsOrigin(unit:GetAbsOrigin() + Vector(0,0,-50))
	table.insert(units,unit)
	
	--白虎，西
	model = "models/unit/huw/hu_body.vmdl"
	pos = center + Vector(-1,0,0) * radius
	unit = CreateDummyUnit(pos,caster)
	unit:SetForwardVector(GetForwardVector(pos,center))--这个模型方向是反的
	unit:SetModelScale(0.5)
	ChangeModelTemporary(unit,model)
	table.insert(units,unit)
	
	--朱雀，南
	model = "models/unit/fenghuang/zhuque_body.vmdl"
	pos = center + Vector(0,-1,0) * radius
	unit = CreateDummyUnit(pos,caster)
	unit:SetForwardVector(GetForwardVector(pos,center))--这个模型方向是反的
	unit:SetModelScale(5)
	ChangeModelTemporary(unit,model)
	table.insert(units,unit)
	
	--玄武，北
	model = "models/unit/xuanwu/xuanwu_body.vmdl"
	pos = center + Vector(0,1,0) * radius
	unit = CreateDummyUnit(pos,caster)
	unit:SetForwardVector(GetForwardVector(pos,center))--这个模型方向是反的
	unit:SetModelScale(0.25)
	ChangeModelTemporary(unit,model)
	table.insert(units,unit)
	
end

---牧尘：四神星宿经，单位死亡，收回星宿
function mc_ssxxj_destroy(keys)
	local ability = keys.ability
	local units = ability.units
	if units then
		for var=#units, 1 , -1 do
			local unit = units[var]
			table.remove(units,var)
			EntityHelper.remove(unit)
		end
	end
end