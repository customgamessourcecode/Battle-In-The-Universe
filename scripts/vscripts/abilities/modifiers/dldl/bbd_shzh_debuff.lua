--比比东：噬魂蛛皇
if bbd_shzh_debuff == nil then
	bbd_shzh_debuff = class({})
	
	local m = bbd_shzh_debuff;
	
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
	     MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	     MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierIncomingDamage_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("damageRatio")
	end
	
	function m:GetModifierMoveSpeedBonus_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("moveRatio")
	end
end

