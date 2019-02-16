local m = {}

local gid = nil;
---配置界面在客户端只创建一次，后续通过显示隐藏来控制
local PanelID = "custom_td_setup"
---游戏是否开始，游戏开始倒计时的时候就认为是已经开始了。跟game_state并不完全同步
local gameStarted = false;
---游戏状态：0代表初始化；1代表难度选择；2代表游戏开始前的准备阶段；3代表游戏战斗开始
local game_state = 0
---玩家的游戏状态，区别于上边的game_state
-- 0：初始化
-- 1：已准备（点了下一步）
-- 	不可修改策略
-- 	不可修改建造者和建造者技能
-- 	可以进行卡片的升级操作
-- 2：等待中
-- 3：难度选择中
-- 4：游戏开始
--状态存储在PlayerUtil中。
local key_state = "player_state";
---玩家数据中存储玩家选择的游戏难度的key，value是一个数字（可能没有）
local key_diff = "setup_diff"
---配置界面选择的要在本局使用的世界
local key_selected_world = "setup_worlds"
---本局使用的策略
local key_selected_world_index = "setup_worlds_index"
---玩家配置的结果是否已经保存了
local key_player_setup_data_saved = "setup_player_data_saved"

---建造者模型
--key是名称，value一个table{hero=对应的英雄单位名称}
local builders = {
	gongxueyan = {hero="npc_dota_hero_phantom_assassin"},---宫雪妍，默认的
	yuwenxiao = {hero="npc_dota_hero_juggernaut"},---宇文骁
	nangongxun = {hero="npc_dota_hero_dragon_knight"},---南宫荀
	suyaner = {hero="npc_dota_hero_crystal_maiden"},---苏嫣儿
}

---各个vip等级的开局奖励
local vipReward = {
	[1] = {item_box_base_equipment_1 = 1,item_box_jj_equipment_1 = 1},
	[2] = {item_box_base_equipment_1 = 2,item_box_jj_equipment_1 = 2},
	[3] = {item_box_base_equipment_2 = 2,item_box_jj_equipment_2 = 1},
	[4] = {item_box_base_equipment_2 = 2,item_box_jj_equipment_2 = 2},
	[5] = {item_box_base_equipment_3 = 2,item_box_jj_equipment_3 = 1},
	[6] = {item_box_base_equipment_3 = 2,item_box_jj_equipment_3 = 2},
	[7] = {item_box_base_equipment_4 = 2,item_box_jj_equipment_4 = 1},
	[8] = {item_box_base_equipment_4 = 2,item_box_jj_equipment_4 = 2},
	[9] = {item_box_base_equipment_5 = 2,item_box_jj_equipment_5 = 1},
	[10] = {item_box_base_equipment_5 = 2,item_box_jj_equipment_5 = 2},
}

---初始化配置界面
function m.SetupInit()
	if not TD_GMAE_MODE_TEST and IsCheatMode() and not IsInToolsMode() then
		--稍微延迟一下，要不然总是不显示
		TimerUtil.createTimerWithDelay(5,function()
			NotifyUtil.Top(nil,"info_cheat_mode_tip",600,"red",nil,{["font-size"]="50px"})
		end)
		return;
	end

	--给在线玩家显示初始化界面
	--一个玩家不自动开始，多人的话，倒计时结束强制开始。
	local playerCount = 0
	for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID(false)) do
		playerCount = playerCount + 1
		--玩家在线，显示界面
		if PlayerResource:GetConnectionState(PlayerID) == 2 then
			m.ShowSetup(PlayerID,true)
		end
	end
	
	--显示倒计时。这样显示倒计时可能会有问题，就是倒计时开始的时候，服务器还没加载完玩家数据。
	--这样客户端实际拥有的设置时间就少于给定的time_setup了（因为倒计时是显示配置界面就开始的单独任务，和数据是否加载完毕没有关系）
	--后续需要将这两者整合一下
	if playerCount > 1 then
		---初始化界面的操作时间
		local time = config_td_time_setup();
		TimerUtil.createTimer(function()
			SendToAllClient("xxdld_setup_timer",{sec=time})
			if time == 0 then
				m.ShowDifficultyVote()
			else
				time = time - 1;
				return 1;
			end
		end)
	else
		SendToAllClient("xxdld_setup_timer",{sec=-1})
	end
end

---为某个玩家显示配置界面
--@param #number PlayerID 玩家id
--@param #boolean isInit 是否初始化，初始化的时候才创建，否则只设置显隐
function m.ShowSetup(PlayerID,isInit)
	if not isInit then
		CustomUI:DynamicHud_SetVisible(PlayerID,PanelID,true);
	else
		CustomUI:DynamicHud_Create(PlayerID,"custom_td_setup","file://{resources}/layout/custom_game/setup/setup.xml",nil);
		m.UpdatePlayerState(PlayerID,0)
	end
end
---隐藏世界配置界面
function m.HideSetup(PlayerID)
	CustomUI:DynamicHud_SetVisible(PlayerID,PanelID,false);
end

---检查玩家状态，如果都准备了就开始游戏；否则显示等待界面
function m.ShowWaitOrStart(PlayerID)
	--所有玩家，包含断开连接的玩家
	local players = PlayerUtil.GetAllPlayersID(false);
	local playerCount = #players;
	
	--只有一个人，直接进入难度选择。多个人的时候，判断是否都准备了，都准备了才进入难度选择
	if playerCount == 1 then
		SendToClient(PlayerID,"xxdld_setup_enterd",{})
		m.ShowDifficultyVote(PlayerID);
	else
		local readyCount = 0;
		--用来向客户端同步数据的
		local netdata = {}
		for _, PlayerID in pairs(players) do
			local sid = PlayerUtil.GetSteamID(PlayerID)
			local online = PlayerUtil.IsPlayerConnected(PlayerID)
			local state = PlayerUtil.getAttrByPlayer(PlayerID,key_state)
			
			netdata[PlayerID] = {sid=sid,online=online,state=state}
			
			if state == 1 then
				readyCount = readyCount + 1;
			end
		end
		
		SendToClient(PlayerID,"xxdld_setup_enterd",{wait = readyCount ~= playerCount})
		SendToAllClient("xxdld_setup_waiting_notify",netdata)
		---所有玩家都准备了，进入难度选择
		if readyCount == playerCount then
			m.ShowDifficultyVote();
		end
	end
end
---显示难度选择界面，PlayerID=-1的时候，给所有人创建界面
local ShowDifficultyVoteUI = function(PlayerID)
	PlayerID = PlayerID or -1
	CustomUI:DynamicHud_Create(PlayerID,"setup_difficulty_vote","file://{resources}/layout/custom_game/setup/difficulty/difficulty.xml",nil);
	if PlayerID > -1 then
		m.UpdatePlayerState(PlayerID,3)
	else
		for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
			m.UpdatePlayerState(PlayerID,3)
		end
	end
end

---隐藏初始化界面，难度选择计时开始
local StartDifficultyVoteTimer = function()
	--客户端动画隐藏设置界面，这个界面是在难度选择界面上面的，使用动画移动出去
	SendToAllClient("xxdld_setup_start_difficulty_vote",{})
	
	local count = config_td_time_difficulty()
	TimerUtil.createTimer(function()
		SendToAllClient("xxdld_setup_difficulty_timer",{count = count})
		if count == 0 then
			m.ConfirmDifficulty();
		else
			count = count - 1;
			return 1;
		end
	end)
end

---显示游戏难度选择界面，并给没有选择世界或者选择的数量不够的玩家随机世界。
--@param #number PlayerID 玩家id，当只有一个玩家的时候传入。一个玩家的话就直接进入难度选择界面，不显示右下角的开始提示了
function m.ShowDifficultyVote(PlayerID)
	--多个条件都会进入这个方法，只有第一次有效
	if game_state == 0 then
		game_state = 1
		
		--检查所有玩家配置结果是否已经保存了，没有保存可能是玩家没有选择世界，此时随机世界
		for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
			m.InitPlayerConfig(PlayerID)
		end
		
		--如果只有一个玩家，直接显示难度选择界面，因为这个时候不会自动开始，肯定点击了下一步的，明确进入难度选择
		--不止一个玩家的时候，先发送提示信息，然后延迟一点显示难度界面，避免玩家在等待期间查看卡片技能呢，突然就跳到难度选择了。
		if PlayerID then
			ShowDifficultyVoteUI(PlayerID)
			StartDifficultyVoteTimer()
		else
			--先通知客户端，3秒后才真正显示难度选择界面
			SendToAllClient("xxdld_setup_prompt_difficulty_vote_starting",{})
			TimerUtil.createTimerWithDelay(3,function()
				ShowDifficultyVoteUI(-1)
				StartDifficultyVoteTimer()
			end)
		end
	end
end

---根据玩家投票结果确定游戏难度
local InitDifficulty = function()
	local players = PlayerUtil.GetAllPlayersID(false);
	local playerCount = #players
	
	local difficulty = nil
	--选择各个难度的人数key是难度，value是人数
	local result = {}
	for _, PlayerID in pairs(players) do
		local chosen = PlayerUtil.getAttrByPlayer(PlayerID,key_diff) or 1
		result[chosen] = (result[chosen] or 0) + 1;
		
		--已经有难度过半了，直接确定
		if result[chosen] > playerCount / 2  then
			difficulty = chosen;
			break;
		end
	end
	
	--尚未确定难度，根据投票结果确定难度
	if difficulty == nil then
		local maxNum = 0;--选的最多的人
		local maxChosenDiff = 0;--选的最多的难度
		local minDiff = 0;--最低难度
		local equal = true;--各个难度选择人数否一致
		
		for diff, num in pairs(result) do
			if equal and maxNum ~= 0 and num ~= maxNum then
				equal = false;
			end
		
			--记录最多最少的人数以及最多人数选的难度是什么
			if num > maxNum then
				maxNum = num;
				maxChosenDiff = diff;
			end
			
			--记录最低难度
			if minDiff == 0 or diff < minDiff then
				minDiff = diff;
			end
		end
		
		if equal then
			difficulty = minDiff
		else
			difficulty = maxChosenDiff
		end
	end
	
	SetDifficulty(difficulty)
end

---难度选择结束后，开始游戏<p>
--根据难度选择结果确定最终难度：<br>
--1.选择某难度的超过半数，就确定为该难度<br>
--2.如果难度选择数量不平均，且没有超过半数的，选人最多的<br>
--2.如果难度选择数平均，选择最低难度<br>
function m.ConfirmDifficulty()
	if not PlayerUtil.IsPlayerDataLoaded() then
		return;
	end


	--由于所有玩家投票结束后就立刻开始，可能和倒计时的冲突，这里添加一个标记，避免难度选择倒计时结束后，再来一遍。
	if not gameStarted then
		gameStarted = true;
		
		InitDifficulty()
	
		--倒计时
		local count = 3
		TimerUtil.createTimer(function()
			local data = {count=count}
			--发送第一个通知的时候，带上最终确定的难度是哪一个，在客户端会有一个特殊标记
			if count == 3 then
				data.confirmed = GetTDDifficulty()
			end
			SendToAllClient("xxdld_setup_difficulty_start_game",data)
			
			if count == 0 then
				--销毁难度选择界面，开始游戏
				CustomUI:DynamicHud_Destroy(-1,"setup_difficulty_vote")
				m.StartGame()
			else
				count = count - 1;
				return 1;
			end
		end)
		
		--此时如果有人没有选择世界，则随机世界
		local Players = PlayerUtil.GetAllPlayersID()
		for key, PlayerID in pairs(Players) do
			if not PlayerUtil.IsPlayerLeaveGame(PlayerID) and not PlayerUtil.getAttrByPlayer(PlayerID,key_selected_world) then
				local strategy = PlayerUtil.GetWorldStrategy(PlayerID)
				if strategy then
					--有策略选取策略1
					m.InitPlayerSelectWorld(PlayerID,strategy,1)
				else
					--随机世界
					m.InitPlayerSelectWorld(PlayerID,nil,1)
				end
			end
		end
	end
end

---获取初始金币
local GetInitialGold = function(difficulty)
	local gold = 2000
	if difficulty == 2 then gold = 3000 
	elseif difficulty == 3 then gold = 4000 
	elseif difficulty >= 4 then gold = 5000 
	end
	return gold
end

local initGID = function(difficulty,mode)
	local params = PlayerUtil.GetAllAccount(true)
	params.diff = difficulty
	params.mode = mode
	http.load("xxj_game",params,function(data)
		if data and data.gid then
			gid = data.gid
		end
	end)
end

---游戏开始
function m.StartGame()
	if game_state > 1 then
		return;
	end
	game_state = 2
	--游戏难度
	local difficulty = GetTDDifficulty();
	--游戏模式
	local mode = GetTDGameMode()
	
	initGID(difficulty,mode)
	
	--倒计时30秒后开始战斗
	local count = config_td_time_prepare()
	EmitAnnouncerSound("announcer_announcer_count_battle_30")
	TimerUtil.createTimer(function()
		SendToAllClient("xxdld_topbar_next_timer",{count = count,wave = 1})
		if count == 0 then
			game_state = 3
			Spawner.Start(mode);
		else
			if count == 10 then
				EmitGlobalSound("GameStart.RadiantAncient")
			end
			count = count - 1;
			return 1
		end
	end)
	--初始化金币
	local gold = GetInitialGold(difficulty)
	for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
		m.InitPlayerGold(PlayerID,gold)
		m.UpdatePlayerState(PlayerID,4)
		m.GiveStartReward(PlayerID)
--		m.GiveHolidayReward(PlayerID)
	end
	SendToAllClient("xxdld_game_state",{difficulty=difficulty,mode = mode,state=game_state})
end


---更新玩家状态到客户端
--@param #number PlayerID 玩家
--@param #number state <br>
-- 0：初始化<br>
-- 1：已准备（准备界面点了下一步：不可修改策略，不可修改建造者和建造者技能,可以进行卡片的升级操作）<br>
-- 2：等待中<br>
-- 3：难度选择中<br>
-- 4：游戏开始
function m.UpdatePlayerState(PlayerID,state)
	PlayerUtil.setAttrByPlayer(PlayerID,key_state,state)
	SendToClient(PlayerID,"xxdld_setup_update_player_state",{state=state})
end

---初始化金币
function m.InitPlayerGold(PlayerID,gold)
	PlayerUtil.SetGold(PlayerID,gold)
	
	--每秒奖励1金币
	local timer = PlayerUtil.getAttrByPlayer(PlayerID,"setup_gold_bonus_timer")
	if not timer then
		TimerUtil.createTimer(function()
			if PlayerUtil.IsPlayerLeaveGame(PlayerID) then
				return
			end
			PlayerUtil.AddGold(PlayerID,1)
			return 1
		end)
		PlayerUtil.setAttrByPlayer(PlayerID,"setup_gold_bonus_timer",true)
	end
end

---给予玩家开局奖励：plus给抽卡；vip等级给装备箱子
function m.GiveStartReward(PlayerID)
	--特权卡
	if Store.HasPrivilegeCard(PlayerID) then
		--延迟点奖励，避免游戏开局，英雄单位还没有替换完毕，添加完物品后才替换了单位，导致物品丢失
		TimerUtil.createTimerWithDelay(5,function()
			local hero = PlayerUtil.GetHero(PlayerID)
			if hero then
				ItemUtil.AddItem(hero,"item_plus_start_reward_draw",true)
			end
		end)
	end
	
	--vip等级奖励
	local vipLevel = Store.GetVipLevel(PlayerID)
	if vipLevel and vipLevel > 0 then
		local items = vipReward[vipLevel]
		if items then
			--延迟点奖励，避免游戏开局，英雄单位还没有替换完毕，添加完物品后才替换了单位，导致物品丢失
			TimerUtil.createTimerWithDelay(7,function()
				local hero = PlayerUtil.GetHero(PlayerID)
				if hero then
					for itemName, count in pairs(items) do
						for var=1, count do
							ItemUtil.AddItem(hero,itemName,true)
						end
						NotifyUtil.ShowSysMsg(PlayerID,{"info_vip_level_reward_item","DOTA_Tooltip_ability_"..itemName," x"..tostring(count)},15);
					end
				end
			end)
		end
	end
end

--function m.GiveHolidayReward(PlayerID)
--	TimerUtil.createTimerWithDelay(5,function()
--		local hero = PlayerUtil.GetHero(PlayerID)
--		if hero then
--			local randoms = {1,2,3}
--			local count = RandomInt(1,3)
--			for var=1, count do
--				ItemUtil.AddItem(hero,"item_box_jj_equipment_2",true)
--			end
--			NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_item_festival","DOTA_Tooltip_ability_item_box_jj_equipment_2","x"..tostring(count)},3)
--			
--			count = RandomInt(1,3)
--			for var=1, count do
--				ItemUtil.AddItem(hero,"item_box_base_equipment_2",true)
--			end
--			NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_item_festival","DOTA_Tooltip_ability_item_box_base_equipment_2","x"..tostring(count)},3)
--		end
--	end)
--end

---初始化玩家配置结果,除了PlayerID，其他都可以为空<p>
--如果该玩家已经配置过了，则不处理。
function m.InitPlayerConfig(PlayerID,strategies,selectIndex,modelName,abilities)
	local inited = PlayerUtil.getAttrByPlayer(PlayerID,key_player_setup_data_saved)
	if inited then
		return;
	end
	--如果下面代码逻辑执行出错了，怎么办？？
	PlayerUtil.setAttrByPlayer(PlayerID,key_player_setup_data_saved,true)

	--初始化选择的世界分组
	m.InitPlayerSelectWorld(PlayerID,strategies,selectIndex)
	
	--初始化英雄位置
	m.InitPlayerPosition(PlayerID)
	
	--游戏开始了才替换英雄这些，主要是替换英雄以后有一个出生语音。如果直接替换，会导致还没进游戏就有声音了，很诡异
	TimerUtil.createTimer(function()
		if game_state < 2 then
			return 1
		end
		
		
		TimerUtil.createTimer(function()
			--替换英雄，在线的才替换，不在线，先不管，等连入再说
			if PlayerUtil.IsPlayerConnected(PlayerID) then
				local hero = PlayerUtil.GetHero(PlayerID);
				--有英雄，且不是小精灵，可能已经替换过了，这里不处理了
				if not hero or hero:GetUnitName() == "npc_dota_hero_wisp" then
					hero = m.InitPlayerBuilder(PlayerID,modelName)
					--添加额外的建造者技能
					if hero then
						if type(abilities) == "table" then
							--AddAbility添加技能的时候先添加的反而会在后面，所以这里为了保持和界面选择的顺序一致，将key进行一下排序再处理
							local keys = {}
							for index, abilityName in pairs(abilities) do
								--使用字符串排序会出现问题，这里转成数字，在下面使用的时候再转换成字符串
								table.insert(keys,tonumber(index))
							end
							table.sort(keys)
							for _, index in pairs(keys) do
								local abilityName = abilities[tostring(index)]
								if abilityName then
									local ability = hero:AddAbility(abilityName)
									if ability then
										ability:SetLevel(1)
									end
								end
							end
						end
					end
				end
			elseif PlayerUtil.IsPlayerLeaveGame(PlayerID) then
				return nil;
			else
				--每隔0.5秒检查一下玩家是否在线，在线了就替换英雄，不在线了继续检查。
				--直到玩家在线或者离开游戏。避免游戏没开始就掉线了，再连进来的时候虽然替换了英雄，但是原有的英雄尸体还存在
				return 0.5
			end
		end)
	end)
end

---初始化玩家的建造者
function m.InitPlayerBuilder(PlayerID,modelName)
	if not modelName or modelName == "" then
		modelName = "gongxueyan"
	end
	local builder = builders[modelName]
	if builder and builder.hero then
		local heroName = builder.hero
		local hero = PlayerResource:ReplaceHeroWith(PlayerID, heroName, 0, 0)
		if hero then
			PlayerUtil.SetHero(PlayerID,hero)
			--设置技能等级
			for index=0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(index)
				if ability then
					ability:SetLevel(1)
				end
			end
		end
		return hero
	end
end

---初始化玩家本局选择的世界信息，如果select为空，则从玩家拥有的世界中随机
function m.InitPlayerSelectWorld(PlayerID,strategies,selectIndex)
	--客户端传过来的是一个数字，但是在strategies中的索引却被转换成了字符串，这里处理一下
	if selectIndex then
		selectIndex = tostring(selectIndex)
	end
	local select = {}
	if strategies and selectIndex and strategies[selectIndex] then
		select = strategies[selectIndex]
	end
	local selectCount = tableLen(select);
	if selectCount >= config_td_min_selection() then
		select = strategies[selectIndex]
	else --如果没有选择，或者选择的数量不足的话，随机够至少5个世界
		--所有可随机的世界
		local worlds = {}
		local ownCards = PlayerUtil.GetCards(PlayerID)
		if ownCards then
			for worldName, cards in pairs(ownCards) do
				local canRandom = true;
				if selectCount > 0 then
					for _, selectWorld in pairs(select) do
						if worldName == selectWorld then
							canRandom = false
							break;
						end
					end
				end
				if canRandom then
					table.insert(worlds,worldName)
				end
			end
		end
		if #worlds > 0 then
			local count = config_td_min_selection() - selectCount
			--随机，如果已经有了，就只随机缺的
			for var=1, count do
				local index = RandomInt(1,#worlds)
				local worldName = table.remove(worlds,index)
				if worldName and worldName ~= "" then
					table.insert(select,worldName)
				end
			end
			--向客户端发送结果
			--没有选择的话，默认选择第一组
			if not selectIndex then
				selectIndex = "1"
			end
			SendToClient(PlayerID,"setup_update_random_select_worlds",{world=select,index=selectIndex})
		end
	end
	
	PlayerUtil.setAttrByPlayer(PlayerID,key_selected_world,select)
	PlayerUtil.setAttrByPlayer(PlayerID,key_selected_world_index,selectIndex)
end

---将英雄单位移动到各自的初始位置，并设置玩家游戏状态为游戏开始
function m.InitPlayerPosition(PlayerID)
	local hero = PlayerUtil.GetHero(PlayerID)
	if hero then
		local spawnEntity = EntityHelper.findEntityByName("hero_spawn_pos_"..tostring(PlayerID))
		if spawnEntity then
			Teleport(hero,spawnEntity:GetAbsOrigin())
			--镜头跟随英雄
			PlayerResource:SetCameraTarget(PlayerID,hero)
			--需要释放镜头，否则会一直绑定在英雄身上;短暂延迟后再释放镜头，否则可能镜头移动到一半就丢失了
			TimerUtil.createTimerWithDelay(0.5,function()
				PlayerResource:SetCameraTarget(PlayerID,nil)
			end);
		end
	end
end


---保存玩家的世界配置策略
function m.SaveAllWorld(PlayerID,allWorld)
	if PlayerID and allWorld then
		--处理一下：index=a,b,c,d...
		local data = {}
		for index, worlds in pairs(allWorld) do
			local names = nil
			for _, worldName in pairs(worlds) do
				if worldName and worldName ~= "" then
					if names then
						names = names..","..worldName
					else
						names = worldName
					end
				end
			end
			--对应索引没有数据的话，清空
			data[index] = names or ""
		end
		local aid = PlayerUtil.GetAccountID(PlayerID);
		local json = JSON.encode(data)
		http.load("world",{aid=aid,data=json},function(svData)
			if svData and svData.success == "1" then
				for index, worlds in pairs(data) do
					PlayerUtil.UpdateWorldStrategy(PlayerID,index,worlds)
				end
			end
		end)
	end
end

---获取玩家在配置阶段选择的世界
function m.GetSelectWorlds(PlayerID)
	return PlayerUtil.getAttrByPlayer(PlayerID,key_selected_world)
end

function m.GetGID()
	return gid
end

---某个玩家重连游戏后，如果还没有开始，显示对应界面
function m.PlayerReconnected(PlayerID)
	if game_state == 0 then
		m.ShowSetup(PlayerID,true)
	elseif game_state == 1 then
		ShowDifficultyVoteUI(PlayerID)
	elseif game_state > 1 then
		--更新已选世界
		local worlds = PlayerUtil.getAttrByPlayer(PlayerID,key_selected_world)
		if PlayerUtil.getAttrByPlayer(PlayerID,key_selected_world) then
			local selectIndex = PlayerUtil.getAttrByPlayer(PlayerID,key_selected_world_index);
			SendToClient(PlayerID,"setup_update_random_select_worlds",{world=worlds,index=selectIndex})
		end
	end
end

---游戏是否开始。进入准备阶段就算开始了
function m.IsGameStarted()
	return game_state > 1
end


-----------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------下面是客户端请求过来的处理逻辑-----------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------

---客户端初始化，请求玩家数据。
--客户端会请求，在服务器端加载完数据后也会主动推送一次。
function m.Client_Init(_,keys)
	if keys then
		local PlayerID = keys.PlayerID
		if not PlayerUtil.IsValidPlayer(PlayerID) then
			return;
		end
		
		if not PlayerUtil.IsPlayerDataLoaded() then
			SendToClient(PlayerID,"xxdld_setup_init",{loading=true})
		else
			local data = {}
			data.card = PlayerUtil.GetCards(PlayerID);
			data.exp = PlayerUtil.GetCardExp(PlayerID);
			data.strategy = PlayerUtil.GetWorldStrategy(PlayerID);
			data.ability = PlayerUtil.GetBuilderAbility(PlayerID);
			data.builder = PlayerUtil.GetBuilderModel(PlayerID);
			
			SendToClient(PlayerID,"xxdld_setup_init",data)
		end
	else--没有key，是初始化调用，发送所有玩家数据
		for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
			local data = {}
			data.card = PlayerUtil.GetCards(PlayerID);
			data.exp = PlayerUtil.GetCardExp(PlayerID);
			data.strategy = PlayerUtil.GetWorldStrategy(PlayerID);
			data.ability = PlayerUtil.GetBuilderAbility(PlayerID);
			data.builder = PlayerUtil.GetBuilderModel(PlayerID);
			
			SendToClient(PlayerID,"xxdld_setup_init",data)
		end
	end
end

---点击下一步进入准备状态。
--如果有多个玩家，则显示等待界面；否则开始游戏
function m.Client_EnterGame(_,keys)
	if game_state > 0 then
		return;
	end
	local PlayerID = keys.PlayerID
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	
	--存储所有世界策略信息
	TimerUtil.createTimer(function()
		m.SaveAllWorld(PlayerID,keys.all)
	end)
	
	m.InitPlayerConfig(PlayerID,keys.all,keys.using,keys.model,keys.ability)
	
	m.UpdatePlayerState(PlayerID,1)
	
	m.ShowWaitOrStart(PlayerID)
end

---更新所有玩家的难度选择结果到客户端。
function m.UpdateDifficultySelectResult()
	local allPlayers = PlayerUtil.GetAllPlayersID(false);
	--已经选择过难度的玩家数量
	local votedCount = 0;
	local data = {}
	for _, PlayerID in pairs(allPlayers) do
		local result = PlayerUtil.getAttrByPlayer(PlayerID,key_diff)
		--如果没有选择，这里就不向客户端发送默认值了。避免引起误会
		if result then
			votedCount = votedCount + 1;
			local players = data[result]
			if not players then
				players = {}
				data[result] = players
			end
			
			table.insert(players,PlayerUtil.GetSteamID(PlayerID))
		end
	end
	
	SendToAllClient("xxdld_setup_difficulty_update",data)
	---所有玩家都已经选择了难度了，直接开始游戏，不管难度选择的倒计时了
	if votedCount == #allPlayers then
		m.ConfirmDifficulty()
	end
end
---刷新配置界面的数据，主要用于某些操作改变了卡片或者建造者技能的拥有情况时，刷新配置界面。
--@param #number PlayerID 玩家id
--@param #table card 新增的卡片信息{worldName={cardName={exp=123}}}
--@param #table ability 所有建造者技能信息（使用PlayerUtil接口去获取即可）
function m.RefreshSetupData(PlayerID,card,ability)
	if PlayerID and (card or ability) then
		local data = {}
		if card then
			data.card = card
		end
		if ability then
			data.ability = ability
		end
		SendToClient(PlayerID,"xxdld_setup_refresh_data",data)
	end
end

---客户端进行难度选择
function m.Client_SelectDifficulty(_,keys)
	local PlayerID,result = keys.PlayerID,keys.result
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	
	if result then
		PlayerUtil.setAttrByPlayer(PlayerID,key_diff,result)
	end
	--更新结果到所有客户端
	m.UpdateDifficultySelectResult()
end

function m.Client_UpdatePlayerState(_,keys)
	if PlayerUtil.IsValidPlayer(keys.PlayerID) then
		SendToClient(keys.PlayerID,"xxdld_setup_update_player_state",{state=PlayerUtil.getAttrByPlayer(keys.PlayerID,key_state)})
	end
end

function m.Client_GetGameStartState(_,keys)
	if gameStarted then
		if PlayerUtil.IsValidPlayer(keys.PlayerID) then
			SendToClient(keys.PlayerID,"xxdld_game_state",{difficulty=GetTDDifficulty(),mode = GetTDGameMode(),state=game_state})
		else
			SendToAllClient("xxdld_game_state",{difficulty=GetTDDifficulty(),mode = GetTDGameMode(),state=game_state})
		end
	end
end

---初始化，缓存所有世界和卡片单位信息
local init = function()
	RegisterEventListener("xxdld_setup_init_request",m.Client_Init)
	RegisterEventListener("xxdld_setup_enter_game",m.Client_EnterGame)
	RegisterEventListener("xxdld_setup_difficulty_select",m.Client_SelectDifficulty)
	RegisterEventListener("xxdld_setup_update_player_state_request",m.Client_UpdatePlayerState)
	RegisterEventListener("xxdld_game_state_request",m.Client_GetGameStartState)
	
	PlayerUtil.RegisterLoadedListener(function()
		m.Client_Init(nil,nil)
		
		RankList.start()
	end)
end

init()
return m