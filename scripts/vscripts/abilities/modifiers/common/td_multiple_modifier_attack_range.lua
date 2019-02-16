--攻击距离buff
if td_multiple_modifier_attack_range == nil then
	td_multiple_modifier_attack_range = class({})
	
	local m = td_multiple_modifier_attack_range;
	
	--无敌保持
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
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
	  }
	  return funcs;
	end
	
	function m:GetModifierAttackRangeBonus()
		local ability = self:GetAbility()
		if ability and not ability:IsNull() then
			return ability:GetSpecialValueFor("bonus")
		end
	end
end

