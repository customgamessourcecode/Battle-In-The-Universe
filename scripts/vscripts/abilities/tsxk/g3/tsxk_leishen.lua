---吞噬星空：雷神，五雷刀法
function tsxk_ls_df(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local maxCount = GetAbilitySpecialValueByLevel(ability,"maxCount")
	
	local modifier = caster:FindModifierByName("modifier_tsxk_LeiShen_df")
	if modifier:GetStackCount() < maxCount - 1 then
		modifier:IncrementStackCount()
	else
		modifier:SetStackCount(0)
		AddDataDrivenModifier(ability,caster,target,"modifier_tsxk_LeiShen_wldf_damage",{})
	end
end

---雷神：雷霆刀法
function tsxk_ls_ltdf(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local path = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"
	local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,1)
	SetParticleControlEx(pid,0,target:GetAbsOrigin())
	SetParticleControlEx(pid,1,target:GetAbsOrigin() + Vector(0,0,600))
	
	if not target:HasModifier("modifier_tsxk_LeiShen_ltdf_stun_interval") then
		AddDataDrivenModifier(ability,caster,target,"modifier_tsxk_LeiShen_ltdf_stun",{})
	end
end