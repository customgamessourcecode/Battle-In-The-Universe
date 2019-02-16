local m = {}

local currentWave = 1
--每两波之间的刷新间隔
local waveInterval = 10

---每个玩家的敌方单位信息。将存活数量和死亡数量分开统计，避免冲突。同时记录所有存活的单位便于在玩家失败或者离开游戏的时候删除这些单位
--key是玩家id，value= {
--	spawned = 123，已刷新怪物对应的总数（boss占5个，普通单位占1个）
--	died = 123，已经死亡的数量（boss占5个，普通单位占1个）
--	units = {unit1,unit2,unit3} --当前存活的怪物实体，用来做删除
--}
local UnitData = {}

---为某个玩家添加一个存活单位，返回添加后的漏怪数量（boss占5个，普通单位占1个）
local AddPlayerUnit = function(PlayerID,unit,count)
	local data = UnitData[PlayerID]
	if not data then
		data = {
			spawned = 0,
			died = 0,
			units = {}
		}
		UnitData[PlayerID] = data
	end
	data.spawned = data.spawned + count
	table.insert(data.units,unit)
	
	return data.spawned - data.died
end
---单位死亡的时候，从存活单位中移除，返回移除后的漏怪数量
local RemovePlayerUnit = function(PlayerID,unit,count)
	local data = UnitData[PlayerID]
	if data then
		data.died = data.died + count
		for index, exist in pairs(data.units) do
			if unit == exist then
				table.remove(data.units,index)
				break;
			end
		end
		return data.spawned - data.died
	end
	return 0
end

---玩家失败或者离开游戏后，移除玩家的所有敌人
local ClearEnemy = function(PlayerID)
	--移除该玩家的所有敌方单位，仍然保留刷怪数量和死亡数量
	local data = UnitData[PlayerID]
	if data and data.units then
		ClearUnitArray(data.units,false)
	end
end

---是否需要给某玩家刷怪：玩家已经离开游戏或者已经失败了就不刷新了
local NeedSpawn = function(PlayerID)
	if IsInPostGameState() then
		return false;
	end

	--离开游戏了不刷新
	if PlayerUtil.IsPlayerLeaveGame(PlayerID) then
		if not PlayerUtil.getAttrByPlayer(PlayerID,Spawner.key_leaved_early) then
			PlayerUtil.setAttrByPlayer(PlayerID,Spawner.key_leaved_early,true)
			--无尽离开游戏的时候，记录失败波次为当前波次减1
			m.MakePlayerLose(PlayerID,currentWave - 1)
		end
		if Spawner.ClearPlayerData(PlayerID) then
			--如果玩家已经离开游戏了清空所有数据
			ClearEnemy(PlayerID)
			return false;
		end
	end
	--已经失败了不刷新
	if Spawner.IsPlayerFaild(PlayerID) then
		return false;
	end
	
	return true
end

---怪物刷新后初始化：累计怪物数量；增加随机元素以及强化怪物等
local initUnit = function(PlayerID,unit,startNode)
	if unit then
		local current = AddPlayerUnit(PlayerID,unit,1)
		SendToClient(PlayerID,"xxdld_topbar_live_count",{current=current,max=config_td_max_enemy_count_single()})
		
		--根据怪物数量判断游戏是否结束
		if m.IsGameOver(PlayerID,current,unit._spawner_wave) then
			return;
		end
		---怪物死亡的时候，减少堆积数量
		DealWithUnitDeath(unit,function(attacker)
			--最后一波会强制杀死怪物，此时attacker就是单位自己，这里排除掉
			if attacker == unit then
				return;
			end
		
			local current = RemovePlayerUnit(PlayerID,unit,1)
			SendToClient(PlayerID,"xxdld_topbar_live_count",{current=current,max=config_td_max_enemy_count_single()})
			--统计玩家杀怪数量
			PlayerResource:IncrementKills(PlayerUtil.GetOwnerID(attacker),1)
		end)
		
		Spawner.Strengthen(unit)
		Elements.randomArmor(unit)
		
		unit:AddNewModifier(nil, nil, "td_modifier_creature", nil)
		unit.pathNode = startNode
		Path.moveNext(unit,true)
	end
end

---根据难度和波次增加减伤以及护甲
local GetInfiniteStrenth = function(wave)
	local ratio = 1
	local difficulty = GetTDDifficulty()
	if difficulty == 2 then ratio = 1.5
	elseif difficulty == 3 then ratio = 2
	elseif difficulty == 4 then ratio = 3
	elseif difficulty == 5 then ratio = 5
	elseif difficulty == 6 then ratio = 7
	end
	
	local waveRatio = 1
	if wave <= 10 then waveRatio = 1
	elseif wave <= 20 then waveRatio = 2
	else waveRatio = 3 end
	
	--减伤公式是1-1 / (1 + 0.075 * currentWave * ratio * waveRatio)，是实际受到伤害就是后半截，这里只记录后半截，在过滤器里面相乘就行了
	local realDamageRatio = 1 / (1 + 0.075 * wave * ratio * waveRatio)
	--排除掉难度系数的因子，用在某些基于血量百分比
	local realDamageRatio2 = 1 / (1 + 0.075 * wave * waveRatio)
	local addArmor = 60 * wave
	
	return realDamageRatio,addArmor,realDamageRatio2
end

---根据难度和波次增加血量以及护甲
local GetInfiniteStrenth2 = function(wave)
	local waveRatio = 1
	if wave <= 10 then waveRatio = 1
	elseif wave <= 20 then waveRatio = 2
	else waveRatio = 3
	end
	
	local hpRatio = 1
	local armorRatio = 1
	local difficulty = GetTDDifficulty()
	if difficulty == 2 then hpRatio = 1.5 armorRatio = 1
	elseif difficulty == 3 then hpRatio = 2 armorRatio = 1
	elseif difficulty == 4 then hpRatio = 3 armorRatio = 1
	elseif difficulty == 5 then hpRatio = 5 armorRatio = 1
	end
	
	local addHealth = 15000 * hpRatio * wave * waveRatio
	local addArmor = 15 * armorRatio * wave * waveRatio
	return addHealth,addArmor
end

---无限波刷怪：无波次奖励，怪物也会越来越强
--返回还需要多久刷新下一波
local WaveSpawn = function(locs)
	if IsInPostGameState() then
		return;
	end
	
	Spawner.WaveChange(currentWave)
	
	--清空伤害统计
	Towermgr.ClearTowerDamageRecord()
	--当前波次，不用全局变量，避免被其他逻辑改变了
	local wave = currentWave
	
--	local addHealth,addArmor = GetInfiniteStrenth2(wave)
	local damageRatio,addArmor,damageRatio2 = GetInfiniteStrenth(wave)
	
	
	local count = 40
	local interval = 0.5
	local unitName = "monster_infinite"
	
	---精英怪刷新索引，key是玩家id，value是一个数组，数组元素代表精英怪出现的第几个怪。
	--分开玩家存储，这样每个人出精英怪的位置都不一样，并且不会相互影响（之前只有一组索引的时候，移除数组元素的话会影响其他玩家的刷怪）。
	--在给玩家刷第一个怪的时候初始化
	local specialIndex = {}
	
	--怪物刷新
	TimerUtil.createTimer(function()
		if IsInPostGameState() then
			return;
		end
		
		if count > 0 then
			for _, loc in pairs(locs) do
				local PlayerID = loc.pid
				--如果玩家已经离开游戏了就不刷新了
				if NeedSpawn(PlayerID) then
					local spawnPos = loc.pos
					local startNode = loc.node
					
					---精英怪索引
					local special = specialIndex[PlayerID]
					if not special then
						special = Spawner.GetSpecialIndex()
						specialIndex[PlayerID] = special
					end
					
					if count == 0 then
						--发送提示
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
					
					--无限波次强化

--					local hp = unit:GetMaxHealth() + addHealth
--					unit:SetMaxHealth(hp)
--					unit:SetBaseMaxHealth(hp)
--					unit:SetHealth(hp)
					unit._infinite_real_damage_ratio = damageRatio
					unit._infinite_real_damage_ratio2 = damageRatio2
					CustomArmor.SetBaseArmor(unit,CustomArmor.GetBaseArmor(unit) + addArmor)
					
					--累计数量，难度强化
					initUnit(PlayerID,unit,startNode)
				end
			end
			
			count = count - 1
			return interval
		end
	end)
	
	local duration = count * interval
	return math.ceil(duration + waveInterval)
end

---开始刷怪
function m.start()
	NotifyUtil.Top(nil,"#info_infinite_mode_start",3,"yellow")
	
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
	
	if TD_GMAE_MODE_TEST then
		locs = {}
		for var=0, 3 do
			local spawner = EntityHelper.findEntityByName("spawner"..tostring(var))
			if spawner then
				local spawnPos = spawner:GetAbsOrigin()
				local startNode = spawner:GetName()
				table.insert(locs,{pid=0 ,pos=spawnPos,node=startNode})
			end
		end
	end
	
	m.SpawnForPlayers(locs)
end


---在所有玩家刷怪
function m.SpawnForPlayers(locs)
	if IsInPostGameState() then
		return;
	end
	
	---要向客户端发送的波次。和服务器存储的可能不一致。服务器基本波和无限波用一个变量。客户端无限波重新从1开始计算
	local wave = tostring(currentWave)
	local nextDelay = WaveSpawn(locs)
	currentWave = currentWave + 1
	
	if wave == 31 then
		bgm.infinite(2)
	end
	
	if nextDelay then
		--客户端计时
		TimerUtil.createTimer(function()
			if IsInPostGameState() then
				return;
			end
			SendToAllClient("xxdld_topbar_next_timer",{count = nextDelay,wave = wave,infinite=true})
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

---使某个玩家失败：发提示信息，清空数据，记录失败波次
function m.MakePlayerLose(PlayerID,wave)
	NotifyUtil.Top(PlayerID,"#info_game_over",5,"red")
	--失败处理的时候仍然在线，才记录失败波次，如果在失败之前就退出了，则不记录
	local online = not PlayerUtil.IsPlayerLeaveGame(PlayerID)
	if online and not Spawner.IsPlayerFaild(PlayerID) and Spawner.PlayerFaild(PlayerID) then
		---延迟一下清空单位
		TimerUtil.createTimerWithDelay(5,function()
			ClearEnemy(PlayerID)
		end)
		PlayerUtil.setAttrByPlayer(PlayerID,Spawner.key_finish_infinite,wave)
		
		--立刻记录奖励信息
		Spawner.PlayerFinished(PlayerID)
	end
end

---检查是否游戏结束，结束了给提示信息
function m.IsGameOver(PlayerID,current,wave)
	if current <= config_td_max_enemy_count_single() then
		return false;
	end
	
	if TD_GMAE_MODE_TEST then
		return false;
	end
	
	--当前玩家失败了，清空玩家数据，实际这一波没有撑过去，所以坚持的波次减少1
	m.MakePlayerLose(PlayerID,wave - 1)
	
	--判断游戏是否结束，所有玩家都失败了就结束了
	local finished = true
	for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
		if not Spawner.IsPlayerFaild(PlayerID) 
		and not PlayerUtil.IsPlayerLeaveGame(PlayerID) then
			--该玩家没有失败，并且没有离开游戏，则游戏不结束
			finished = false
			break;
		end
	end
	
	if finished then
		Spawner.GameFinished()
	end
	
	return true;
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