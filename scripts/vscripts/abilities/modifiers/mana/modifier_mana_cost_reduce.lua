---魔法消耗降低。用kv中的设置不会自动自动叠加，所以单独添加一个减魔耗的modifier，
--在这个modifeir里面计算所有所有添加过属性的技能的值。然后返回
if modifier_mana_cost_reduce == nil then
	modifier_mana_cost_reduce = class({})
	
	local m = modifier_mana_cost_reduce;
	
	function m:OnCreated(keys)
		if IsServer() then
			--默认客户端会一直调用获取耗蓝的方法，频率太高了，每次都计算怕影响效率，这里服务端每0.5秒计算一次
			--如果反正了变化，则设置nettable，通知客户端更新（使用refresh）
			self:StartIntervalThink(0.5)
		end
	end
	--
	function m:OnIntervalThink()
		if IsServer() then
			local unit = self:GetParent()
			if unit and not unit:IsNull() then
				--在这个modifier里面记录所有的技能，计算的时候从技能中获取实时值
				local abilities = self._mana_cost_ability
				local bonus = 0
				if abilities and #abilities > 0 then
					for _, ability in pairs(abilities) do
						if ability and not ability:IsNull() then
							bonus = bonus + ability:GetSpecialValueFor("bonus")
						end
					end
				end
				
				--最多减少100%，就算耗蓝被减成负值也不会增加蓝，所以干脆就不让出现负数耗蓝了。
				if bonus > 100 then
					bonus = 100;
				end
				
				if bonus ~= self._bonus then
					self._bonus = bonus;
					SetNetTableValue("mana_cost_reduce",tostring(unit:entindex()),{bonus=bonus})
					self:ForceRefresh()
				end
			end
		end
	end
	
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
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_PROPERTY_MANACOST_PERCENTAGE
	  }
	  return funcs;
	end
	
	---这个属性必须返回客户端的值才能在技能耗蓝上显示出来
	function m:GetModifierPercentageManacost()
		return self._bonus
	end
	
	function m:OnDestroy()
		if self._bonus then
			self._bonus = nil
			--清空一下nettable
			if IsServer() then
				local unit = self:GetParent()
				SetNetTableValue("mana_cost_reduce",tostring(unit:entindex()),nil)
				self._mana_cost_ability = nil
			end
		end
	end
	
	function m:OnRefresh()
		if IsClient() then
			--客户端没有方法FindAllModifiersByName，所以只能通过nettable去获取数值了。又要累积内存了。。。。
			local unit = self:GetParent()
			local data = CustomNetTables:GetTableValue("mana_cost_reduce",tostring(unit:entindex()));
			if data and data.bonus then
				self._bonus = data.bonus
			end
		end
	end
end

