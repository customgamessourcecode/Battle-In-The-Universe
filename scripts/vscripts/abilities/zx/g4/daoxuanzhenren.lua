--- ：青云阵法
function dxzr_qyzf(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local path = "particles/zx/daoxuanzhenren_qyzf.vpcf"
	
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
	SetParticleControlEx(pid,0,point)
	TimerUtil.createTimer(function()
		if duration > 0 then
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			duration = duration - interval
			return interval
		else
			ParticleManager:DestroyParticle(pid,true)
		end
	end)
	
	local qymf = caster:FindAbilityByName("zx_DaoXuanZhenRen_qymj")
	if qymf and qymf:GetLevel() > 0 then
		--默认的thinker函数总是不识别这个modifier，只能造虚拟单位了
		local dummy = CreateDummyUnit(point,caster)
		AddDataDrivenModifier(qymf,caster,dummy,"modifier_zx_DaoXuanZhenRen_qymj",{})
		TimerUtil.createTimerWithDelay(duration,function()
			EntityHelper.kill(dummy)
			dummy = nil
		end)
	end
end