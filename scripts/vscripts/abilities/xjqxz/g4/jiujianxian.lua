---醉剑升级，恢复之前叠加的攻击力
function jjx_zj_upgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	--升级的时候会进来很多次，这里只处理一次
	if ability.jjx_zj_upgrade then
		return;
	end
	ability.jjx_zj_upgrade = true
	
	local stack = Towermgr.GetTowerKV(caster,"jjx_zj_stack")
	if stack then
		local modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_xjqxz_JiuJianXian_zj_bonus",{})
		if modifier then
			modifier:SetStackCount(stack)
		end
	end
end

function jjx_zj_destroy(keys)
	local caster = keys.caster
	local modifier = caster:FindModifierByName("modifier_xjqxz_JiuJianXian_zj_bonus")
	if modifier then
		Towermgr.SetTowerKV(caster,"jjx_zj_stack",modifier:GetStackCount())
	end
end