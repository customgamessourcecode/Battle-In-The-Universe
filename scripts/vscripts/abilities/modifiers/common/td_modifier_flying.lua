--怪物飞行buff，当怪物由于某些技能被推上高低的时候，给怪物加上飞行状态，这样就能下去了，下去以后再移除掉
if td_modifier_flying == nil then
	td_modifier_flying = class({})
	
	local m = td_modifier_flying;
	
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
			[MODIFIER_STATE_FLYING] = true
		}
	 
		return state
	end
end

