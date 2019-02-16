local m = {}
local waves = LoadKeyValues("scripts/kv/WaveEnemy.kv")

---当前波次（开始刷新后，比实际波次大1）
local currentWave = 1
---每两波之间的刷新间隔
local waveInterval = 30

---当前已经刷新的怪物数量。boss算5点，普通怪算1点
local monsterCount = 0
---已死亡的怪物数量，增加和减少分开存储，避免冲突
local diedMonsterCount = 0

---普通波次最终boss。最终boss刷新后，两分钟倒计时，如果2分钟后，有boss没有死亡，则游戏失败；否则通关，可以进入无尽模式
local finalBoss = {}

---怪物刷新后初始化：累计怪物数量；增加随机元素以及强化怪物等
local initUnit = function(unit,startNode)
	if unit then
		---怪物堆积数量。boss算5个，普通怪算1个
		if unit.TD_IsBoss then
			monsterCount = monsterCount + 5
		else
			monsterCount = monsterCount + 1
		end
		
		--根据怪物数量判断游戏是否结束
		if m.IsGameOver() then
			return;
		end
		
		---怪物死亡的时候，减少堆积数量
		DealWithUnitDeath(unit,function(attacker)
			--最后一波会强制杀死怪物，此时attacker就是单位自己，这里排除掉
			if attacker == unit then
				return;
			end
		
			if unit.TD_IsBoss then
				diedMonsterCount = diedMonsterCount + 5
			else
				diedMonsterCount = diedMonsterCount + 1
			end
			--统计数量
			PlayerResource:IncrementKills(PlayerUtil.GetOwnerID(attacker),1)
			
			SendToAllClient("xxdld_topbar_live_count",{current=monsterCount - diedMonsterCount,max=config_td_max_enemy_count_team()})
			
			--掉落物品
			Spawner.DropItem(unit,unit._spawner_wave,attacker)
		end)
		
		Spawner.Strengthen(unit)
		Elements.randomArmor(unit)
		
		unit:AddNewModifier(nil, nil, "td_modifier_creature", nil)
		unit.pathNode = startNode
		Path.moveNext(unit,true)
	end
end

---是否需要给某玩家刷怪：玩家已经离开游戏就不刷新了
local NeedSpawn = function(PlayerID)
	if IsInPostGameState() then
		return false;
	end

	--离开游戏了不刷新
	if PlayerUtil.IsPlayerLeaveGame(PlayerID) then
		PlayerUtil.setAttrByPlayer(PlayerID,Spawner.key_leaved_early,true)
		if Spawner.ClearPlayerData(PlayerID) then
			return false;
		end
	end
	return true
end

---刷新一波怪物
local baseWaveSpawn = function(units,locs)
	if IsInPostGameState() then
		return;
	end
	
	Spawner.WaveChange(currentWave)
	
	--发放上一波补偿金
	if currentWave > 1 then
		local gold = 100 * (currentWave - 1)
		m.GiveWaveCompensation(gold)
	end
	--清空伤害统计
	Towermgr.ClearTowerDamageRecord()
	
	--当前波次，不用全局变量，避免被其他逻辑改变了
	local wave = currentWave
	--本波单位
	local unitName = units.unit
	--本波boss
	local bossName = nil
	local bossCount = 0;
	if units.boss then
		bossName = units.boss
		bossCount = Spawner.GetBossCount()
	end
	if not unitName and not bossName then
		DebugPrint(wave,"wave enemy KV error:no unit or boss")
		return;
	end
	---精英怪刷新索引，key是玩家id，value是一个数组，数组元素代表精英怪出现的第几个怪。
	--分开玩家存储，这样每个人出精英怪的位置都不一样，并且不会相互影响
	--在给玩家刷第一个怪的时候初始化
	local specialIndex = {}
	
	--已刷新数量
	local count = 0
	--最大数量
	local max = units.count
	--怪物刷新
	TimerUtil.createTimer(function()
		if m.SpawnNormalUnit(wave,locs,count,max,unitName,bossName,bossCount,specialIndex) then
			count = count + 1
			return units.interval
		end
	end)
	
	---最后一波就不发送下一波的间隔了，在刷完怪以后才会有2分钟倒计时，
	--计时结束了判定boss是否击杀来确定是否能进入下一波，即无限模式
	if wave < config_td_base_wave_count() then
		local duration = units.count * units.interval
		return math.ceil(duration + waveInterval)
	end
end

---在各个玩家的刷怪点刷新一个怪物，返回是否需要继续刷新
function m.SpawnNormalUnit(wave,locs,count,max,unitName,bossName,bossCount,specialIndex)
	if IsInPostGameState() then
		return false;
	end
	
	if count < max then
		--本波是否刷新了boss，如果刷新了boss则给提示
		local spawnedBoss = false
		for _, loc in pairs(locs) do
			local PlayerID = loc.pid
			--如果玩家已经离开游戏了就不刷新了
			if NeedSpawn(PlayerID) then
				local spawnPos = loc.pos
				local startNode = loc.node
				
				---初始化精英怪出现的位置
				local special = specialIndex[PlayerID]
				if not special then
					special = Spawner.GetSpecialIndex()
					specialIndex[PlayerID] = special
				end
				
				--开始刷新，发送提示
				if count == 0 then
					EntityHelper.ShowOnMiniMap(spawnPos)
				end
				
				--刷怪
				local unit = CreateUnitEX(unitName,spawnPos,true)
				unit._spawner_wave = wave
				--判断是否是精英怪，如果是，进行强化
				if count >= 10 and count == special[1] then
					table.remove(special,1)
					Spawner.initSpecialUnit(unit)
				end
				--最后累计数量，添加死亡监听等
				initUnit(unit,startNode)
				
				--有boss，则在第十一只怪的时候刷boss
				if bossName and count == 10 then
					for var=1, bossCount do
						local boss = CreateUnitEX(bossName,spawnPos,true)
						boss.TD_IsBoss = true
						boss._spawner_wave = wave
						initUnit(boss,startNode)
						
						--最后一波boss的话，存起来。2分钟后如果没有死完，则游戏失败。如果死亡了开启无限模式
						if wave == config_td_base_wave_count() then
							table.insert(finalBoss,boss)
						end
					end
					spawnedBoss = true
				end
			end
		end
		--全都刷完了，同步一次数量
		SendToAllClient("xxdld_topbar_live_count",{current=monsterCount - diedMonsterCount,max=config_td_max_enemy_count_team()})
		
		if spawnedBoss then
			NotifyUtil.Top(nil,"#info_boss_coming",3,"#FF4500")
		end
		
		return true;
	else--刷怪结束。判断下一波有没有boss，有的话提前发送提示信息
		local nextUnits = waves[tostring(wave + 1)]
		if nextUnits and nextUnits.boss then
			NotifyUtil.Top(nil,"#info_boss_coming_in_next",10,"yellow")
			NotifyUtil.ShowSysMsg(nil,"#info_boss_coming_in_next",10)
		end
		--最后一波boss
		if wave == config_td_base_wave_count() then
			m.SpawnFinalBoss()
		end
	end
end

function m.SpawnFinalBoss()
	--最后一波
	local wave = config_td_base_wave_count();
	--开始倒计时
	local delay = config_td_delay_before_infinite()
	
	NotifyUtil.Top(nil,"#info_final_boss_tip",10,"yellow",true)
	
	NotifyUtil.ShowSysMsg(nil,"#info_final_boss_tip",10)
	
	TimerUtil.createTimer(function()
		SendToAllClient("xxdld_topbar_next_timer",{count = delay,wave = wave})
		if delay == 0 then
			for _, boss in pairs(finalBoss) do
				--有boss存活，游戏结束，标记所有在线玩家的结束波次为上一波
				if EntityIsAlive(boss) then
					m.SetPlayersFinalWave(wave - 1)
					Spawner.TeamFinished()
					Spawner.GameFinished()
					return;
				end
			end
			--所有boss都已经死亡了。则开启无尽模式
			finalBoss = nil
			
			--记录所有在线玩家的存活波数为最大波数
			m.SetPlayersFinalWave(wave)
			Spawner.EnterInfinite()
		else
			delay = delay - 1;
			return 1
		end
	end)
end

function m.start()
	NotifyUtil.Top(nil,"#info_game_start",3,"yellow")
	
	currentWave = 1
	--所有刷怪点
	local locs = {}
	local players = PlayerUtil.GetAllPlayersID();
	for _, PlayerID in pairs(players) do
		local hero = PlayerUtil.GetHero(PlayerID)
		if hero or true then--有英雄的才刷怪
			local spawner = EntityHelper.findEntityByName("spawner"..tostring(PlayerID))
			if spawner then
				local spawnPos = spawner:GetAbsOrigin()
				local startNode = spawner:GetName()
				table.insert(locs,{pid=PlayerID ,pos=spawnPos,node=startNode})
			end
		end
	end
	
	m.SpawnForPlayers(locs)
end

---给所有玩家刷怪
function m.SpawnForPlayers(locs)
	if IsInPostGameState() then
		return;
	end
	
	---要向客户端发送的波次。
	local wave = tostring(currentWave)
	local nextDelay = nil
	--团队模式只到基础波次结束，进入无限模式后，切换为单人模式
	if currentWave <= config_td_base_wave_count() then
		local unit = waves[wave]
		if unit then
			--波次刷新
			nextDelay = baseWaveSpawn(unit,locs)
			currentWave = currentWave + 1
		else
			DebugPrint(wave,"wave config error:no enemy")
		end
	end
	
	if nextDelay then
		--客户端计时
		TimerUtil.createTimer(function()
			if IsInPostGameState() then
				return;
			end
			SendToAllClient("xxdld_topbar_next_timer",{count = nextDelay,wave = wave})
			if nextDelay <= 0 then
				--刷新下一波
				m.SpawnForPlayers(locs)
			else
				nextDelay = nextDelay - 1;
				return 1
			end
		end)
	end
end

local GameOverTimer
---检查是否游戏结束，结束了给提示信息
function m.IsGameOver()
	if monsterCount - diedMonsterCount > config_td_max_enemy_count_team() and not GameOverTimer then
		local count = config_td_faild_delay()
		GameOverTimer = TimerUtil.createTimer(function()
			if monsterCount - diedMonsterCount > config_td_max_enemy_count_team() then
				if count == 0 then
					--获取在线玩家，记录失败波次
					m.SetPlayersFinalWave(m.GetCurrentWave())
					
					Spawner.TeamFinished()
					Spawner.GameFinished()
				else
					NotifyUtil.Top(nil,count,3,"#FF4500")
					NotifyUtil.Top(nil,"info_game_faild_delay",3,"#FF4500",true)
					count = count - 1
					return 1;
				end
			else
				GameOverTimer = nil
			end
		end)
	end
end

---设置所有在线玩家（没有提前离开游戏的，这样即便某些人一直在挂机，或者是断开连接但是没有离开游戏，一样会有奖励）的最终坚持波数
function m.SetPlayersFinalWave(wave)
	local Players = PlayerUtil.GetAllPlayersID()
	for _, PlayerID in pairs(Players) do
		if not PlayerUtil.getAttrByPlayer(PlayerID,Spawner.key_leaved_early) then
			PlayerUtil.setAttrByPlayer(PlayerID,Spawner.key_finish_base,wave)
		end
	end
end

---给所有玩家发放波次补偿金
function m.GiveWaveCompensation(gold)
	local players = PlayerUtil.GetAllPlayersID()
	--只有一个人的时候，就给默认金币
	if #players == 1 then
		local PlayerID = players[1]
		local hero = PlayerUtil.GetHero(PlayerID)
		local player = PlayerUtil.GetOwner(hero)
		PlayerUtil.AddGold(PlayerID,gold)
		ShowOverheadMsg(hero,OVERHEAD_ALERT_GOLD,gold,player)
	else
		--多人的时候进行排序，击杀最少的，给予双倍补贴
		--记录此刻的杀怪数量
		local kills = {}
		local min = 0
		for _, PlayerID in pairs(players) do
			--只记录没有离开游戏的，即掉线的也会发放金币
			if not PlayerUtil.IsPlayerLeaveGame(PlayerID) then
				kills[PlayerID] = PlayerResource:GetKills(PlayerID)
				if min == 0 or kills[PlayerID] < min then
					min = kills[PlayerID]
				end
			end
		end
		
		--排序，倒数第一得到双倍金币补偿
		local minPlayers = {}
		for PlayerID, count in pairs(kills) do
			if count == min then
				table.insert(minPlayers,PlayerID)
			else --其他玩家发放正常数额的金币
				local hero = PlayerUtil.GetHero(PlayerID)
				local player = PlayerUtil.GetOwner(hero)
				PlayerUtil.AddGold(PlayerID,gold)
				ShowOverheadMsg(hero,OVERHEAD_ALERT_GOLD,gold,player)
			end
		end
		--最少的玩家发放双倍，有多个的时候，随机一个。General.CoinsBig，这个音效比较大，后面看有需要的话，可以替换一下
		local minIndex = RandomInt(1,#minPlayers)
		for index, PlayerID in pairs(minPlayers) do
			local hero = PlayerUtil.GetHero(PlayerID)
			local player = PlayerUtil.GetOwner(hero)
			if index == minIndex then
				PlayerUtil.AddGold(PlayerID,gold * 2)
				ShowOverheadMsg(hero,OVERHEAD_ALERT_GOLD,gold * 2,player)
			else
				PlayerUtil.AddGold(PlayerID,gold)
				ShowOverheadMsg(hero,OVERHEAD_ALERT_GOLD,gold,player)
			end
		end
	end
	
	NotifyUtil.ShowSysMsg(nil,{"#info_wave_gold",":"..tostring(gold)},4)
end

---获取当前正在刷新的波次
--还没开始的时候，返回0
function m.GetCurrentWave()
	--波次在刷新怪的时候就已经累加了，所以这里要减去1才代表实际正在刷新的波次。
	return currentWave - 1
end

return m