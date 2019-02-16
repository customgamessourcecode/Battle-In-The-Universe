--波塞西：海洋之眼
function bsx_hyzy(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	---缓存起来便于删除。在wtf模式下，多次释放的时候也不会出现很多
	if ability._particle then
		ParticleManager:DestroyParticle(ability._particle, true)
		ability._particle = nil
	end
	if ability._timer then
		TimerUtil.removeTimer(ability._timer)
		ability._timer = nil
	end
	
	--眼的特效
	local path = "particles/dldl/bosaixi_hyzy.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,duration)
	SetParticleControlEx(pid,1,Vector(150,0,0))
	SetParticleControlEx(pid,3,point + Vector(0,0,300))
	ability._particle = pid
	--波浪特效
	local wavePath = "particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship_splash_rings.vpcf"
	
	local count = duration / interval
	ability._timer = TimerUtil.createTimer(function()
		if count > 0 then
			--伤害
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			--波浪特效
			local pid = CreateParticleEx(wavePath,PATTACH_ABSORIGIN,caster,2)
			SetParticleControlEx(pid,3,point + Vector(0,0,50))
			
			count = count - 1 
			return interval
		end
	end)
end

---塔被移除，立刻销毁特效
function bsx_hyzy_destroy(keys)
	local ability = keys.ability
	
	if ability._particle then
		ParticleManager:DestroyParticle(ability._particle, true)
		ability._particle = nil
	end
	if ability._timer then
		TimerUtil.removeTimer(ability._timer)
		ability._timer = nil
	end
end