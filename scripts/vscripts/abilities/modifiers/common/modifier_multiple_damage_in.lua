---可重复的伤害加深效果。重复主要是为了给不同的技能使用，不能重复将会出现覆盖的情况
--创建buff的时候必须传入ability，并且ability的键值要有ratio值，否则就没有效果
if modifier_multiple_damage_in == nil then
	modifier_multiple_damage_in = class({})
	
	local m = modifier_multiple_damage_in;
	
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
	     MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierIncomingDamage_Percentage()
		local ability = self:GetAbility()
		if ability then
			local ratio = 0
			--某些技能有加强效果，此时去加强后的数值
			if type(ability.xxj_di_special) == "string" then
				ratio = ability:GetSpecialValueFor(ability.xxj_di_special)
			else
				ratio = ability:GetSpecialValueFor("ratio")
			end
			if self:GetStackCount() > 0 then --默认这个属性是不支持叠加的，这里处理一下叠加效果
				ratio = ratio * self:GetStackCount()
			end
			return ratio
		end
	end
end

