---叶凡：八步灭道无上神术
function yf_bbmdwsss(keys)
	local caster = keys.caster
	local ability = keys.ability 
	local point = keys.target_points[1]
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	local baseDamage = GetAbilitySpecialValueByLevel(ability,"base_damage")
	local healtRatio = GetAbilitySpecialValueByLevel(ability,"max_health_damage_ratio")
	
	local startPos = caster:GetAbsOrigin()
	local endPos = startPos + GetForwardVector(startPos,point) * length
	
	
	EmitSound(caster,"zt.yefan.bbmdwsss.cast")
	
	local path = "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
	SetParticleControlEx(pid,0,startPos)
	SetParticleControlEx(pid,1,endPos)
	--特效结束的时间，跟特效里面的其他设置（Position Along Path Sequential里面的Particles to map from start to end）一起作用才能显示比较合适的速度。
	--直接设置成1，只会跑一段就停了。
	SetParticleControlEx(pid,3,Vector(0,3,0)) 
	
	EmitSound(caster,"zt.yefan.bbmdwsss.projectile")
	
	caster:SetContextThink(DoUniqueString("thinker"),function()
		EmitSound(caster,"zt.yefan.bbmdwsss.destroy")
		
		local enemies = FindEnemiesInLineEx(caster,startPos,endPos,width)
		if enemies and #enemies > 0 then
			for _, enemy in pairs(enemies) do
				ApplyDamageEx(caster,enemy,ability,baseDamage + enemy:GetMaxHealth() * healtRatio / 100)
				AddDataDrivenModifier(ability,caster,enemy,"modifier_zt_yefan_bbmdwsss_debuff",{})
			end
		end
	end,3)
end