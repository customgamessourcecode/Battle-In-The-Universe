---马红俊：不灭火焰。承受的火系伤害加深。由于可能存在多个同类NPC，
--他们都会给怪物上这个buff，如果用dota自带的buff机制去增减火系伤害加深系数，会导致错乱
if mhj_bmhy_fire_damage_in == nil then
	mhj_bmhy_fire_damage_in = class({})
	
	local m = mhj_bmhy_fire_damage_in;
	
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
	
	function m:OnCreated(keys)
		if IsServer() then
			local caster = self:GetCaster()
			local target = self:GetParent()
			local ability = self:GetAbility()
			
			self.caster = caster
			self.ability = ability
			
			self.element_buff = Elements.AddElementDamageIn(caster,target,ability,Elements.fire)
		end
	end
	
	function m:OnRefresh(keys)
		if IsServer() then
			local caster = self:GetCaster()
			local ability = self:GetAbility()
			
			if self.ability ~= ability or self.caster ~= caster then
				if self.element_buff then
					self.element_buff:Destroy()
				end
				
				self.element_buff = Elements.AddElementDamageIn(caster,self:GetParent(),ability,Elements.fire)
			end
		end
	end
	
	function m:OnDestroy()
		if IsServer() then
			if self.element_buff then
				self.element_buff:Destroy()
			end
		end
	end
end

