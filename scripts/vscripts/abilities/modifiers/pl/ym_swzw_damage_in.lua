--幽冥-死亡之吻
if ym_swzw_damage_in == nil then
	ym_swzw_damage_in = class({})
	
	local m = ym_swzw_damage_in;
	
	--无敌保持
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE;
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
	     MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierIncomingDamage_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("ratio")
	end
end

