--虚拟墙检查单位位置的buff
if td_fakewall_move_control == nil then
	td_fakewall_move_control = class({})
	
	local m = td_fakewall_move_control;
	
	--无敌保持，可以重复。可能有不同的技能都有墙效果
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
	
--	function m:DeclareFunctions()
--	    local funcs = {
--			MODIFIER_PROPERTY_MOVESPEED_MAX,
--	        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
--	        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
--	    }
--	
--	    return funcs
--	end
--	
--	function m:GetModifierMoveSpeed_Max()
--	    if IsServer() then
--	    	return 0.1
--	    end
--	end
--	
--	function m:GetModifierMoveSpeed_Limit()
--	    if IsServer() then
--	    	return 0.1
--	    end
--	end
--	
--	function m:GetModifierMoveSpeed_Absolute()
--	    if IsServer() then
--	    	return 0.1
--	    end
--	end

	function m:CheckState()
		local state = {
			[MODIFIER_STATE_ROOTED] = true
		}
	 
		return state
	end
	
	function m:OnDestroy()
		if IsServer() then
			--避免卡位
			local target = self:GetParent();
			Teleport(target,target:GetAbsOrigin())
		end
	end
end

