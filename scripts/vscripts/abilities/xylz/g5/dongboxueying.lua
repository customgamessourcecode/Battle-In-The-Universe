---东伯雪鹰：五相封禁术
function dbxy_wxfjs(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
--	local upDuration = 0.6
--	local upInterval = 0.03
	
	---用来承载光环的单位
	local auraUnit = CreateDummyUnit(point,caster)
	
	---地上的特效
--	local path = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_ring_lv.vpcf"
--	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,auraUnit)
--	SetParticleControlEx(pid,0,point)
--	SetParticleControlEx(pid,1,Vector(radius,radius,radius))
--	auraUnit.pid = pid
	
	---创建五个点，并连线。默认钻在地下，延迟一段时间慢慢钻出来
	local count = 5
	local angle = 360 / count
	local underGround = 0
	
	local towers = {}
	local modelName = "models/props_structures/tower_dragon_white.vmdl"
	local pos = RandomPosInRadius(point,radius,radius)
	for var=1, count do
		pos = RotateVector2DWithCenter(point,pos,angle)
		local tower = CreateDummyUnit(pos,caster)
		tower:SetForwardVector(GetForwardVector(pos,point))
		tower:SetModelScale(0.5)
		
		tower.origin = tower:GetAbsOrigin()
		tower:SetAbsOrigin(tower:GetAbsOrigin() + Vector(0,0,-underGround))
		ChangeModelTemporary(tower,modelName)
		
		table.insert(towers,tower)
	end
	
	
	
	local path = "particles/units/heroes/hero_wisp/wisp_tether.vpcf"
	--连接特效
	for index=1, count do
		local t1 = towers[index]
		local t2 = towers[index + 1]
		if index == count then
			t2 = towers[1]
		end
		local pid = CreateParticleEx(path,PATTACH_POINT_FOLLOW,t1)
		SetParticleControlEnt(pid,0,t1,PATTACH_POINT_FOLLOW,"attach_hitloc",t1:GetAbsOrigin())
		SetParticleControlEnt(pid,1,t2,PATTACH_POINT_FOLLOW,"attach_hitloc",t2:GetAbsOrigin())
		t1.pid = pid
	end

	--五个塔上浮结束（前后大约0.5秒），才正式生效禁锢
	AddDataDrivenModifier(ability,caster,auraUnit,"modifier_xylz_DongBoXueYing_wxfjs",{})
	---时间结束后，删掉所有的特效、单位
	TimerUtil.createTimerWithDelay(duration,function()
		EntityHelper.remove(auraUnit) --不清楚删除实体以后，归属于该实体的特效是否会删除，所以都强制删除一下
		
		for key, tower in pairs(towers) do
			ParticleManager:DestroyParticle(tower.pid,false)
			EntityHelper.remove(tower) --不清楚删除实体以后，归属于该实体的特效是否会删除，所以都强制删除一下
		end
	end)
	
--	--塔上浮
--	local p1 = "particles/econ/items/pudge/pudge_arcana/stone/pudge_arcana_dismember_flek_stone.vpcf"
--	local p2 = "particles/units/heroes/hero_medusa/medusa_stone_gaze_impact_dust.vpcf"
--	local upHeight = Vector(0,0,underGround / (upDuration / upInterval))
--	TimerUtil.createTimer(function()
--		if upDuration > 0 then
--			for key, tower in pairs(towers) do
--				tower:SetAbsOrigin(tower:GetAbsOrigin() + upHeight)
--				
--				local pid = CreateParticleEx(p1,PATTACH_ABSORIGIN,tower,0.1)
--				SetParticleControlEx(pid,0,tower.origin)
--				pid = CreateParticleEx(p2,PATTACH_ABSORIGIN,tower,0.1)
--				SetParticleControlEx(pid,0,tower.origin)
--			end
--			upDuration = upDuration - upInterval
--			return upInterval
--		else
--			local path = "particles/units/heroes/hero_wisp/wisp_tether.vpcf"
--			--连接特效
--			for index=1, count do
--				local t1 = towers[index]
--				local t2 = towers[index + 1]
--				if index == count then
--					t2 = towers[1]
--				end
--				local pid = CreateParticleEx(path,PATTACH_POINT_FOLLOW,t1)
--				SetParticleControlEnt(pid,0,t1,PATTACH_POINT_FOLLOW,"attach_hitloc",t1:GetAbsOrigin())
--				SetParticleControlEnt(pid,1,t2,PATTACH_POINT_FOLLOW,"attach_hitloc",t2:GetAbsOrigin())
--				t1.pid = pid
--			end
--		
--			--五个塔上浮结束（前后大约0.5秒），才正式生效禁锢
--			AddDataDrivenModifier(ability,caster,auraUnit,"modifier_xylz_DongBoXueYing_wxfjs",{})
--			---时间结束后，删掉所有的特效、单位
--			TimerUtil.createTimerWithDelay(duration,function()
--				EntityHelper.remove(auraUnit) --不清楚删除实体以后，归属于该实体的特效是否会删除，所以都强制删除一下
--				
--				for key, tower in pairs(towers) do
--					ParticleManager:DestroyParticle(tower.pid,false)
--					EntityHelper.remove(tower) --不清楚删除实体以后，归属于该实体的特效是否会删除，所以都强制删除一下
--				end
--			end)
--		end
--	end)
end

---浑源七击，范围内每多一个水系单位，伤害提升100%
function dbxy_hyqj(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	if units and #units > 0 then
		local count = 0
		for _, unit in pairs(units) do
			if Elements.GetAttackElement(unit) == Elements.water and unit.TD_IsTower then
				count = count + 1;
			end
		end
		local modifier = "modifier_xylz_DongBoXueYing_hyqj_damage"
		if ability.group_bonus then
			modifier = "modifier_xylz_DongBoXueYing_hyqj_group"
			
			if caster:HasModifier("modifier_xylz_DongBoXueYing_hyqj_damage") then
				caster:RemoveModifierByName("modifier_xylz_DongBoXueYing_hyqj_damage")
			end
		elseif caster:HasModifier("modifier_xylz_DongBoXueYing_hyqj_group") then
			caster:RemoveModifierByName("modifier_xylz_DongBoXueYing_hyqj_group")
		end
		
		local tooltip = caster:FindModifierByName(modifier);
		if not tooltip then
			tooltip = AddDataDrivenModifier(ability,caster,caster,modifier,{})
		end
		if tooltip and tooltip:GetStackCount() ~= count then
			tooltip:SetStackCount(count)
		end
	end
end