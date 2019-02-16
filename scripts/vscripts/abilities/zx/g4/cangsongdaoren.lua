function csdr_xj_upgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	--升级的时候会进来很多次，这里只处理一次
	if ability.csdr_xj_upgrade then
		return;
	end
	ability.csdr_xj_upgrade = true
	
	local stack = Towermgr.GetTowerKV(caster,"csdr_xj_stack")
	if stack then
		local modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_zx_CangSongDaoRen_xj_bonus",{})
		if modifier then
			modifier:SetStackCount(stack)
		end
	end
end

function csdr_xj_destroy(keys)
	local caster = keys.caster
	local modifier = caster:FindModifierByName("modifier_zx_CangSongDaoRen_xj_bonus")
	if modifier then
		Towermgr.SetTowerKV(caster,"csdr_xj_stack",modifier:GetStackCount())
	end
end