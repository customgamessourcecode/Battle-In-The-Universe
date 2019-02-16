--生命主宰薇薇亚：生命剥离
function wwy_smbl(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local damageRatio = GetAbilitySpecialValueByLevel(ability,"damage") / 500
	
	local path = "particles/units/heroes/hero_arc_warden/arc_warden_magnetic.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,duration)
	SetParticleControlEx(pid,0,point)
	SetParticleControlEx(pid,1,Vector(radius,radius,radius))
	
	local count = 0
	TimerUtil.createTimer(function()
		if count < duration * 5 then
			local enemies = FindEnemiesInRadiusEx(caster,point,radius)
			for key, unit in pairs(enemies) do
				ApplyDamageEx(caster,unit,ability,unit:GetMaxHealth() * damageRatio)
			end
			count = count + 1
			return 0.2
		end
	end)
end

--生命主宰薇薇亚：生命祝福
function wwy_smzf(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius,DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED)
	for key, unit in pairs(units) do
		if count > 0 then
			--KV的仅用来显示（kv的伤害加深没有用了。。。。）
			AddDataDrivenModifier(ability,caster,unit,"modifier_pl_WeiWeiYa_smzf",{duration=duration})
			AddLuaModifier(caster,unit,"wwy_smzf_damage_out",{duration=duration},ability)
			count = count - 1
		end
	end
end