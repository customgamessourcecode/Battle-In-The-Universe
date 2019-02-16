--聊天信息处理
local m = {};
m.equal = {};
m.findStr = {};

function m.init()
	if not IsInToolsMode() then
		return;
	end

	m.addStr("-e",function(splitArray,playerID,hero)
		local unitName = "test_unit"
		local num = 5
		local arg2 = splitArray[2]
		if type(arg2) == "string" then
			if tonumber(arg2) then
				num = tonumber(arg2)
			else
				unitName = arg2
			end
		end
		local arg3 = splitArray[3]
		if arg3 then
			num = tonumber(arg3) or 5
		end		
		
		for var=1, num do
			local unit = CreateUnitByName(unitName, hero:GetAbsOrigin() + RandomVector(RandomInt(300,600)), true, nil, nil, DOTA_TEAM_BADGUYS)
			if unit then
				unit:SetControllableByPlayer(playerID,true)--是否可以进行控制，如果不可被控制，则即便能选中，也不能移动、操作
				unit._armorType = Elements.randomElement()
			end
		end
	end)
	
	--创建不定数量的物品
	m.addStr("-citem",function(splitArray,playerID,hero)
		local itemName = splitArray[2]
		local num = splitArray[3] or 1
		if hero then
			for var=1, num do
				ItemUtil.CreateItemOnGround(itemName,hero,hero:GetAbsOrigin())
			end
		end
	end)
	
	--用指定的模型创建单位来测试（mt=model test）
	m.addStr("-mt",function(splitArray,PlayerID,hero)
		local modelName = splitArray[2]
		local modelScale = splitArray[3]
		
		local unit = PlayerUtil.getAttrByPlayer(PlayerID,"_temp_model")
		--已经存在了就删除
		if not unit then
			--缓存
			unit = CreateUnitEX(hero:GetUnitName(),hero:GetAbsOrigin(),true,hero);
			PlayerUtil.setAttrByPlayer(PlayerID,"_temp_model",unit)
		else
			unit:RemoveModifierByName("td_model_change")
		end
		ChangeModelTemporary(unit,modelName)
		unit:SetModelScale(tonumber(modelScale));
		unit:SetControllableByPlayer(PlayerID,true)--是否可以进行控制，如果不可被控制，则即便能选中，也不能移动、操作
	end)
	
	m.addStr("-gold",function(array,PlayerID,hero)
		if array and PlayerUtil.IsValidPlayer(PlayerID) then
			local gold = array[2]
			gold = ParseFloatToDecimal(parseNumber(gold),0,true)
			--这里允许负数了
			PlayerUtil.AddGold(PlayerID,gold)
		end
	end)

	
--	m.addEqual("-start",function(text,PlayerID,hero)
----		TimerUtil.createTimerWithDelay(5,function()
----			print("unit == nil ",unit == nil)
----			
----			local count = collectgarbage("count");
----			print("memory report:"..FormatByte(count).."\t("..tostring(count)..")".."\t come from :"..(IsClient() and "client" or "server"))
----			
----			
----			collectgarbage("collect")
----			
----			local count = collectgarbage("count");
----			print("after collect memory report:"..FormatByte(count).."\t("..tostring(count)..")".."\t come from :"..(IsClient() and "client" or "server"))
----			
----			return 2;
----		end)
--
--		AddLuaModifier(hero,hero,"memory_temp_modifier",{})
--	end)
	

	
end

---函数参数：text,playerID,hero
function m.addEqual(key,func)
	m.equal[key]=func
end

---函数参数：text[],playerID,hero
function m.addStr(key,func)
	m.findStr[key]=func
end

--当玩家发送聊天消息的时候
function m:OnPlayerChat(keys)
	local userID = keys.userid
	local playerID = keys.playerid
	local hero = PlayerUtil.GetHero(playerID)

	local text = keys.text

	for key, func in pairs(m.equal) do
		if text == key then
			local result,error = pcall(func,text,playerID,hero)
			if not result and error then
				DebugPrint(error)
			end
			return;
		end
	end
	for key, func in pairs(m.findStr) do
		if string.find(text,key) ~= nil then
			local result,error = pcall(func,Split(text," "),playerID,hero)
			if not result and error then
				DebugPrint(error)
			end
			return;
		end
	end
end

m.init();
return m;
