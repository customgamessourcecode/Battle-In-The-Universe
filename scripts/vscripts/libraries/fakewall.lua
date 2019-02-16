---在游戏中虚拟"一堵墙"
local m = {}

---将墙内的单位移出去
local CuboidMoveUnit = function(caster,startPos,endPos,direction,width)
	local units = FindEnemiesInLineEx(caster,startPos,endPos,width)
	
	for i,unit in ipairs(units) do
		local unitPos = unit:GetAbsOrigin()
		local vDistance = unitPos - startPos
		local distance = (vDistance):Length2D()
		local targetDirection = (vDistance):Normalized()
	
		local targetAngle = math.atan2(targetDirection.y, targetDirection.x)
		local wallAngle = math.atan2(direction.y, direction.x)
	
		--获取目标位置，在墙体投影点到墙的起点的距离
		local perpen_distance = math.abs(math.cos(wallAngle - targetAngle)) * distance
		--目标位置在墙上的投影点
		local perpen_position = startPos + perpen_distance * direction
		--移动方向
		local moveDirection = GetForwardVector(perpen_position,unitPos)
		--移动距离，加一个缓冲区20码
		local moveDistance = width + 20
		
		---要使用地面坐标，否则可能会钻进地里或者飞在天上，就不会移动了。
		--能过去的位置才能移动，否则就算卡在特效里，也不动。避免被推上高台
		local newPos = GetGroundPosition(unitPos + moveDistance * moveDirection,unit)
		if GridNav:CanFindPath(unitPos,newPos) then
			unit:SetAbsOrigin(newPos)
		else
			--过不去，尝试相反的方向
			newPos = GetGround(RotateVector2DWithCenter(perpen_position,newPos,180),unit)
			if GridNav:CanFindPath(unitPos,newPos) then
				unit:SetAbsOrigin(newPos)
			end
		end
	end
end

---检查单位是否在合理的位置
local CuboidCheck = function(dummyUnit,target)
	local ability = dummyUnit.fw_ability
	local width = dummyUnit.fw_width
	local wallDirection = dummyUnit.fw_direction
	local startPos = dummyUnit.fw_startPos
	
	local vDistance = target:GetAbsOrigin() - startPos
	local distance = (vDistance):Length2D()
	local direction = (vDistance):Normalized()

	local targetAngle = math.atan2(direction.y, direction.x)
	local targetAngleDegree = math.deg(targetAngle) + 180

	local wallAngle = math.atan2(wallDirection.y, wallDirection.x)
	local wallAngleDegree = math.deg(wallAngle) + 180
	--目标距离墙体的垂直距离
	local perpen_distance = math.abs(math.sin(wallAngle - targetAngle)) * distance

	--目标面向角度
	local faceAngle = target:GetAnglesAsVector().y
	
	if (targetAngleDegree - wallAngleDegree) < 0 
		and perpen_distance <= width + 20 
		and ((faceAngle - wallAngleDegree < 0 and faceAngle - wallAngleDegree > -180) 
				or (faceAngle - wallAngleDegree > 180)) then
		if not target:FindModifierByNameAndCaster("td_fakewall_move_control",dummyUnit) then
			AddLuaModifier(dummyUnit,target,"td_fakewall_move_control",{},ability)
		end
	elseif (targetAngleDegree - wallAngleDegree) > 0
		and perpen_distance <= width + 20 
		and ((faceAngle - wallAngleDegree > 0 and faceAngle - wallAngleDegree < 180) 
				or (faceAngle - wallAngleDegree < -180)) then
		if not target:FindModifierByNameAndCaster("td_fakewall_move_control",dummyUnit) then
			AddLuaModifier(dummyUnit,target,"td_fakewall_move_control",{},ability)
		end
	else
		target:RemoveModifierByNameAndCaster("td_fakewall_move_control",dummyUnit)
	end

end

---位置检查的modifier被销毁，移除减速效果
local function DestroyChecker(dummyUnit,target)
	---这里直接移除同名效果，不再依赖dummyUnit，避免dummyUnit没有了，从而不能成功移除debuff。
	--对于有多个阻塞效果的，移除掉buff也不会影响太大，因为仍然存在的阻隔效果会再次添加上该buff
	target:RemoveModifierByName("td_fakewall_move_control")
	AddLuaModifier(nil,target,"modifier_phase",{duration=0.1})
end

---创建一堵立方体形的墙。
--@param #handle ability 技能
--@param #vector startPos 开始点坐标
--@param #number length 长度
--@param #number width 墙的宽度
--@param #vector direction 墙的走向
--@param #number duration 墙持续的时间
--@param #function particleCreator 创建特效用的函数
--@return #handle 返回创建的虚拟单位实体
function m.CreateCuboid(ability,startPos,length,width,direction,duration,particleCreator)
	
	local wallAngle = math.atan2(direction.y, direction.x)
	local wallAngleDegree = math.deg(wallAngle) + 180

	---中间点，用来放置虚拟单位，提供检测位置的光环。
	--该光环直径设置为比长度稍长，这样无论从哪个方向进入墙的范围，都会被加上这个光环
	--虽然对于矩形的墙来说有点多余。。。
	local center = startPos + direction * (length / 2)
	local auraRadius = length / 2
	
	local dummy = CreateDummyUnit(center,ability:GetCaster())
	dummy.fw_caster = ability:GetCaster()
	dummy.fw_ability = ability
	dummy.fw_startPos = startPos
	dummy.fw_direction = direction
	dummy.fw_width = width
	
	dummy.fw_Checker = CuboidCheck
	dummy.fw_CheckerDestroyer = DestroyChecker
	
	---这里使用的caster是谁，这个aura和aura创建的modifier里面都会用该caster作为caster。
	--为了保持每一个技能的逻辑独立，这里的caster都设置为虚拟单位
	AddLuaModifier(dummy,dummy,"td_fakewall_aura",{radius=auraRadius},ability)
	
	--持续时间结束了移除虚拟单位
	if type(duration) == "number" then
		TimerUtil.createTimerWithDelay(duration,function()
			--直接移除会导致光环添加的buff在销毁的时候处理失败，从而导致单位的移动速度不会恢复
			EntityHelper.kill(dummy)
		end)
	end
	
	--创建特效
	if particleCreator then
		xpcall(particleCreator,
			function (msg)--错误不返回了，直接输出
				DebugPrint(msg..'\n'..debug.traceback()..'\n')
			end)
	end
	
	local endPos = startPos + length * direction
	CuboidMoveUnit(ability:GetCaster(),startPos,endPos,direction,width)
	
	return dummy
end

---开始的时候将单位移出去
local CylinderMoveUnit = function(caster,center,radius)
	local units = FindEnemiesInRadiusEx(caster,center,radius)
	if #units > 0 then
		for key, unit in pairs(units) do
			local loc = unit:GetAbsOrigin()
			local distance = GetDistance2D(loc,center)
			local direction = GetForwardVector(center,loc)
			
			local diff = radius + 20 - distance
			if diff >= 0 then
				--要使用地面坐标，否则可能会钻进地里或者飞在天上，就不会移动了
				local newPos = GetGroundPosition(loc + direction * diff,unit)
				if GridNav:CanFindPath(loc,newPos) then
					unit:SetAbsOrigin(newPos)
				else
					--尝试四次
					local count = 3
					newPos = GetGround(RotateVector2DWithCenter(center,newPos,90),unit)
					while not GridNav:CanFindPath(loc,newPos) and count > 0 do
						newPos = GetGround(RotateVector2DWithCenter(center,newPos,90),unit)
						count = count - 1
					end
					if GridNav:CanFindPath(loc,newPos) then
						unit:SetAbsOrigin(newPos)
					end
				end
			end
		end
	end
end

---圆柱检查位置检查
local CylinderCheck = function (dummyUnit,target)
	local ability = dummyUnit.fw_ability
	local center = dummyUnit.fw_center
	local radius = dummyUnit.fw_radius
	
	local vDistance = target:GetAbsOrigin() - center
	local distance = (vDistance):Length2D()
	local direction = (vDistance):Normalized()

	local targetAngle = math.deg(math.atan2(direction.y, direction.x)) + 180

	--目标面向角度
	local faceAngle = target:GetAnglesAsVector().y
	if distance <= radius then
		if not target:FindModifierByNameAndCaster("td_fakewall_move_control",dummyUnit) then
			AddLuaModifier(dummyUnit,target,"td_fakewall_move_control",{},ability)
		end
	elseif distance - radius <= 20 and ((faceAngle - targetAngle >= -90 and faceAngle - targetAngle <= 90) or faceAngle - targetAngle > 270) then
		if not target:FindModifierByNameAndCaster("td_fakewall_move_control",dummyUnit) then
			AddLuaModifier(dummyUnit,target,"td_fakewall_move_control",{},ability)
		end
	else
		target:RemoveModifierByNameAndCaster("td_fakewall_move_control",dummyUnit)
	end
end

---创建一堵圆柱形的障碍物。
--@param #handle ability 技能
--@param #vector center 中心点
--@param #number radius 半径
--@param #number duration 墙持续的时间
--@param #function particleCreator 创建特效用的函数
--@return #handle 返回创建的虚拟单位实体
function m.CreateCylinder(ability,center,radius,duration,particleCreator)
	local caster = ability:GetCaster()
	local dummy = CreateDummyUnit(center,caster)
	dummy.fw_caster = caster
	dummy.fw_ability = ability
	dummy.fw_center = center
	dummy.fw_radius = radius
	
	dummy.fw_Checker = CylinderCheck
	dummy.fw_CheckerDestroyer = DestroyChecker
	
	---这里使用的caster是谁，这个aura和aura创建的modifier里面都会用该caster作为caster。
	--为了保持每一个技能的逻辑独立，这里的caster都设置为虚拟单位
	AddLuaModifier(dummy,dummy,"td_fakewall_aura",{radius=radius},ability)
	
	--持续时间结束了移除虚拟单位
	if type(duration) == "number" then
		TimerUtil.createTimerWithDelay(duration,function()
			--直接移除会导致光环添加的buff在销毁的时候处理失败，从而导致单位的移动速度不会恢复
			EntityHelper.kill(dummy)
		end)
	end
	
	--创建特效
	if particleCreator then
		xpcall(particleCreator,
			function (msg)
				DebugPrint(msg..'\n'..debug.traceback()..'\n')
			end)
	end
	
	CylinderMoveUnit(caster,center,radius)
	
	return dummy
end

return m