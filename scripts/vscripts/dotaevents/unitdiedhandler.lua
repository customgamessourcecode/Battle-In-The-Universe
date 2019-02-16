--单位死亡处理，主要是物品掉落，任务处理等
--死亡监听事件的优先级【低于】物品和技能中的OnOwnerDied事件的优先级


local m = {}
---存储特定敌方单位死亡时的处理器。每一个元素的key是单位名称，value是一个table。
--table的key是一个唯一字符串
--value代表一个处理器，其中包括两个元素{num（死亡总数）,handler}
m.nameHandlers = {}
---存储任意敌方单位死亡时的处理器
--元素有一个唯一的key，value是处理函数
m.handlers = {}

--单位被击杀时的处理，只保证流程，具体的处理操作，在对应的函数中进行
function m:OnEntityKilled(keys)
--	-- 被击杀者
--	local diedUnit = EntityHelper.findEntityByIndex( keys.entindex_killed )
--	
--	--判断输赢，如果所杀的怪物就是可以决定输赢的怪，就终止处理
--	if m.IsGameOver(diedUnit) then
--		return;
--	end
--	
--	--英雄被杀，只处理真是英雄死亡，幻象死亡暂时不处理
--	if diedUnit:IsHero() then
--		if diedUnit:IsRealHero() then --只有真身死亡才会复活
--			m.RespawnHero(diedUnit);
--		end
--		return;
--	end
--
--	--其他情况
--	local killer --杀手单位
--	if keys.entindex_attacker ~= nil then
--		killer = EntityHelper.findEntityByIndex( keys.entindex_attacker )
--	end
--	--先处理任意单位死亡逻辑，主要用在杀怪升级武器等不需要特定怪的情况
--	for key, handler in pairs(m.handlers) do
--		if not handler.invalid then
--			local status,stop = m.executeHandler(handler.func,killer,diedUnit)
--			if status and stop then
--				m.handlers[key] = nil;
--			end
--		else
--			m.handlers[key] = nil;
--		end
--	end
--	--再处理特定单位死亡,任务怪物
--	local handlers = m.nameHandlers[diedUnit:GetUnitName()];
--	if handlers then
--		--玩家id，用来记录某个玩家杀了多少个特定的怪物
--		local playerID = nil
--		if killer and killer:GetTeam() == TEAM_PLAYER then
--			playerID = PlayerUtil.GetOwnerID(killer)
--		end
--		local killerKilled = nil; --当前杀手所属玩家一共击杀了多少个
--		for key, handler in pairs(handlers) do
--			local func = handler.func;
--			if func then
--				if not handler.invalid then
--					handler.total = (handler.total or 0) + 1;
--					if playerID then --累计某个玩家的击杀数量
--						handler.playerKilled[playerID] = (handler.playerKilled[playerID] or 0) + 1
--						killerKilled = handler.playerKilled[playerID]
--					end
--					local status,stop = m.executeHandler(func,killer,diedUnit,handler.total,killerKilled);
--					--不再继续的话，删除该处理函数
--					if status and stop then
--						handlers[key] = nil;
--					end
--				else
--					handlers[key] = nil;
--				end
--			end
--		end
--	end

end

-----------------------------------------------下面是各个处理单位被杀的函数-----------------------------------------------------------------

---设置是否禁用英雄默认的复活逻辑。禁用以后，英雄死亡了则不会自动进入复活倒计时，也不会复活
function m.SetRespawnDisabled(hero,disabled)
	hero.NotUseDefaultRespawnLogic = disabled;
end

---能够减少复活时间的道具信息
--key是道具名，value是对应的复活时间。
--从上到下按照时间长短升序。即，越往前的物品复活越快。这样在实际处理的时候，即以第一个匹配到的时间为准即可
local item2time = {
	item_stick_lh3_ld = 7,--灵锻轮回珠
	item_stick_lh3 = 8,--3级轮回珠
	item_stick_lh2 = 10,--2级轮回珠
	item_stick_lh = 12, --轮回珠
}

---获取英雄的复活时间。主要是处理由于某些因素导致复活时间减少的逻辑
local getRespwanTime = function(hero)
	local respwanTime = 15;--默认15秒复活时间
	for itemName, time in pairs(item2time) do
		--由于item2time中已经做了排序，所以匹配到的第一个就是最短时间，以此为结果
		if fun_item.HasItemInBody(hero,itemName) then
			respwanTime = time
			break;
		end
	end
	return respwanTime
end

---英雄重生
--@param #table diedHero 死亡的英雄
--@param #boolean force 强制复活，将忽略SetRespawnDisabled的设置信息
function m.RespawnHero(diedHero,force)
	if diedHero:IsAlive() then
		return
	end
	--NotUseDefaultRespawn，有些特殊的逻辑会禁用默认的复活，比如张小凡的灵锻武器本身带有复活，就不用这个复活了
	if diedHero.NotUseDefaultRespawnLogic and not force then
		return;
	end
	
	local point= Entities:FindByName(nil,"point_caomiao_spawn"):GetAbsOrigin()  --草庙村复活点坐标
	point = point+RandomVector(RandomFloat(0, 800))

	local timeToRespwan = getRespwanTime(diedHero) --复活时间
	
	local playerID = diedHero:GetPlayerID();
	--复活时间计时器
	TimerUtil.createTimer(function ()
		--计时结束英雄还没有复活，就复活英雄。 有些时候timeToRespwan会变成nil，这里一样认为可以复活
		if (timeToRespwan == nil  or timeToRespwan <= 0) and not diedHero:IsAlive() then
			m.doRespawn(diedHero,point);
			return;
		end
		if not GameRules:IsGamePaused() then
			NotifyUtil.Bottom(playerID,timeToRespwan,1,"red",false)
			NotifyUtil.Bottom(playerID,"#zxj_respwan_hint",1,"red",true)

			timeToRespwan = timeToRespwan - 1
			--当断线重连的时候，会出现负值，所以如果出现负值，则立刻复活英雄（目前还没找到原因，先这么处理）
			if timeToRespwan < 0 then
				m.doRespawn(diedHero,point);
				return 
			end
		end
		return 1;  --函数1秒执行一次
	end)
end

---复活英雄，血量为60%，蓝量为50%
--@param #table diedHero 复活后的英雄
--@param #Vector point 复活地点
function m.doRespawn(diedHero,point)
	Teleport(diedHero,point)
	diedHero:RespawnHero(false, false) --复活
	diedHero:SetHealth(diedHero:GetMaxHealth() * 0.6)
	diedHero:SetMana(diedHero:GetMaxMana() * 0.5)
end

---判断游戏是否结束
--@param #table diedUnit 死亡的单位
--@return #boolean true表示游戏结束（可能输了或赢了）
function m.IsGameOver(diedUnit)
	if diedUnit then
		local diedUnitName = diedUnit:GetUnitName();
		--草庙村基地被爆
		if diedUnitName == "npc_caomiao_jidi" and GetStage() <= 2  then
			m.invokeGameOverListener(false);
			GameRules:SetCustomVictoryMessage( "兽神大军获得了胜利" )  --胜利信息
			GameRules:MakeTeamLose(TEAM_PLAYER)
			return true;
		end
		--青云基地被爆
		if diedUnitName == "npc_qinyun_jidi" then
			m.invokeGameOverListener(false);
			GameRules:SetCustomVictoryMessage( "兽神大军获得了胜利" )  --胜利信息
			GameRules:MakeTeamLose(TEAM_PLAYER)
			return true;
		end
		
		--兽神被击杀，游戏胜利
		if diedUnitName == "npc_boss_shouyao" then
			Notifications:TopToAll({text="胜利！，游戏将会在60秒后结束", duration=5.0})
			m.invokeGameOverListener(true);
			GameRules:SetCustomVictoryMessage( "各位大侠成功守卫了青云门！" )  --胜利信息
			GameRules:MakeTeamLose(TEAM_ENEMY)
			return true;
		end
	end
	return false;
end


-- ------------------------------------------------------------------------------------------------
--									死亡监听处理逻辑
-- ------------------------------------------------------------------------------------------------


---添加一个<b style="color:red;">特定非英雄单位</b>死亡的监听处理逻辑。
--@param #string unitName 单位名称
--@param #function handler 单位死亡时的处理函数，
--每次调用handler的时候会为handler传入以下参数：(killer,diedUnit,totalKilled,killerKilled)
--<ol>
--	<li>killer：杀手单位</li>
--	<li>diedUnit：死亡单位</li>
--	<li>totalKilled：从加入处理函数到当前调用，一共死了多少个怪物</li>
--	<li>killerKilled：从加入处理函数到当前调用，当前杀手所属玩家一共击杀了多少个</li>
--</ol>
--handler处理完后，如果handler返回true，表示处理完毕，将删除该任务，即不会再次调用；否则会再次被触发
--@return #string 处理器的key，可以用来删除
function m.listenUnitDiedByName(unitName,handler)
	if not unitName or type(handler) ~= "function" then
		return;
	end
	if m.nameHandlers[unitName] == nil then
		m.nameHandlers[unitName] = {}
	end
	local key = DoUniqueString(unitName) --使用字符串key来索引，这样将对应的handler置空后，垃圾回收就能起作用了。
	
	
	m.nameHandlers[unitName][key] = {
		total=0,--从调用该处理器开始，一共死了多少个指定怪物。
		func=handler,
		invalid=false,
		playerKilled = {}--playerKilled存储每一个玩家杀死的怪物数量，key是玩家id
	}
	return key;
end


---根据单位名称和处理器的key移除处理器（在下次调用前失效）。对应listenUnitDiedByName（unitName,handler）
function m.removeListenerByUnitAndKey(unitName,key)
	if unitName and key then
		local handler = m.nameHandlers[unitName][key];
		if handler  then --失效即可。在实际使用的时候移除
			handler.invalid = true;
		end
	end
end

---添加一个非英雄单位死亡的监听处理逻辑。<b style="color:red;">任何非英雄单位死亡都会触发。</b>
--@param #function handler 单位死亡时的处理函数，
--每次调用handler的时候会为handler传入以下参数：
--<ol>
--	<li>killer：杀手单位</li>
--	<li>diedUnit：死亡单位</li>
--</ol>
--handler处理完后，如果返回true，表示处理完毕，将删除该任务，即不会再次调用；否则会再次被触发
--@return #string 返回处理器的key
function m.listenUnitDied(handler)
	if type(handler) == "function" then
		local key = DoUniqueString("handler") --使用字符串key来索引，这样将对应的handler置空后，垃圾回收就能起作用了。
		m.handlers[key] = {func=handler,invalid=false}
	end
end

---根据处理器的key移除处理器（在下次调用前失效）。对应：listenUnitDied（handler）
function m.removeHandlerByKey(key)
	if key then
		local handler = m.handlers[key];
		if handler  then --失效即可。在实际使用的时候移除
			handler.invalid = true;
		end
	end
end

---以保护模式运行一个处理器<br/>
--如果handler不为空，则返回handler是否执行成功和handler的返回值。
--@param #function handler 处理函数
--@param #table killer 杀手单位
--@param #table diedUnit 死亡单位
--@param #number totalKilled 一共死亡了多少个
--@param #number killerKilled 杀手单位杀死了多少个
--@return #boolean 函数是否执行成功
--@return #boolean 是否需要删除该函数
function m.executeHandler(handler,killer,diedUnit,totalKilled,killerKilled)
	if handler then
		return xpcall(function() return handler(killer,diedUnit,totalKilled,killerKilled) end,
			function (msg)--错误不返回了，直接输出
				DebugPrint(msg..'\n'..debug.traceback()..'\n')
			end)
	end
end


----添加游戏结束监听。非作弊模式下才会触发监听
----@func 监听函数。在游戏结束时触发，并将玩家是否获胜playerWin传入给该函数
--function m:addGameOverListener(func)
--	if m.listeners == nil then
--		m.listeners = {}
--	end
--	table.insert(m.listeners,func)
--end

---触发游戏结束的监听。非作弊模式下才会触发。
--@param #boolean playerWin 玩家是否胜利
function m.invokeGameOverListener(playerWin)
	if not GameRules:IsCheatMode() then
		local sid = "";
		local aid = "";
		local pc = 0;
		local nd = GetTDDifficulty();
		local win = "0";
		if playerWin then
			win = "1";
		end
		for _, playerID in ipairs(PlayerUtil.GetAllPlayersID()) do
			--只记录仍然在游戏中的玩家，掉线(3)的和离开游戏(4)的不积分
			if PlayerResource:GetConnectionState(playerID) == 2 then
				sid = sid .. "," ..PlayerUtil.GetSteamID(playerID);
				aid = aid .. "," ..PlayerUtil.GetAccountID(playerID);
				pc = pc+1;
			end
		end
		if pc > 0 then
			sid = string.sub(sid,2)
			aid = string.sub(aid,2)
			local params = {sid=sid,aid=aid,pc=tostring(pc),nd=tostring(nd),ps=win};
			http.get("gf",params,function(data)end);
		end
	end
end

return m
