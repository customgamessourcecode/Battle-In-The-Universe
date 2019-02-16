--朱竹清：幽冥附体
if zzq_ymft_damage_out == nil then
	zzq_ymft_damage_out = class({})
	
	local m = zzq_ymft_damage_out;
	
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
	     MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierTotalDamageOutgoing_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("ratio")
	end
end

