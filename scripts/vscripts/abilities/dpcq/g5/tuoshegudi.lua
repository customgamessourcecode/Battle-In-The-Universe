---陀舍古帝：业火
function tsgd_yh(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local center = caster:GetAbsOrigin()
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	
	local ringPath = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf"
	local pid = CreateParticleEx(ringPath,PATTACH_ABSORIGIN,caster,3)
	SetParticleControlEx(pid,1,Vector(10,0,0))
	
	--特效
	local path = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf"
	local time = 1.5
	local speed = radius / time
	local point = nil
	local count = 12
	local angle = 360 / count
	for var=1, count do
		if not point then
			point = RandomPosInRadius(center,radius,radius)
		else
			point = RotateVector2DWithCenter(center,point,angle)
		end
		local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,3)
		SetParticleControlEx(pid,0,center)
		SetParticleControlEx(pid,1,GetForwardVector(center,point) * speed) --速度
		SetParticleControlEx(pid,2,Vector(0,time,0)) --持续时间
	end
	
	local enemies = FindEnemiesInRadiusEx(caster,center,radius)
	if enemies and #enemies > 0 then
		--火毒技能
		local ability_hd = caster:FindAbilityByName("dpcq_tuoshegudi_hd")
		for _, unit in pairs(enemies) do
			--有火毒，额外伤害
			if unit:HasModifier("modifier_dpcq_tuoshegudi_hd_debuff") then
				ApplyDamageEx(caster,unit,ability,damage * ratio)
			else
				ApplyDamageEx(caster,unit,ability,damage)
			end
			
			--添加火毒buff
			if ability_hd then
				AddDataDrivenModifier(ability_hd,caster,unit,"modifier_dpcq_tuoshegudi_hd_debuff",{})
			end
		end
	end
end

---陀舍古帝：帝炎
function tsgd_dy(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			EmitSoundOnLoc(point,"Hero_AbyssalUnderlord.Firestorm",caster)
		
			local path = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
			local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,1.2)
			SetParticleControlEx(pid,0,point)
			SetParticleControlEx(pid,4,Vector(radius,radius,1))
			
			local enemies = FindEnemiesInRadiusEx(caster,point,radius)
			if enemies then
				local damage2 = damage * ratio
				for _, unit in pairs(enemies) do
					if unit:HasModifier("modifier_dpcq_tuoshegudi_hd_debuff") then
						ApplyDamageEx(caster,unit,ability,damage2)
					else
						ApplyDamageEx(caster,unit,ability,damage)
					end
				end
			end
			
			duration = duration - interval
			return interval
		end
	end)
end

---陀舍古帝：炼狱世界
function tsgd_lysj(keys)
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
	
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	
	local baseDamage = GetAbilitySpecialValueByLevel(ability,"damage")
	local damageMaxHealth = GetAbilitySpecialValueByLevel(ability,"damage_max_health") / 30
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	
	--顺着放
	local casterOrigin = caster:GetAbsOrigin()
	local direction = GetForwardVector(casterOrigin,point)
	local startPos = casterOrigin + 60 * direction
	local endPos = startPos + direction * length
	
	local particleName = "particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf"
	local pid = CreateParticleEx(particleName,PATTACH_ABSORIGIN,caster,duration)
	ParticleManager:SetParticleControl( pid, 0, startPos )
	ParticleManager:SetParticleControl( pid, 1, endPos )
	ParticleManager:SetParticleControl( pid, 2, Vector( duration, 0, 0 ) )
	ability._pid = pid
	
	
	ability._timer = TimerUtil.createTimer(function()
		if duration > 0 then
			local enemies = FindEnemiesInLineEx(caster,startPos,endPos,width)
			if enemies and #enemies > 0 then
				for _, target in pairs(enemies) do
					local damage = 0;				
					--基于生命的伤害也计算护甲
					if target._infinite_real_damage_ratio2 then
						--无尽怪，最大生命值排除减伤影响，只计算护甲
						damage = baseDamage + (target:GetMaxHealth() * damageMaxHealth / target._infinite_real_damage_ratio2)
					else
						damage = baseDamage + target:GetMaxHealth() * damageMaxHealth
					end
					
					if target:HasModifier("modifier_dpcq_tuoshegudi_hd_debuff") then
						damage = damage * ratio
					end
					ApplyDamageEx(caster,target,ability,damage)
				end
			end
			
			duration = duration - interval
			return interval
		else
			ability._pid = nil
			ability._timer = nil
		end
	end)
end

---陀舍古帝：炼狱世界移除
function tsgd_lysj_destroy(keys)
	local ability = keys.ability
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
		ability._pid = nil
	end
	if ability._timer then
		TimerUtil.removeTimer(ability._timer)
		ability._timer = nil
	end
end