---基于回血速度百分比增加单位的回血速度，dota默认没有这个效果。
--具体看下面的AddHealRegenBasedTotalRegen的描述
if td_total_percent_health_regen == nil then
	td_total_percent_health_regen = class({})
	
	local m = td_total_percent_health_regen;
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
	     MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	  }
	  return funcs;
	end
	
	function m:GetModifierConstantHealthRegen()
		local unit = self:GetParent()
		
		--客户端没有获取单位回血速度的接口，为了保持界面显示一致，这里通过nettable去实现。这个是netTable的key。
		local key = "td_tphr_"..tostring(unit:entindex())
		if IsClient() then
--			--客户端只有查看单位回血才会进入，而且频率很高。但是不查看的话，不会进来
--			local tb = CustomNetTables:GetTableValue("custom_health_regen",key)
--			if tb then
--				return tb.value
--			end
		else
			if self.ignore_GetHealthRegen then
				return--attribues
			end
			--GetHealthRegen这个函数返回的包含基础生命恢复和modifier增加的（包括当前这个GetModifierConstantHealthRegen方法）恢复数值
			--在获取的时候要排除掉当前这个modifier，否则会死循环。因此加一个特殊标记，再进入的话，不处理（上边的return）。
			--如果只要获取基础恢复数值，用GetBaseHealthRegen
			self.ignore_GetHealthRegen = true
			local regen = unit:GetHealthRegen()
			self.ignore_GetHealthRegen = false
			
			if regen > 0  then
				local ratio = 0
				local abilities = self._abilities --所有技能的效果都添加在一个里面，这样处理的时候不会因为一个影响其他的。因为要调用GetHealthRegen
				if abilities then
					for abilityName, ability in pairs(abilities) do
						ratio = ratio + ability:GetSpecialValueFor("ratio")
					end
				end
				local value = regen * ratio / 100
				
				--SetNetTableValue("custom_health_regen",key,{value=value})
				
				return value
			end
		end
	end
	
	function m:OnRemoved()
		if IsServer() then
--			local unit = self:GetParent()
--			--客户端没有获取单位回血速度的接口，为了保持界面显示一致，这里通过nettable去实现。这个是netTable的key。
--			local key = "td_tphr_"..tostring(unit:entindex())
--			SetNetTableValue("custom_health_regen",key,nil)
		end
	end
end
