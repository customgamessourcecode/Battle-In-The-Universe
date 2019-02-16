--单位模型变化使用的buff：可更改模型、攻击声音。投射物和弹道速度可以直接接口改变
if td_model_change == nil then
	td_model_change = class({})
	
	local m = td_model_change;
	
	function m:OnCreated(value)
		if IsServer() then
			self.model = value.model
			self.sound = value.sound
			self.permanent = value.permanent
		end
	end
	
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
	     MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
	  }
	  return funcs;
	end
	
	function m:GetModifierModelChange()
		if IsServer() then
			return self.model
		end
	end
	
	function m:GetAttackSound()
		if IsServer() then
			return self.sound
		end
	end
	
--	function m:IsPermanent()
--	
--	end
	
	function m:RemoveOnDeath()
		if IsServer() then
			return not self.permanent
		end
	end
end

