--塔在创建期间的buff
if td_modifier_tower_building == nil then
	td_modifier_tower_building = class({})
	
	local m = td_modifier_tower_building;
	
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
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true
		}
	 
		return state
	end
end

