---
function ld_zyz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target

	local damage = GetAbilitySpecialValueByLevel(ability,"damage")

	local time = GetAbilitySpecialValueByLevel(ability,"time")
	
	local modifier = caster:FindModifierByName("modifier_wdqk_LinDiao_ziyuezhan_2")
	if modifier then
		if modifier:GetStackCount() < time then
			modifier:IncrementStackCount()
		else
			--第5次攻击，触发效果
			modifier:SetStackCount(0)

			local path = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf";

			local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN_FOLLOW,caster,1)

			local casterOrigin	= caster:GetAbsOrigin()
			
			local casterForward	= caster:GetForwardVector() - 180

			local casterOrigin2 = casterOrigin + casterForward * 800 

			SetParticleControlEx(pid,0,caster:GetAbsOrigin())	
			SetParticleControlEx(pid,1,(target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * 800)	

			local units = FindEnemiesInLineEx(caster,caster:GetAbsOrigin(),casterOrigin2,100,DOTA_UNIT_TARGET_FLAG_NONE)
			
			for key, unit in pairs(units) do
				ApplyDamageEx(caster,unit,ability,damage)			
			end
		end
	end
end