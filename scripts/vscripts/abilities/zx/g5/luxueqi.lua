---霜天雪舞
function lxq_stxw(keys)
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local chance = GetAbilitySpecialValueByLevel(ability,"chance")
	
	local start = "particles/zx/lxq/lxq_stxw_1.vpcf"
	local pid1 = CreateParticleEx(start,PATTACH_CUSTOMORIGIN,caster,3)
	SetParticleControlEx(pid1,0,point)
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			local path = "particles/zx/lxq/lxq_stxw_ice.vpcf"
			local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,3)
			local attackPoint = RandomPosInRadius(point,radius,0)
			ParticleManager:SetParticleControl( pid, 0, attackPoint )
			ParticleManager:SetParticleControl( pid, 1, attackPoint + Vector(0,0,1500))
			
			local enemies = FindEnemiesInRadiusEx(caster,point,radius)
			if enemies then
				for _, unit in pairs(enemies) do
					ApplyDamageEx(caster,unit,ability,damage)
					if not unit.TD_IsBoss and RollPercent(chance) then
						AddDataDrivenModifier(ability,caster,unit,"modifier_zx_luxueqi_stxw_frozone",{})
					end
				end
			end
			
			duration = duration - interval
			return interval
		end
	end)
	
end

---天玄冰
function lxq_txb(keys)
	local caster = keys.caster
	local ability = keys.ability
	local units = keys.target_entities
	
	local modifier = "modifier_zx_luxueqi_txb"
	if ability.xxj_edi_special then
		modifier = "modifier_zx_luxueqi_txb_group"
	end
	if units and #units > 0 then
		local duration = GetAbilitySpecialValueByLevel(ability,"duration")
		for _, unit in pairs(units) do
			AddDataDrivenModifier(ability,caster,unit,modifier,{duration=duration})
		end
	end
end

---御雷真诀
function lxq_ylzj(keys)
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = 0
	if ability.duration_group then
		duration = GetAbilitySpecialValueByLevel(ability,"duration_group")
	else
		duration = GetAbilitySpecialValueByLevel(ability,"duration");
	end
	
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	-- 雷云特效：控制点3控制云的浓度，控制点4控制云的半径，128的浓度大概对应400范围。
	local cloud = ParticleManager:CreateParticle( "particles/zx/lxq/ylzj/lxq_storm.vpcf", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( cloud, 0, point )
	ParticleManager:SetParticleControl( cloud, 3, Vector(96,0,0) )
	ParticleManager:SetParticleControl( cloud, 4, Vector(radius,0,0) )
	
	TimerUtil.createTimer(function ()
		if duration > 0 then
--			if RollPercentage(50) then
--				StartSoundEventFromPosition("Hero_Zuus.ProjectileImpact",point)--这个是宙斯攻击命中时候的声音，模拟雷击地面声音
--			end
			--每次打击伤害300范围的单位
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			
			local attackPoint = FindRandomPoint(point,radius)
			--创建闪电特效，控制点0控制落雷起始点，控制点1控制落雷结束点。
			local pid = CreateParticleEx("particles/zx/lxq/ylzj/lxq_thunder_0.vpcf",PATTACH_CUSTOMORIGIN,caster,0.5,false)
			ParticleManager:SetParticleControl( pid, 0, attackPoint + Vector(RandomInt(-100, 100), RandomInt(-100, 100), 512))
			ParticleManager:SetParticleControl( pid, 1, attackPoint )
			
			duration = duration - interval
			return interval
		else --打击结束以后，销毁雷云特效(这个特效并不会自动消失)。
			ParticleManager:DestroyParticle(cloud,true)
		end
	end)
	
end