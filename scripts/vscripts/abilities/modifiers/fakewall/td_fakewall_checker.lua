--虚拟墙检查单位位置的buff
if td_fakewall_checker == nil then
	td_fakewall_checker = class({})
	
	local m = td_fakewall_checker;
	
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
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_EVENT_ON_UNIT_MOVED
	  }
	  return funcs;
	end
	
	function m:OnUnitMoved(keys)
		if IsServer() then
			local auraUnit = self:GetCaster()
			if auraUnit and auraUnit.fw_Checker then
				auraUnit.fw_Checker(auraUnit,self:GetParent())
			end
		end
	end
	
	function m:OnDestroy()
		if IsServer() then
			local auraUnit = self:GetCaster()
			if auraUnit and auraUnit.fw_CheckerDestroyer then
				auraUnit.fw_CheckerDestroyer(auraUnit,self:GetParent())
			end
		end
	end
end

