---自定义护甲，参考damage_reduce里面的说明
if modifier_custom_armor_multi == nil then
	modifier_custom_armor_multi = class({})
	
	local m = modifier_custom_armor_multi;
	
	--创建计时器，当技能升级或者关联的modifier叠加层数变化的时候，更新nettable
	function m:OnCreated(keys)
		if IsServer() then
			self.ref = keys.ref
			self:StartIntervalThink(0.5)
		end
	end
	
	function m:OnIntervalThink()
		if IsServer() then
			local ability = self:GetAbility()
			if EntityNotNull(ability) and ability:GetLevel() ~= self._abilityLevel then
				self._abilityLevel = ability:GetLevel()
				CustomArmor.UpdateArmorNettable(self:GetParent())
			elseif self.ref and self:GetParent() then
				--转换成modifeir实体，避免每次都查询。在create的时候可能会获取不到这个关联的modifier
				--因为一般创建这个护甲buff都是在关联的modifier创建的时候执行的，那个时候还获取不到关联modifier
				if type(self.ref) == "string" and not self.refModifier then
					local unit = self:GetParent()
					--获取关联的buff实体，由于可能存在同名单位，所以可能存在同名的这个buff，这里只获取和当前护甲buff同一个技能的那个buff
--					local modifier = nil
--					local ability = self:GetAbility()
--					local modifiers = unit:FindAllModifiersByName(ref)
--					if modifiers then
--						for _, m in pairs(modifiers) do
--							if m:GetAbility() == ability then
--								modifier = m;
--								break;
--							end
--						end
--					end
					--忽略buff的来源技能，这样同名单位的同名技能效果实际是可以叠加的。
					--用上边的逻辑的话，必须保证ref的modifier是可重复的才行，但是可重复又容易出其他问题，所以这里忽略掉
					local modifier = unit:FindModifierByName(self.ref)
					if modifier then
						self.refModifier = modifier
					end
				end
				if EntityNotNull(self.refModifier) and self.refModifier:GetStackCount() ~= self._refStatckCount then
					self._refStatckCount = self.refModifier:GetStackCount()
					CustomArmor.UpdateArmorNettable(self:GetParent())
				end
			end
		end
	end
	
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE;
	end
	
	function m:IsHidden()
		return true;
	end
	
	function m:IsPurgable()
		return false;
	end
	--对幻象有效
	function m:AllowIllusionDuplicate()
		return true;
	end
	
	---自定义函数：从技能中获取护甲值。技能中需要有armor键值
	function m:GetCustomArmor()
		local ability = self:GetAbility()
		if ability then
			local armor = 0
			--某些技能有加强效果，此时去加强后的数值
			if type(ability.armor_special) == "string" then
				armor = ability:GetSpecialValueFor(ability.armor_special)
			else
				armor = ability:GetSpecialValueFor("armor")
			end
			
			--处理叠加效果
			if self.refModifier then
				if EntityNotNull(self.refModifier) and self.refModifier:GetStackCount() > 0 then
					armor = armor * self.refModifier:GetStackCount()
				end
			end
			
			return armor
		end
		
		return 0
	end
end


