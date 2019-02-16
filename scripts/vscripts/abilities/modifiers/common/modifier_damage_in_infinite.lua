---可重复的伤害加深效果。重复主要是为了给不同的技能使用，不能重复将会出现覆盖的情况
--创建buff的时候必须传入ability，并且ability的键值要有ratio值，否则就没有效果
if modifier_damage_in_infinite == nil then
	modifier_damage_in_infinite = class({})
	
	local m = modifier_damage_in_infinite;
	
	function m:OnCreated(value)
		if IsServer() then
			self.ratio = value.ratio
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
	     MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierIncomingDamage_Percentage()
		if IsServer() then
			if self.ratio then
				return -self.ratio
			end
		end
	end
end

