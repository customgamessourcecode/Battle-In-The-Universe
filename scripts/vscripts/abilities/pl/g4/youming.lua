--死亡主宰幽冥：死亡呼吸
function ym_swhx(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local unitLevel = caster:GetLevel()
	local damage = caster:GetAverageTrueAttackDamage(target)
	damage = damage * unitLevel * unitLevel * 0.4 + 5000
	ApplyDamageEx(caster,target,ability,damage)
	
	--死亡爆发效果，致死
	local swbfBuff = target:FindModifierByName("modifier_pl_YouMing_swbf_death")
	if swbfBuff then
		local swbfAbility = swbfBuff:GetAbility()
		local percentLimit = GetAbilitySpecialValueByLevel(swbfAbility,"health_limit")
		if target:GetHealthPercent() < percentLimit then
			local chance = GetAbilitySpecialValueByLevel(swbfAbility,"chance")
			if chance and RollPercent(chance) then
				local path = "particles/econ/items/shadow_demon/sd_ti7_shadow_poison/sd_ti7_shadow_poison_kill.vpcf"
				local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
				SetParticleControlEx(pid,2,target:GetAbsOrigin())
				
				TimerUtil.createTimerWithDelay(0.5,function()
					target:Kill(ability,caster)
				end)
			end
		end
	end
end
--死亡主宰幽冥：死亡之吻
function ym_swzw(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local modifier = AddLuaModifier(caster,target,"ym_swzw_damage_in",{duration=duration},ability)
end