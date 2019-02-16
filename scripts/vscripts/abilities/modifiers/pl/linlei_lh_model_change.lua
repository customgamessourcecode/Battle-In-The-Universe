--林雷：龙化，替换模型
if linlei_lh_model_change == nil then
	linlei_lh_model_change = class({})
	
	local m = linlei_lh_model_change;
	
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
	     MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	     MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	  }
	  return funcs;
	end
	
	function m:GetModifierModelChange()
		return "models/items/dragon_knight/oblivion_blazer_dragon/oblivion_blazer_dragon.vmdl"
	end
	
	function m:GetAttackSound()
		return "Hero_DragonKnight.ElderDragonShoot1.Attack"
	end
	
	function m:GetModifierDamageOutgoing_Percentage()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("damage_ratio")
	end
	
	function m:GetModifierAttackSpeedBonus_Constant()
		local ability = self:GetAbility()
		return ability:GetSpecialValueFor("attackspeed_bonus")
	end
	
end

