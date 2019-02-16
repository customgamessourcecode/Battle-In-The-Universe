--戴沐白：白虎真身
if dmb_bhzs_damage_out == nil then
	dmb_bhzs_damage_out = class({})
	
	local m = dmb_bhzs_damage_out;
	
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
	     MODIFIER_PROPERTY_MODEL_CHANGE,
	     MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
	     MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierModelChange()
		return "models/unit/huw/hu_body.vmdl"
	end
	
	function m:GetAttackSound()
		return "Hero_Lycan.Attack"
	end
	
	function m:GetModifierDamageOutgoing_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("ratio")
	end
end

