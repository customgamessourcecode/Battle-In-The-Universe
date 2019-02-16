---玄葬：毒液侵蚀伤害效果
function xz_dyqs(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	--二技能加成
	local bonusAbility = caster:FindAbilityByName("qm_XuanZang_dxqh")
	if bonusAbility and bonusAbility:GetLevel() > 0 then
		local ratio = GetAbilitySpecialValueByLevel(bonusAbility,"ratio")
		if ratio > 0 then
			damage = damage + damage * ratio / 100
		end
	end
	
	ApplyDamageEx(caster,target,ability,damage)
end

---玄葬：毒性爆发
function xz_dxbf_check(keys)
	local caster = keys.caster
	local target = keys.target
	
	local ability = caster:FindAbilityByName("qm_XuanZang_dxbf")
	
	if ability and ability:GetLevel() > 0 then
		if not target:HasModifier("modifier_qm_XuanZang_dxbf_resistance") and
			 not target:HasModifier("modifier_qm_XuanZang_dxbf_debuff") then
			AddDataDrivenModifier(ability,caster,target,"modifier_qm_XuanZang_dxbf_debuff",{})
		end
	end
end