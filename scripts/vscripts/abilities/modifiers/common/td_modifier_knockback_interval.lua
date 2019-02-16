--击退冷却
if td_modifier_knockback_interval == nil then
	td_modifier_knockback_interval = class({})
	
	local m = td_modifier_knockback_interval;
	
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
end

