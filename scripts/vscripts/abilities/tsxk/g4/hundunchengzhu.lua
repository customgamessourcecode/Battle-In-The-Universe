---混沌城主：千宝河
function hdcz_qbh(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
		ability._pid = nil
	end
	if ability._timer then
		TimerUtil.removeTimer(ability._timer)
		ability._timer = nil
	end
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	
	local startPos = caster:GetAbsOrigin()
	local forward = GetForwardVector(startPos,point)
	local endPos = forward * length + startPos
	
	local path = "particles/tsxk/g2/hundunchengzhu_qbh.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,duration,true)
	SetParticleControlEx(pid,0,startPos + forward * 400)
	SetParticleControlEx(pid,1,endPos)
	ability._pid = pid
	
	ability._timer = TimerUtil.createTimer(function()
		if duration > 0 then
			local units = FindEnemiesInLineEx(caster,startPos,endPos,width)
			ApplyDamageEx(caster,units,ability,damage)
			
			duration = duration - interval
			return interval
		else
			ability._pid = nil
			ability._timer = nil
		end
	end)
end

---塔被移除了，就清除特效和伤害
function hdcz_qbh_destroy(keys)
	local ability = keys.ability
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
	end
	if ability._timer then
		TimerUtil.removeTimer(ability._timer)
	end
end
