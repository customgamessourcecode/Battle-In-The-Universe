--所有怪物共有的buff
if td_modifier_creature == nil then
	td_modifier_creature = class({})
	
	local m = td_modifier_creature;
	
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
	
	function m:CheckState()
		local state = {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true
		}
	 
		return state
	end
end

