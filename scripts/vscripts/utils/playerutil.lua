---玩家数据
--key是玩家id，value是一个table，包括各个玩家的数据
local PlayerData = {}
---内部数据，为了避免和其他模块调用setAttribute时用的key冲突，再维护一个表，仅供内部使用
--key是玩家id，value是一个table
local InternalData = {}

local m = {}

---金币最大数量
local maxGold = 10000000
---金币最小数量
local minGold = 0

---内部设置指定key的玩家数据。value可以是nil，会覆盖。
--已用key：
--hero（英雄实体）
--tp_active（是否可以传送）
--cards（卡片信息），exp（可用升级经验），strategy（世界策略），ability（建造者技能），builder（建造者）
--gold_ratio（金币加成系数）
local SetKV = function(player,key,value)
	if player and key then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		if type(player) == "number" and m.IsValidPlayer(player) then
			local data = InternalData[player]
			if not data then
				data = {}
				InternalData[player] = data
			end
			data[key] = value
		end
	end
end

---内部获取指定key的玩家数据
--可用key：
--hero（英雄实体）
--tp_active（是否可以传送）
--cards（卡片信息），exp（可用升级经验），strategy（世界策略），ability（建造者技能），builder（建造者）
--gold_ratio（金币加成系数），gold（金币数量）
local GetKV = function(player,key)
	if player and key then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		if type(player) == "number" and m.IsValidPlayer(player) then
			local data = InternalData[player]
			if data then
				return data[key]
			end
		end
	end
end

local colors = {
	[0]={47,116,255},
	[1]={100,255,193},
	[2]={193,0,189},
	[3]={247,241,9},
	[4]={251,105,0},
	[5]={255,129,190}
}

---初始化玩家数据
function m.AddPlayer(PlayerID)
	if PlayerID and m.IsValidPlayer(PlayerID) then
		if PlayerData[PlayerID] == nil then
			PlayerData[PlayerID] = {}
			InternalData[PlayerID] = {}
			
			---初始化部分玩家数据
			Towermgr.InitPopulation(PlayerID)
			Towermgr.StartSyncDPS(PlayerID)
			
			--初始化颜色
			local c = colors[PlayerID]
			if c then
				PlayerResource:SetCustomPlayerColor(PlayerID,c[1],c[2],c[3])
				c = nil;
			end
		end
	end
end

---设置一个玩家的英雄实体，同时根据英雄单位，初始化玩家的相应属性<br>
--当玩家断开连接后，通过玩家id将获取不到玩家，也就不能获取其控制的英雄，会出现各种bug，所以这里单独存储一下
function m.SetHero(PlayerID,hero)
	SetKV(PlayerID,"hero",hero)
end


---根据玩家信息获取对应的英雄实体。英雄实体有个函数：HasOwnerAbandoned，不知道是不是能获取玩家是否离开游戏这个状态
--@param #any player 玩家id或者玩家所拥有的单位实体
function m.GetHero(player)
	if player then
		--先尝试从缓存中读取英雄（玩家掉线以后貌似通过接口是获取不到英雄的），没有的话，在尝试返回玩家拥有的英雄
		local hero = GetKV(player,"hero")
		if hero then
			return hero
		end
		local playerEntity = PlayerResource:GetPlayer(player)
		if playerEntity then
			return playerEntity:GetAssignedHero()
		end
	end
end

---根据玩家id或者玩家拥有的实体，获取玩家实体。
--@param #any playerID 玩家id或玩家拥有的实体
--@param #boolean allState 是否返回所有状态的玩家，默认只返回连入游戏的玩家
--<ul>
--	<li>DOTA_CONNECTION_STATE_UNKNOWN</li>
--	<li>DOTA_CONNECTION_STATE_NOT_YET_CONNECTED</li>
--	<li>DOTA_CONNECTION_STATE_CONNECTED</li>
--	<li>DOTA_CONNECTION_STATE_DISCONNECTED</li>
--	<li>DOTA_CONNECTION_STATE_ABANDONED</li>
--	<li>DOTA_CONNECTION_STATE_LOADING</li>
--	<li>DOTA_CONNECTION_STATE_FAILED</li>
--</ul>
function m.GetPlayer(playerID,allState)
	if type(playerID) == "table" then
		playerID = playerID:GetPlayerOwnerID()
	end
	if allState or PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
		return PlayerResource:GetPlayer(playerID);
	end
end

---根据单位实体返回该单位所属的玩家id
function m.GetOwnerID(unit)
	if type(unit) == "table" and unit.GetPlayerOwnerID then
		return unit:GetPlayerOwnerID()
	end
end

---根据单位实体返回该单位所属的玩家id。<br>
--有一些单位是分身或者幻象类的，这些单位的拥有者默认是其本体，这样通过GetPlayerOwnerID就获取不到id
--此时要获取其归属单位，再考虑获取id
function m.GetOwnerIDForDummy(unit)
	if type(unit) == "table" and unit.GetPlayerOwnerID then
		local PlayerID = PlayerUtil.GetOwnerID(unit)
		if PlayerID and PlayerID < 0 then
			--有可能是分身、幻象，获取英雄后再获取PlayerID
			local owner = unit:GetOwner();
			PlayerID = PlayerUtil.GetOwnerID(owner)
			if PlayerID and PlayerID < 0 then
				owner = owner:GetOwner();
				PlayerID = PlayerUtil.GetOwnerID(owner)
			end
		end
		if PlayerID and PlayerID >= 0 then
			return PlayerID
		end
	end
end

---获取拥有这个单位的玩家实体
function m.GetOwner(unit)
	if type(unit) == "table" and unit.GetPlayerOwner then
		return unit:GetPlayerOwner()
	end
end

---返回所有玩家的id数组
--@param #boolean noDisconnect 忽略不在线的玩家（无论是断开连接还是离开游戏）
function m.GetAllPlayersID(noDisconnect)
	local result = {}
	for playerID, data in pairs(PlayerData) do
		if type(playerID) == "number" then
			if noDisconnect then
				if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
					table.insert(result,playerID)
				end
			else
				table.insert(result,playerID)
			end
		end
	end
	return result;
end

---判断一个玩家是否在线
function m.IsPlayerConnected(PlayerID)
	return PlayerResource:GetConnectionState(PlayerID) == DOTA_CONNECTION_STATE_CONNECTED
end

---判断一个玩家是否已经离开游戏了，彻底断开了
--@param #number PlayerID 玩家id，为空返回false
function m.IsPlayerLeaveGame(PlayerID)
	if not PlayerID then
		return false;
	end
	return PlayerResource:GetConnectionState(PlayerID) == DOTA_CONNECTION_STATE_ABANDONED
end

---这个应该是判断是否是正在游戏的玩家的。可以用来区分观战玩家
function m.IsValidPlayer(PlayerID)
	return PlayerID and PlayerResource:IsValidPlayer(PlayerID)
end

---获取当前进入游戏的玩家数量
--@param #boolean noDisconnect 忽略不在线的玩家
function m.GetPlayerCount(noDisconnect)
	if noDisconnect then
		local count = 0
		for playerID, data in pairs(PlayerData) do
			if type(playerID) == "number" then
				if noDisconnect then
					if PlayerResource:GetConnectionState(playerID) == 2 then
						count = count + 1
					end
				else
					count = count + 1
				end
			end
		end
		
		return count
	else--这个会返回加入该队伍的玩家数量，即使该玩家已经离开游戏了
		return PlayerResource:GetPlayerCountForTeam(TEAM_PLAYER)
	end
end


---获取玩家的某项属性。参数为空或者找不到，则返回nil
--@param #any player 玩家id或者单位实体
--@param #string attrName 属性标识，不可为空
function m.getAttrByPlayer(player,attrName)
	if player and attrName and PlayerData then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		if type(player) == "number" and m.IsValidPlayer(player) then
			local data = PlayerData[player]
			if data then
				return data[attrName]
			end
		end
	end
end

---设置玩家的属性
--@param #any player 玩家id或者单位实体。默认只有初始化过英雄的玩家才会有缓存数据，如果不存在缓存数据，则不会存储当前数据。
--@param #string attrName 属性标识，不可为空
--@param #any value 属性值，可为空
function m.setAttrByPlayer(player,attrName,value)
	if player and attrName and PlayerData then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		if type(player) == "number" and m.IsValidPlayer(player) then
			local data = PlayerData[player]
			if data then
				data[attrName] = value
			end
		end
	end
end

---增加某个玩家的金币
--@param #any player 玩家id或者玩家所拥有的单位实体
--@param #number gold 要修改的金币数量，可正可负。金币有最大最小数量限制，但是没有做小数处理，也就是目前是允许小数的
function m.AddGold(player,gold)
	if player and type(gold) == "number" then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		
		if type(player) == "number" and m.IsValidPlayer(player) then
			local now = GetKV(player,"gold") or 0
			now = now + gold
			
			---金币有最大最小数量限制，但是没有做小数处理，也就是目前是允许小数的
			if now < minGold then
				now = minGold
			elseif now > maxGold then
				now = maxGold
			end
			
			SetKV(player,"gold",now)
			SetNetTableValue("player_states","gold_"..tostring(player),{now=now})
		end
	end
end

---消耗某个玩家的金币。<p>
--使用modify的话，需要指明是否是可靠金钱，会导致扣钱的时候不能扣除足够的金币。
--所以用这个Spend单独处理金币减少的逻辑
--@param #any player 玩家id或者玩家所拥有的单位实体
--@param #number gold 要修改的金币数量，必须大于0。金币有最大最小数量限制，但是没有做小数处理，也就是目前是允许小数的
function m.SpendGold(player,gold)
	if type(gold) == "number" and gold > 0 then
		m.AddGold(player,-gold)
	end
end

---设置某个玩家的金币数量
--@any player 玩家id或者玩家拥有的单位实体
--@number gold 要设置的金币数量，必须大于0。金币有最大最小数量限制，但是没有做小数处理，也就是目前是允许小数的
function m.SetGold(player,gold)
	if player and type(gold) == "number" and gold > 0 then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		
		if type(player) == "number" and m.IsValidPlayer(player) then
			---金币有最大最小数量限制，但是没有做小数处理，也就是目前是允许小数的
			if gold < minGold then
				gold = minGold
			elseif gold > maxGold then
				gold = maxGold
			end

			SetKV(player,"gold",gold)
			SetNetTableValue("player_states","gold_"..tostring(player),{now=gold})
		end
	end
end
---获取某个玩家的金币数量
function m.GetGold(player)
	if player then
		if type(player) == "table" then
			player = m.GetOwnerID(player)
		end
		
		if type(player) == "number" and m.IsValidPlayer(player) then
			return GetKV(player,"gold") or 0
		end
	end
	return 0
end

---修改某玩家的金币获取加成
--@param #any PlayerID 玩家id或者单位实体
--@param #number ratio 系数，百分比值，可正可负
function m.AddGoldRatio(PlayerID,ratio)
	if PlayerID and ratio then
		local now = m.GetGoldRatio(PlayerID) or 0
		SetKV(PlayerID,"gold_ratio",now + ratio)
	end
end
---获取某个玩家的金币加成系数
function m.GetGoldRatio(PlayerID)
	return GetKV(PlayerID,"gold_ratio")
end

---获取指定玩家的SteamID
--@param #number PlayerID 玩家id
--@param #boolean returnNum 是否返回数值，默认返回的是字符串形式
function m.GetSteamID(PlayerID,returnNum)
	if returnNum then
		return PlayerResource:GetSteamID(PlayerID)
	else
		return tostring(PlayerResource:GetSteamID(PlayerID));
	end
end

---获取指定玩家的AccountID（玩家信息能看到的那一串数字）
--@param #number PlayerID 玩家id
--@param #boolean returnNum 是否返回数值，默认返回的是字符串形式
function m.GetAccountID(PlayerID,returnNum)
	if returnNum then
		return PlayerResource:GetSteamAccountID(PlayerID);
	else
		return tostring(PlayerResource:GetSteamAccountID(PlayerID));
	end
end

---获取所有玩家账号，并拼接成字符串
function m.GetAllAccount(onlyAid)
	local aids = nil;
	local sids = nil;
	for _,PlayerID in ipairs(PlayerUtil.GetAllPlayersID()) do
		local accountID = PlayerUtil.GetAccountID(PlayerID)
		if accountID then
			if aids then
				aids = aids .. "," .. accountID
			else
				aids = accountID;
			end
		end
		
		if not onlyAid then
			local steamID = PlayerUtil.GetSteamID(PlayerID)
			if steamID then
				if sids then
					sids = sids .. "," .. steamID
				else
					sids = steamID;
				end
			end
		end
	end
	
	if onlyAid then
		return {aid=aids}
	else
		return {aid=aids,sid=sids}
	end
end

--禁止传送
function m.DisabledTP(PlayerID)
	SetKV(PlayerID,"tp_active",false)
end
--允许传送
function m.EnableTP(PlayerID)
	SetKV(PlayerID,"tp_active",true)
end

---返回玩家是否可以进行传送<p>
--满足以下所有条件可以传送：
--<ol>
--	<li>玩家有控制的英雄</li>
--	<li>英雄非死亡、非眩晕、非冰冻</li>
--	<li>没有因为其他原因被禁止飞行(调用PlayerUtil:DisabledTP(PlayerID))</li>
--</ol>
function m.CanTP(PlayerID)
	local hero = m.GetHero(PlayerID)
	if not hero then
		return false;
	end
	local canTP = GetKV(PlayerID,"tp_active") or true;--没有设置，默认就是true，可以飞
	return hero:IsAlive() 
			and not hero:IsStunned() 
			and not hero:IsFrozen() 
			and canTP;
end
---玩家数据是否已经加载完毕
local playerDataLoaded = false;
local handlers = {}
---初始化玩家数据
--@return 返回是否初始化成功
function m.InitPlayerData(data)
	--测试用，以后不要了
	if not data then
		return;
	end

	local allCards = data.card or {}
	local allExp = data.exp or {}
	local allWorld = data.world or {}
	local allAbility = data.ability or {}
	local models = data.model or {}
	
	for _, PlayerID in pairs(m.GetAllPlayersID()) do
		local aid = m.GetAccountID(PlayerID)
		
		local cards = allCards[aid];
		if cards then
			SetKV(PlayerID,"cards",cards)
		end
		
		local exp = allExp[aid]
		if exp then
			SetKV(PlayerID,"exp",exp)
		end
		
		local world = allWorld[aid]
		if world then
			---有些玩家的数据有异常，会有空值，这里处理一下
			for index, strategy in pairs(world) do
				local newStrategy = nil;
				local array = Split(strategy,",")
				for _, name in pairs(array) do
					if name and name ~= "" then
						if newStrategy then
							newStrategy = newStrategy .. "," .. name
						else
							newStrategy = name
						end
					end
				end
				world[index] = newStrategy
			end
			SetKV(PlayerID,"strategy",world)
		end
		
		local ability = allAbility[aid]
		if ability then
			SetKV(PlayerID,"ability",ability)
		end
		
		local model = models[aid]
		if model then
			SetKV(PlayerID,"builder",model)
		end
	end
	
	--处理监听
	for index=#handlers, 1,-1 do
		local handler = handlers[index]
		if handler then
			local status,err = pcall(handler,data)
			if not status then
				DebugPrint("execute loaded handler faild:\n"..err)
			end
		end
	end
	--只调用一次，清空所有的监听
	handlers = nil 
	playerDataLoaded = true;
	return true;
end
---玩家数据是否加载完毕
function m.IsPlayerDataLoaded()
	return playerDataLoaded;
end
---注册一个监听，监听玩家数据的加载情况，会在玩家数据第一次加载完毕后
--调用该函数，调用完毕就会移除掉
--@param #function handler 监听，调用时会传入一个参数：data，所有玩家数据
function m.RegisterLoadedListener(handler)
	if type(handler) == "function" then
		table.insert(handlers,handler)
	end
end

---获取某个玩家拥有的所有卡片信息
--<pre>
--world = {
--	cardName = {
--		exp = 123 --总经验值
--	}
--}</pre>
function m.GetCards(PlayerID)
	return GetKV(PlayerID,"cards")
end

---更新某个玩家拥有的卡片。如果没有就新增，有了就更新经验值
--@param #number PlayerID 玩家id
--@param #string worldName 所属世界
--@param #string cardName 卡片名称
--@param #number exp 卡片经验
function m.UpdateCard(PlayerID,worldName,cardName,exp)
	local allCards = m.GetCards(PlayerID)
	if not allCards then
		allCards = {}
		SetKV(PlayerID,"cards",allCards)
	end
	
	local world = allCards[worldName]
	if not world then
		world = {}
		allCards[world] = world
		
	end
	world[cardName] = {exp = exp or 0}
end

---获取玩家的某张卡片信息，返回{exp=123}<br>
--如果该玩家并没有这张卡片，则返回nil
function m.GetCard(PlayerID,world,cardName)
	local allCards = m.GetCards(PlayerID)
	if allCards and allCards[world] then
		return allCards[world][cardName]
	end
end

---获取玩家拥有的总卡片经验
function m.GetCardExp(PlayerID)
	return GetKV(PlayerID,"exp") or 0
end

---设置玩家拥有的总卡片经验，会向客户端同步数据
function m.SetCardExp(PlayerID,exp)
	exp = exp or 0
	SetKV(PlayerID,"exp",exp)
	SendToClient(PlayerID,"custom_setup_update_player_card_exp",{exp=exp})
end

---世界策略
--<pre>
--{
--	1 = "a,b,c,d..."
--}</pre>
function m.GetWorldStrategy(PlayerID)
	return GetKV(PlayerID,"strategy")
end

---更新世界策略<p>
--worlds = "a,b,c,d..."
function m.UpdateWorldStrategy(PlayerID,index,worlds)
	local strategy = m.GetWorldStrategy(PlayerID)
	if not strategy then
		strategy = {}
		SetKV(PlayerID,"strategy",strategy)
	end
	strategy[index] = worlds
end

---建造者技能
--{ability,ability,ability...}
function m.GetBuilderAbility(PlayerID)
	return GetKV(PlayerID,"ability")
end

function m.UpdateBuilderAbility(PlayerID,abilityName)
	local ability = m.GetBuilderAbility(PlayerID)
	if not ability then
		ability = {}
		SetKV(PlayerID,"ability",ability);
	end
	
	for _, name in pairs(ability) do
		if abilityName == name then
			return;
		end
	end
	
	table.insert(ability,abilityName)
end

---建造者模型
--{modelName,modelName,modelName...}
function m.GetBuilderModel(PlayerID)
	return GetKV(PlayerID,"builder")
end

---添加玩家的建造者模型数据，并向客户端同步
function m.AddBuilderModel(PlayerID,builderName)
	if m.IsValidPlayer(PlayerID) and type(builderName) == "string" then
		local builders = GetKV(PlayerID,"builder")
		if not builders then
			builders = {}
			SetKV(PlayerID,"builder",builders)
		end
		table.insert(builders,builderName)
		
		--同步客户端
		SendToClient(PlayerID,"custom_store_builder_update",builders)
	end
end

return m;
