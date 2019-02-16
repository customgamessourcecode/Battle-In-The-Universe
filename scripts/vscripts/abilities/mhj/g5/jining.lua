---纪宁：永恒终极剑道
function jn_yhzjjd(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local duration = ability.duration_group
	if not duration then
		duration = GetAbilitySpecialValueByLevel(ability,"duration")
	else
		duration = GetAbilitySpecialValueByLevel(ability,"duration_group")
	end
	
	local dummy = CreateDummyUnit(point,caster)
	AddDataDrivenModifier(ability,caster,dummy,"modifier_mhj_JiNing_yhzjjd_dummy",{duration=duration})
	
	local path = "particles/mhj/jining_yhzjjd.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN_FOLLOW,dummy,duration,true)
	SetParticleControlEx(pid,0,dummy:GetAbsOrigin())
	
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	--直接使用kv中的伤害逻辑不知道为什么，如果施法后收起施法者，在持续时间超过一定值（未测试具体值）时，会对友军造成伤害。
	--目前没有研究具体原因（猜测是施法者丢失后，找不到所属队伍了？），先不用那个逻辑了，自己判断敌军并伤害（目前这个逻辑，即便塔被收起来，仍然会造成伤害）
	TimerUtil.createTimer(function()
		if duration > 0 then
			--更新伤害数值，在塔被收回的时候，技能就空了
			if EntityNotNull(ability) then
				damage = GetAbilitySpecialValueByLevel(ability,"damage")
			end
			--直接使用玩家队伍，而不用施法者，避免施法者被收起来的时候获取队伍为空。
			local enemies= FindEnemiesInRadiusEx(TEAM_PLAYER,point,radius)
			if enemies~=nil then
				BatchApplyPhysicalDamage(enemies,caster,damage,ability)
			end
			duration = duration - interval
			return interval;
		else
			EntityHelper.kill(dummy)
			dummy = nil
		end
	end)
end
