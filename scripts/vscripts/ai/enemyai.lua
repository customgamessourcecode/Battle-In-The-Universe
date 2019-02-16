EnemyAI = {}
EnemyAI.__index = EnemyAI

---怪物AI，让怪物移动和施法
function EnemyAI:MakeInstance(unit)
	if not EntityIsAlive(unit) then
		return;
	end
	
	if unit._ai then
		Timers:RemoveTimer(unit._ai.timerName);
	end

	local ai = {}
	setmetatable( ai, EnemyAI )

	ai.unit = unit --这个AI控制的单位
	
	--开始思考，记录计时器的名字，以便于删除
	ai.timerName = TimerUtil.createTimerWithContext( ai.GlobalThink, ai )
	
	unit._ai = ai;--将ai绑定到单位上，以便于重复时删除
	return ai
end

--[[ 高优先级的计时器判断这个AI单位每跳要做的时, 选择正确的方法状态并执行. ]]
function EnemyAI:GlobalThink()
	local unit = self.unit;
	--单位死了就停止AI
	if not EntityIsAlive(unit) then
		return
	end
	
	--特殊状态下不处理
	if unit:IsChanneling()  --持续施法中
		or unit:IsFrozen() --冰冻
		or unit:IsHexed() --妖术变化
		or unit:IsStunned() --眩晕
		or unit:IsRooted() --固定
	then
		return 0.5
	end
	
	
	---找不到路径，有可能是被推上了高地，此时加上飞行状态，无视地形走过去以后再去掉飞行状态
	if not GridNav:CanFindPath(unit:GetAbsOrigin(),unit.targetPos) then
		AddLuaModifier(nil,unit,"td_modifier_flying",{})
	elseif unit:HasModifier("td_modifier_flying") then
		unit:RemoveModifierByName("td_modifier_flying")
	end
	
	if not unit.ChangingPathNode then
		unit:MoveToPosition(unit.targetPos)
	end
	
	--尝试释放主动技能
	if not unit:IsSilenced() then
		self:castAbility(unit)
	end
	
	return 1
end


function EnemyAI:castAbility(unit)
	--至少三秒才会释放一次技能，要不然释放太频繁了（0.5秒），容易打断攻击 
	local time = self._CastAbilityTime
	if time and GameRules:GetGameTime() - time < RandomInt(1,3) then
		return;
	end
	
	--可释放的技能，实际释放的时候随机一个
	local castable = {}
	for index=0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(index);
		--如果对应位置存在技能，技能不是被动，也没有冷却，则释放技能
		if ability and not ability:IsPassive() and ability:GetLevel() > 0
			and ability:IsFullyCastable() then
			table.insert(castable,ability)
		end
	end
	
	--随机释放一个技能
	if #castable > 0 then
		local ability = castable[RandomInt(1,#castable)]
		local castRange = ability:GetCastRange();
		
		--技能属性
		local targetTeam = ability:GetAbilityTargetTeam()
		local targetType = ability:GetAbilityTargetType()
		local targetFlag = ability:GetAbilityTargetFlags()
		
		local unitLoc = unit:GetAbsOrigin()
		local unitTeam = unit:GetTeamNumber()
		
		--根据技能类型决定施法方式，只应用一个
		local behavior = GetAbilityBehaviorNum(ability)
		if BitAndTest(behavior,DOTA_ABILITY_BEHAVIOR_NO_TARGET) then --无目标的技能
			--对友方释放的，附近有友军才释放；对敌方释放的，附近有敌方才释放
			if BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
				local allies = FindAlliesInRadiusEx(unitTeam,unit:GetAbsOrigin(),castRange,targetFlag,nil,targetType)
				if allies and #allies > 0 then
					unit:CastAbilityNoTarget(ability,-1);
					self._CastAbilityTime = GameRules:GetGameTime()
				end
			else
				local enemies = FindEnemiesInRadiusEx(unitTeam,unitLoc,castRange,targetFlag,nil,targetType)
				if enemies and #enemies > 0 then
					unit:CastAbilityNoTarget(ability,-1);
					self._CastAbilityTime = GameRules:GetGameTime()
				end
			end
		elseif BitAndTest(behavior,DOTA_ABILITY_BEHAVIOR_POINT) then --点目标
			--如果是作用于友军的，则直接在自己所在位置释放。否则检查是否有攻击目标，有目标在目标点释放
			if BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
				unit:CastAbilityOnPosition(unitLoc,ability,-1);
				self._CastAbilityTime = GameRules:GetGameTime()
			else
				local enemies = FindEnemiesInRadiusEx(unitTeam,unitLoc,castRange,targetFlag,nil,targetType)
				if enemies and #enemies > 0 then
					local target = enemies[RandomInt(1,#enemies)]
					local targetLoc = target:GetAbsOrigin()
					if (targetLoc - unitLoc):Length2D() <= castRange then --在施法范围内，才使用。
						unit:CastAbilityOnPosition(targetLoc,ability,-1);
						self._CastAbilityTime = GameRules:GetGameTime()
					end
				end
			end
		elseif BitAndTest(behavior,DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then --单位目标
			--技能目标，根据技能属性获取目标
			local target = nil
			--判断是对友方还是对敌方释放
			if BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
				--在自身周围找一个合适的友方单位，排除掉幻象和魔免单位（马甲）
				if not BitAndTest(targetFlag,DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS) then
					targetFlag = targetFlag + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
				end
				if not BitAndTest(targetFlag,DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES) then
					targetFlag = targetFlag + DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES
				end
				local allies = FindAlliesInRadiusEx(unitTeam,unit:GetAbsOrigin(),castRange,targetFlag,nil,targetType)
				if allies and #allies > 0 then
					target = allies[RandomInt(1,#allies)]
				end
			else
				--检查目标单位是否符合条件，不符合的话，尝试在施法范围内找一个
				local attackingTarget = unit:GetAttackTarget()
				if not attackingTarget or UnitFilter(attackingTarget,targetTeam,targetType,targetFlag,unitTeam) ~= UF_SUCCESS then
					local enemies = FindEnemiesInRadiusEx(unitTeam,unitLoc,castRange,targetFlag,nil,targetType)
					if enemies and #enemies > 0 then
						target = enemies[RandomInt(1,#enemies)]
					end
				else
					target = attackingTarget;
				end
			end
			
			if target then
				local targetLoc = target:GetAbsOrigin()
				if (targetLoc - unitLoc):Length2D() <= castRange then --在施法范围内，才使用。
					unit:CastAbilityOnTarget(target,ability,-1);
					self._CastAbilityTime = GameRules:GetGameTime()
				end
			end
		end
	end
end
