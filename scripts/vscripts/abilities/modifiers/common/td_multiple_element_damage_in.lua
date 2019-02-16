---单位受到元素伤害加深的效果。可重复，这样不同的逻辑可以分开添加
--直接增加数值缓存的话，涉及到比较麻烦的同步问题（比如添加状态的时候，技能是1级，系数是1，移除的时候，技能变成了2级，系数变成了2，按照2移除就会出错）。
--所以使用modifier来承载数值，每次要获取加成效果的时候，动态计算。
--加成比例需要在技能中添加键值：ratio
if td_multiple_element_damage_in == nil then
	td_multiple_element_damage_in = class({})
	
	local m = td_multiple_element_damage_in;
	
	--无敌保持 + 可重复
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
	
	function m:AllowIllusionDuplicate()
		return true;
	end
	
	---自定义函数
	function m:GetElementDamageInRatio()
		if IsServer() then
			local ability = self:GetAbility()
			if ability then
				local value = 0
				--某些技能有加强效果，此时去加强后的数值
				if type(ability.xxj_edi_special) == "string" then
					value = ability:GetSpecialValueFor(ability.xxj_edi_special)
				else
					value = ability:GetSpecialValueFor("ratio")
				end
				return value
			end
		end
		return 0
	end
end
