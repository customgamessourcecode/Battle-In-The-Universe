---马红俊：凤凰火线开始
function mhj_fhhx_start(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	ability.targetPoint = point
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	
	local path = "particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,caster,duration)
	SetParticleControlEnt(pid,0,caster,PATTACH_POINT_FOLLOW,"attach_attack1",caster:GetAbsOrigin())
	SetParticleControlEx(pid,1,point)
	ability._pid = pid
	--控制转向，间隔越短看起来越顺畅
	local interval = 0.03
	TimerUtil.createTimer(function()
		if caster:FindModifierByName("modifier_dldl_MaHongJun_fhhx") then
			local casterOrigin	= caster:GetAbsOrigin()
			local casterForward	= caster:GetForwardVector()
			local endcapPos = casterOrigin + casterForward * length
			endcapPos = GetGroundPosition( endcapPos, nil )
			endcapPos.z = endcapPos.z + 92
			ParticleManager:SetParticleControl(pid, 1, endcapPos )
			
			ability.targetPoint = endcapPos
			return interval
		else
			ability.targetPoint = nil
		end
	end)
end

---持续施法被打断或者单位死亡，移除特效、停止播放声音
function mhj_fhhx_interrupted(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid,true)
		ability._pid = nil
	end
	StopSoundOnEntity(caster,"Hero_Phoenix.SunRay.Cast")
	StopSoundOnEntity(caster,"Hero_Phoenix.SunRay.Loop")
	caster:RemoveModifierByName("modifier_dldl_MaHongJun_fhhx")
end


---马红俊：凤凰火线造成伤害
function mhj_fhhx_damage(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local targetPoint = ability.targetPoint
	if targetPoint then
		local width = GetAbilitySpecialValueByLevel(ability,"radius") * 2
		local interval = GetAbilitySpecialValueByLevel(ability,"damage_interval") or 1
		local damage = GetAbilitySpecialValueByLevel(ability,"damage")
		if interval > 0 then
			damage = damage * interval
		end
		local enemies = FindEnemiesInLineEx(caster,caster:GetAbsOrigin(),targetPoint,width)
		if enemies and #enemies > 0 then
			--不灭火焰效果
			local bmhy = caster:FindAbilityByName("dldl_MaHongJun_bmhy")
			local tooltip_modifier = "modifier_dldl_MaHongJun_bmhy_debuff"
			local duration = GetAbilitySpecialValueByLevel(bmhy,"duration")
			
			for key, unit in pairs(enemies) do
				ApplyDamageEx(caster,unit,ability,damage)
				if bmhy:GetLevel() > 0 then
					AddDataDrivenModifier(bmhy,caster,unit,tooltip_modifier,{duration=duration})
					AddLuaModifier(caster,unit,"mhj_bmhy_fire_damage_in",{duration=duration},bmhy)
				end
			end
		end
	end
end
