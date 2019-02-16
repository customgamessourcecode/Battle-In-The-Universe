---百分比增加杀怪获取到的金币。用的是金币过滤器，过滤器目前只能识别杀怪获取的金币
if td_multiple_gold_gain_percentage == nil then
	td_multiple_gold_gain_percentage = class({})
	
	local m = td_multiple_gold_gain_percentage;
	
	--无敌保持 + 可重复
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE;
	end
	
	function m:IsHidden()
		return true;
	end
	
	--是否可以被净化
	function m:IsPurgable()
		return false;
	end
	
	function m:AllowIllusionDuplicate()
		return false;
	end
	
	---自定义函数
	function m:GetGoldGainPercentage()
		if IsServer() then
			local ability = self:GetAbility()
			if ability then
				local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
				--检查施法者是否经过了卡牌等级提升的强化
				local caster = self:GetCaster()
				if caster then
					local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
					if bonusModifier and bonusModifier:GetStackCount() > 0 then
						ratio = ratio * (1 + bonusModifier:GetStackCount() / 100)
					end
				end
				return ratio
			end
		end
	end
end
