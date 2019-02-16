--刑干的伤害加深
if memory_temp_modifier == nil then
	memory_temp_modifier = class({})
	
	local m = memory_temp_modifier;
	
	
	-----格式化后，返回一个字符串
local FormatByte = function(count)
	if count < 1024 then
		return tostring(count).." K";
	elseif count < 1024 * 1024 then
		local fmt = "%.2f"
		return string.format(fmt,count / 1024).." M"
	else
		local fmt = "%.2f"
		return string.format(fmt,count / 1024).." G"
	end
end
	
	function m:OnCreated(value)
		self:StartIntervalThink(2)
	end
	
	function m:OnIntervalThink()
		local from = "server"
		if IsClient() then
			from = "client"
		end
		
		print("\n\n------------------------------",from,"---------------------------")
		
		local count = collectgarbage("count");
		print("memory report:"..FormatByte(count).."\t("..tostring(count)..")")
		
		
		collectgarbage("collect")
		
		local count = collectgarbage("count");
		print("after collect memory report:"..FormatByte(count).."\t("..tostring(count)..")")
	end
	
	--无敌保持
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE;
	end
	

	function m:IsHidden()
		return false;
	end
	
	--是否可以被净化
	function m:IsPurgable()
		return false;
	end
	
end

