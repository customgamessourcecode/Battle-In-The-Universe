---秦霜：寒风刺骨
function qs_hfcg(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	---技能已经冷却好了，并且范围内有敌人，才释放
	if ability:GetCooldownTimeRemaining() == 0 then
		local radius = GetAbilitySpecialValueByLevel(ability,"radius")
		local enemy = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
		if enemy and #enemy > 0 then
			--特效
			local path = "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch.vpcf"
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
			SetParticleControlEx(pid,1,Vector(radius,radius,0))
			
			EmitSound(caster,"Hero_Ancient_Apparition.ChillingTouchCast")
		
			local duration = GetAbilitySpecialValueByLevel(ability,"duration")
			for _, unit in pairs(enemy) do
				if not unit.TD_IsBoss then
					AddDataDrivenModifier(ability,caster,unit,"modifier_xcb_qinShuang_hfcg_debuff",{duration=duration})
					--风霜之水组合效果
					if ability.group_bonus then
						AddDataDrivenModifier(ability,caster,unit,"modifier_xcb_qinShuang_hfcg_group",{duration=duration})
					end
				end
			end
			
			local cooldown = GetAbilitySpecialValueByLevel(ability,"cooldown")
			ability:StartCooldown(cooldown)
		end
	end
end