---单位死亡检查：这个buff所在的单位死亡后，会调用指定的代码逻辑
if td_model_death_checker == nil then
	td_model_death_checker = class({})
	
	local m = td_model_death_checker;
	
	--无敌保持，并且可以同时存在多个，以便于不同的逻辑同时调用而互不干扰
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE;
	end
	
	function m:IsHidden()
		return false;
	end
	
	--是否可以被净化
	function m:IsPurgable()
		return false;
	end
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_EVENT_ON_DEATH
	  }
	  return funcs;
	end
	
	function m:OnDeath(keys)
		if IsServer() then
			local unit = self:GetParent()
			local handler = self.func
			if unit == keys.unit and type(handler) == "function" then
				xpcall(
					function() 
						return handler(keys.attacker,keys.inflictor) 
					end,
					function (msg)--错误不返回了，直接输出
						DebugPrint(msg..'\n'..debug.traceback()..'\n')
					end
				)
			end
			
		end
	end
end
