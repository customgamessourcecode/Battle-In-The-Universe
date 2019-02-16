---斗罗大陆奥斯卡的技能中需要用到某个单位最后使用的技能
--没有相关接口，只能通过这个buff来记录
if td_modifier_unit_ability_recorder == nil then
	td_modifier_unit_ability_recorder = class({})
	
	local m = td_modifier_unit_ability_recorder;
	
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
	     MODIFIER_EVENT_ON_ABILITY_EXECUTED
	  }
	  return funcs;
	end
	
	function m:OnAbilityExecuted(keys)
		if IsServer() then
			local unit = self:GetParent()
			---keys.unit是施法单位
			if unit == keys.unit then
				local ability = keys.ability
				--不记录物品
				if ability:IsItem() then
					return;
				end
				local usedAbilities = unit._used_abilities
				if not usedAbilities then
					usedAbilities = {}
					unit._used_abilities = usedAbilities
				end
				--记录两个技能
				if #usedAbilities == 2 then
					table.remove(usedAbilities,1)
				end
				table.insert(usedAbilities,ability)	
			end
		end
	end
end
