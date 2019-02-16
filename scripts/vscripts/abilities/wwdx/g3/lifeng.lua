---戾峰-魔功，击杀单位，叠加伤害buff
function lf_mogong_kill(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	---收回的时候调用的击杀逻辑，也会进入这里。排除掉
	if caster == keys.unit then
		return;
	end
	
	local damage_modifier = ability._modifier
	if not damage_modifier then
		damage_modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_wwdx_LiFeng_MoGong_2",{})
		ability._modifier = damage_modifier
	end
	
	if damage_modifier then
		local stack = GetAbilitySpecialValueByLevel(ability,"bonus")
		damage_modifier:SetStackCount(damage_modifier:GetStackCount()+stack)
		--保存起来
		Towermgr.SetTowerKV(caster,"lf_mogong_kill",damage_modifier:GetStackCount())
	end
end

---戾峰-魔功，更新buff状态。主要用于处理单位收起重新放置的时候，恢复之前的击杀数量
--注意这个逻辑要在技能升级的时候调用，在创建时调用会有问题，因为是默认拥有的，当创建单位的时候，就直接加上了。但是这个时候还获取不到缓存的数据。
--但是放在升级触发就没有问题了，创建单位后就会赋值缓存的数据，而升级是在单位“长大”以后了，至少是1秒以后了，此时就能获取到缓存数据了。
function lf_mogong_update(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	if ability.lf_mogong_update then
		return;
	end
	ability.lf_mogong_update = true
	--更新击杀数
	local stack = Towermgr.GetTowerKV(caster,"lf_mogong_kill") or 0
	
	if stack > 0 then
		local damage_modifier = ability._modifier
		if not damage_modifier then
			damage_modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_wwdx_LiFeng_MoGong_2",{})
			ability._modifier = damage_modifier
		end
		
		if damage_modifier then
			damage_modifier:SetStackCount(stack)
		end
	end
end