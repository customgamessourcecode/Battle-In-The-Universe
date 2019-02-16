--千仞雪：太阳圣剑
function qrx_tysj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local startPos = caster:GetAbsOrigin()
	local direction = GetForwardVector(startPos,point)
	
	local length = GetAbilitySpecialValueByLevel(ability,"length")
	local width = GetAbilitySpecialValueByLevel(ability,"width")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local duration = GetAbilitySpecialValueByLevel(ability,"stun_duration")
	
	local path = "particles/econ/items/skywrath_mage/skywrath_mage_weapon_empyrean/skywrath_mage_mystic_flare_ambient_hit_empyrean.vpcf"
	
	local units = FindEnemiesInLineEx(caster,startPos,startPos + direction * length,width)
	if units and #units > 0 then
		for key, unit in pairs(units) do
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,unit,1.5)
			EmitSound(unit,"Hero_SkywrathMage.MysticFlare.Target")
			ApplyDamageEx(caster,unit,ability,damage)
			--有间隔，不会持续受到眩晕
			if not unit:HasModifier("modifier_dldl_qianrenxue_tysj_interval") then
				AddDataDrivenModifier(ability,caster,unit,"modifier_dldl_qianrenxue_tysj",{duration=duration})
			end
		end
	else --没有单位的话，随机几个点释放效果
		local points = {}
		for var=1, 5 do
			table.insert(points,RandomPosInRadius(startPos + direction * RandomInt(100,length),width / 2,10))
		end
		for _, point in pairs(points) do
			local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,nil,1.5)
			SetParticleControlEx(pid,0,point)
			EmitSoundOnLoc(point,"Hero_SkywrathMage.MysticFlare.Target",caster)
		end
	end
end