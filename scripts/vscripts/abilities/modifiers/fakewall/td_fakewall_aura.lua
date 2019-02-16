--虚拟墙的光环，用来给附近单位提供检测位置的buff
if td_fakewall_aura == nil then
	td_fakewall_aura = class({})
	
	local m = td_fakewall_aura;
	
	function m:OnCreated(keys)
		if IsServer() then
			self.radius = keys.radius
		end
	end
	
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
	
	function m:IsAura()
		return true
	end
	
	---不做checker检查了。太耗费资源，简单做成光环。
	--checker的目的主要是检查扭头或者偏向的时候，不加减速效果。
	--但是对于怪物来说，也不会扭头了。就不考虑转向的问题了。直接所有附近的单位都加上减速效果
	function m:GetModifierAura()
		return "td_fakewall_move_control"
	end
	
	function m:GetAuraRadius()
		if IsServer() then
			return self.radius
		end
	end
	
	function m:GetAuraSearchFlags()
		if IsServer() then
			return nil
		end
	end
	
	function m:GetAuraSearchTeam()
		if IsServer() then
			return DOTA_UNIT_TARGET_TEAM_ENEMY
		end
	end
	
	function m:GetAuraSearchType()
		if IsServer() then
			return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
		end
	end
end

