
--基础AI
BaseAI = {}
BaseAI.__index = BaseAI

function BaseAI:MakeInstance(unit)
	if not EntityIsAlive(unit) then
		return;
	end
	
	if unit._ai then
		Timers:RemoveTimer(unit._ai.timerName);
	end

	local ai = {}
	setmetatable( ai, BaseAI )

	ai.unit = unit --这个AI控制的单位
	ai.abilityExecutor = AICenter.GetAbilityExecutor(unit:GetUnitName())
	
	--开始思考，记录计时器的名字，以便于删除
	ai.timerName = TimerUtil.createTimerWithContext( ai.GlobalThink, ai )
	
	unit._ai = ai;--将ai绑定到单位上，以便于重复时删除
	return ai
end

--[[ 高优先级的计时器判断这个AI单位每跳要做的时, 选择正确的方法状态并执行. ]]
function BaseAI:GlobalThink()
	local unit = self.unit;
	--单位死了就停止AI
	if not EntityIsAlive(unit) then
		return
	end
	
	---没有这个buff代表还没有完全创建成功。先不启动ai的逻辑
	if not unit:HasModifier("td_modifier_tower") then
		return 0.5;
	end
	
	
	local target = unit:GetAttackTarget()
	if not target then
		--搜索附近的敌方单位，避免玩家没有在dota选项中开启召唤物的自动攻击，导致塔不会攻击
		local enemies = FindEnemiesInRadiusEx(unit,unit:GetAbsOrigin(),unit:Script_GetAttackRange())
		--没有攻击任何单位，并且没有执行其他命令的时候，打怪，isIdle主要是为了释放能的逻辑
		if enemies and #enemies > 0 and not unit:IsAttacking() and unit:IsIdle() then
			--使用攻击目标点的命令，应该很快就会终止，使用攻击目标单位的命令的话，怕不能很快进入idle状态，导致进入下面的
			--idle检测逻辑，并一直调用stop，这样就可能会出现人物要攻击，但是被新的命令打断的情况
			unit:MoveToPositionAggressive(unit:GetAbsOrigin())
		end
	end
	
	--状态没问题的时候，尝试释放技能，无论是否有攻击目标。主要是为了释放那些可对友军释放的技能，比如回蓝这些
	--但是这也有问题，有一些是只有战斗的时候才需要用的，比如释放技能后，增加附近单位的攻击力这类的。
	if not self.disabled 
	and not unit:IsChanneling() 
	and not unit:IsSilenced() 
	and not unit:IsStunned() then
		self:CastAbility(unit,self.abilityExecutor)
	end
	
	---是否正在执行某个非攻击类的命令。比如移动、释放技能等。
	if not unit:IsIdle() and not unit:IsAttacking() and not unit:IsChanneling() then
		if self.NeedReleaseOrder then
			unit:Stop()
			self.NeedReleaseOrder = false
		else
			self.NeedReleaseOrder = true
		end
	else
		self.NeedReleaseOrder = false
	end
	
	return 0.5
end


function BaseAI:CastAbility(unit,executor)
	if executor then
		executor(unit,self)
		return;
	else
		--没有自定义的技能释放逻辑的话，就不那么频繁的释放技能了
		--至少三秒才会释放一次技能，要不然释放太频繁了（0.5秒），容易打断攻击 
		local time = self._CastAbilityTime
		if time and GameRules:GetGameTime() - time < 3 then
			return;
		end
	end
	
	
	--可释放的技能，实际释放的时候随机一个
	local castable = {}
	for index=0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(index);
		--如果对应位置存在技能，技能不是被动，也没有冷却，则释放技能
		if ability and not ability:IsPassive() and ability:GetLevel() > 0
			and not string.find(ability:GetAbilityName(),"tower_levelup_")
			and ability:GetAbilityName() ~= "tower_disable_ai" 
			and ability:GetAbilityName() ~= "tower_enable_ai" 
			and ability:GetAbilityName() ~= "tower_autocast_bind" 
			and ability:IsFullyCastable() then
			--非陷阱类技能可以重复释放。陷阱类技能基础ai不会重复释放（第一次释放的时候就会标记成陷阱，就不再释放了）
			--如果有自定义的技能释放逻辑，则考虑加进可释放技能中
			if not ability.td_is_trap or executor then
				table.insert(castable,ability)
			end
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
			--对友方释放的，附近有友军才释放；对敌方释放的，附近有敌方才释放。如果是其他队伍类型，则不释放。这样某些不需要自动释放的技能就可以设置成没有队伍即可
			if BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
				local allies = FindAlliesInRadiusEx(unitTeam,unit:GetAbsOrigin(),castRange,targetFlag,nil,targetType)
				if allies and #allies > 0 then
					--切换类技能
					if ability:IsToggle() then
						if not ability:GetToggleState() then
							ability:ToggleAbility()
						end
					else
						unit:CastAbilityNoTarget(ability,-1);
					end
					self._CastAbilityTime = GameRules:GetGameTime()
				end
			elseif BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_ENEMY) then
				local enemies = FindEnemiesInRadiusEx(unitTeam,unitLoc,castRange,targetFlag,nil,targetType)
				if enemies and #enemies > 0 then
					--切换类技能
					if ability:IsToggle() then
						if not ability:GetToggleState() then
							ability:ToggleAbility()
						end
					else
						unit:CastAbilityNoTarget(ability,-1);
					end
					self._CastAbilityTime = GameRules:GetGameTime()
				end
			end
		elseif BitAndTest(behavior,DOTA_ABILITY_BEHAVIOR_POINT) then --点目标
			--如果是作用于友军的，则直接在自己所在位置释放。否则检查是否有攻击目标，有目标在目标点释放
			if BitAndTest(targetTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
				unit:CastAbilityOnPosition(unitLoc,ability,-1);
				self._CastAbilityTime = GameRules:GetGameTime()
			else
				local target = unit:GetAttackTarget()
				if target then
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
				--纽带技能绑定的目标
				local binded = Towermgr.GetTowerKV(unit,"tower_autocast_bind_target")
				if EntityNotNull(binded) then
					target = binded
				else
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
