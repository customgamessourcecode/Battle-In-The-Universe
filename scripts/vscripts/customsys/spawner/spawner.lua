--这个里面主要包括一些在不同模式下通用的函数
local m = {}
---游戏模式：1或空团队，2单人
local game_mode
---团队模式基础波次
local SpawnerTeam = require("customsys.spawner.spawner_team")
---单人模式基础波次
local SpawnerSingle = require("customsys.spawner.spawner_single")
---无尽模式
local SpawnerInfinite = require("customsys.spawner.spawner_infinite")
---当前是否是无尽模式
local IsInfinite = false

---玩家信息key：游戏中途玩家离开游戏，则没有奖励
m.key_leaved_early = "spawner_player_leaved"
---玩家信息key：游戏结束波次。value是结束的基础波次
m.key_finish_base = "spawner_player_finish_base";
---玩家信息key：游戏结束波次。value是结束的无限波次
m.key_finish_infinite = "spawner_player_finish_extra";
---玩家信息key：玩家数据是否已经清空。当玩家离开游戏或者游戏失败的时候，清空数据
local key_cleared = "spawner_single_player_cleard"
---玩家信息key，玩家是否失败（离开游戏不被判定为失败，在结束的时候没有奖励）
local key_faild = "spawner_player_faild"

---开始刷怪
--@param #number mode 游戏模式：1或空代表团队模式，2代表单人模式
function m.Start(mode)
	game_mode = mode
	
	if TD_GMAE_MODE_TEST then
		m.EnterInfinite()
		return;
	end
	
	if game_mode == 2 then
		SpawnerSingle.start();
	else
		SpawnerTeam.start();
	end
	
	bgm.live()
end

---根据游戏难度强化单位属性
function m.Strengthen(unit)
	if unit then
		local healthRatio = 1
		local armorRatio = 1
		
		local difficulty = GetTDDifficulty()
		if difficulty == 1 then
			healthRatio = 0.8
			armorRatio = 0.8
		elseif difficulty == 2 then
			healthRatio = 1.5
			armorRatio = 1.3
		elseif difficulty == 3 then
			healthRatio = 2
			armorRatio = 1.6
		elseif difficulty == 4 then
			healthRatio = 3
			armorRatio = 2
		elseif difficulty == 5 then
			healthRatio = 5
			armorRatio = 3
		elseif difficulty == 6 then
			healthRatio = 7.5
			armorRatio = 4.5
		end
		
		local hp = unit:GetMaxHealth() * healthRatio
		unit:SetMaxHealth(hp)
		unit:SetBaseMaxHealth(hp)
		unit:SetHealth(hp)
	
		local armor = CustomArmor.GetBaseArmor(unit)
		CustomArmor.SetBaseArmor(unit,armor * armorRatio)
	end
end

---获取当前难度可以刷新的boss数量<br>
--每个刷新点都要刷新这么多boss
function m.GetBossCount()
	local bossCount = 1
	local difficulty = GetTDDifficulty()
	if difficulty >= 3 then
		bossCount = 2
	end
	return bossCount
end

---获取精英怪出现的索引。<br>
--精英怪在每波怪的第11个至第20个怪之间随机产生。这个方法返回一个数组，数组的每个元素是要产生精英怪的索引。
--索引从小到大进行排序，逐一取用即可
function m.GetSpecialIndex()
	local result = {}
	local count = GetTDDifficulty() -1
	if count > 0 then
		--怪物出现的区间，第11到20个怪。索引对应的是10-19
		local indexes = {}
		for var=10, 19 do
			table.insert(indexes,var)
		end
		--随机出现的位置
		for var=1, count do
			--目前最多会有5个精英怪，而随机区间有10个，应该不会出现nil的情况。后续有多的再考虑
			table.insert(result,table.remove(indexes,RandomInt(1,#indexes)))
		end
		--排序
		table.sort(result)
	end
	return result
end
---精英怪技能
local specialAbilityes = {
	"jingyingguai_slgh","jingyingguai_xrgh","jingyingguai_hjgh","jingyingguai_xegh",
	"jingyingguai_njgh","jingyingguai_qd","jingyingguai_zlpx","jingyingguai_xrwl",
	"jingyingguai_hmgh"
}
---精英怪刷新后，进行以下强化：<br>
--*模型放大<br>
--*血量护甲提升<br>
--*添加随机技能<br>
function m.initSpecialUnit(unit)
	unit.TD_IsSpecial = true
	--模型放大，血量护甲*1.5
	unit:SetModelScale(unit:GetModelScale() * 2)
	
	local hp = unit:GetMaxHealth() * 1.5
	unit:SetMaxHealth(hp)
	unit:SetBaseMaxHealth(hp)
	unit:SetHealth(hp)
	CustomArmor.SetBaseArmor(unit,CustomArmor.GetBaseArmor(unit) * 1.5)
	--随机技能
	local ability = specialAbilityes[RandomInt(1,#specialAbilityes)]
	if ability then
		ability = unit:AddAbility(ability)
		if ability then
			local level = math.ceil((unit._spawner_wave or 10) / 10)
			--设置单位等级，单位升级几次，技能就升级几次。，但是这个技能由于是后加的，所以技能等级会低一级，下面再额外设置一下等级
			unit:CreatureLevelUp(level - 1)
			ability:SetLevel(level)
		end
	end
end

---开启无尽模式。无尽模式是单人的
function m.EnterInfinite()
	--清除地图上所有敌方单位
	local enemy = FindEnemiesInRadiusEx(TEAM_PLAYER,Vector(0,0,0),FIND_UNITS_EVERYWHERE)
	if enemy and #enemy > 0 then
		for _, unit in pairs(enemy) do
			EntityHelper.kill(unit,true)
		end
	end
	
	NotifyUtil.Top(nil,"#info_infinite_mode_enable",10,"yellow")
	NotifyUtil.ShowSysMsg(nil,"#info_infinite_mode_enable",10)
	--倒计时，开启无尽
	local delay = config_td_infinite_start_delay()
	TimerUtil.createTimer(function()
		SendToAllClient("xxdld_topbar_next_timer",{count = delay,wave = "?",infinite=true})
		if delay == 0 then
			SpawnerInfinite.start()
			IsInfinite = true
			bgm.infinite(1)
		else
			delay = delay - 1;
			return 1
		end
	end)
end

---获取当前波次。不区分无尽和非无尽，需要使用IsInfinite来区分
function m.GetCurrentWave()
	if IsInfinite then
		return SpawnerInfinite.GetCurrentWave()
	elseif game_mode == 2 then
		return SpawnerSingle.GetCurrentWave()
	else
		return SpawnerTeam.GetCurrentWave()
	end
	return 0
end

---是否是无尽模式
function m.IsInfinite()
	return IsInfinite
end

---进攻怪死亡掉落物品
--@param #handle unit 单位实体
--@param #number wave 波次
--@param #number killer 杀手单位
function m.DropItem(unit,wave,killer)
	if not wave or wave > config_td_base_wave_count() or not unit then
		return;
	end
	
--	--礼花掉落
--	local chance = 2
--	if unit.TD_IsSpecial then
--		chance = 10
--	elseif unit.TD_IsBoss then
--		chance = 100
--	end
--	if RandomLessInt(chance) then
--		if killer then
--			local pid = PlayerUtil.GetOwnerIDForDummy(killer)
--			local hero = PlayerUtil.GetHero(pid)
--			if hero then
--				if ItemUtil.AddItem(hero,"item_festival_fireworks",true) then
--					NotifyUtil.ShowSysMsg(pid,{"#info_got_item","DOTA_Tooltip_ability_item_festival_fireworks"},3)
--				end
--			end
--		else
--			ItemUtil.CreateItemOnGround("item_festival_fireworks",nil,unit:GetAbsOrigin())
--			NotifyUtil.ShowSysMsg(nil,{"#info_got_item","DOTA_Tooltip_ability_item_festival_fireworks"},3)
--		end
--	end
	

	local difficulty = GetTDDifficulty()
	local chance = 2 + 0.5 * (difficulty - 1)
	if unit.TD_IsBoss then
		chance = 100
	end
	
	if RandomLessFloat(chance) then
		local itemName = nil
		local count = 1
		if unit.TD_IsBoss then --BOSS掉落
			if wave == 10 then
				itemName = "item_box_jj_equipment_2"
			elseif wave == 20 then
				count = 2
				itemName = "item_box_jj_equipment_2"
			elseif wave == 30 then
				itemName = "item_box_jj_equipment_3"
			elseif wave == 40 then
				itemName = "item_box_jj_equipment_4"
			elseif wave == 50 then
				itemName = "item_box_jj_equipment_5"
			end
		else
			if wave <= 20 then
				itemName = "item_box_base_equipment_1"
			elseif wave <= 40 then
				itemName = "item_box_base_equipment_2"
			elseif wave <= config_td_base_wave_count() then
				itemName = "item_box_base_equipment_3"
			end
		end
		
		if itemName then
			if killer then
				local pid = PlayerUtil.GetOwnerIDForDummy(killer)
				local hero = PlayerUtil.GetHero(pid)
				if hero then
					for var=1, count do
						ItemUtil.AddItem(hero,itemName,true)
						NotifyUtil.ShowSysMsg(pid,{"#info_got_item","DOTA_Tooltip_ability_"..itemName},3)
					end
				end
			else
				for var=1, count do
					ItemUtil.CreateItemOnGround(itemName,nil,unit:GetAbsOrigin())
					NotifyUtil.ShowSysMsg(nil,{"#info_got_item","DOTA_Tooltip_ability_"..itemName},3)
				end
			end
		end
	end
end

---清空玩家数据：地上的物品、塔单位、建造者，返回是否已经清除了数据
function m.ClearPlayerData(PlayerID)
	if not m.HasClearedPlayerData(PlayerID) then
		--移除英雄。这个杀死单位以后，通过设置gamerules和gamemode的属性，可以限制买活和自动复活。
		--但是这个时候英雄仍然可以购买和出售物品、获得自动奖励的金币等
		local hero = PlayerUtil.GetHero(PlayerID)
		if hero then
			EntityHelper.kill(hero,true)
		end
		
		--移除地上归属于该玩家的物品，优先于下面的单位移除，因为怕先移除单位会导致这个purchaser为空了
		local items = {}
		for _,item in pairs(Entities:FindAllByClassname("dota_item_drop")) do
			local containedItem = item:GetContainedItem()
			local owner = containedItem:GetPurchaser()
			if owner and PlayerUtil.GetOwnerID(owner) == PlayerID then
				--先记录，避免删除英雄后获取不到了。延迟删除。
				table.insert(items,item)
			end
		end
		
		--移除塔，在移除单位的时候，单位身上的物品会在一定时间后自动销毁。但是如果扔在了地上，则不会被销毁掉。用下面的逻辑销毁
		Towermgr.ClearPlayerTower(PlayerID)
		
		--移除物品
		TimerUtil.createTimerWithDelay(3,function()
			for _, item in pairs(items) do
				if EntityNotNull(item) then
					local containedItem = item:GetContainedItem()
					EntityHelper.remove(item)
					EntityHelper.remove(containedItem)
				end
			end
		end)
		
		PlayerUtil.setAttrByPlayer(PlayerID,key_cleared,true)
	end
	return true
end

---是否已经清空了玩家数据。当玩家失败或者离开游戏等场景中，会清除数据
function m.HasClearedPlayerData(PlayerID)
	return PlayerUtil.getAttrByPlayer(PlayerID,key_cleared)
end

---单人模式下，玩家失败了。移除玩家的数据，标记失败状态。返回该玩家是否已经失败
function m.PlayerFaild(PlayerID)
	--清空数据成功了才标记失败
	if m.ClearPlayerData(PlayerID) and not m.IsPlayerFaild(PlayerID) then
		PlayerUtil.setAttrByPlayer(PlayerID,key_faild,true)
	end
	
	return m.IsPlayerFaild(PlayerID)
end

---判断某个玩家是否失败。游戏中离开游戏不被判定为失败，游戏结束的时候没有奖励。
--只有坚持到失败的情况下才算失败，此时有奖励
function m.IsPlayerFaild(PlayerID)
	return PlayerUtil.getAttrByPlayer(PlayerID,key_faild);
end

---发送游戏结束信息，显示结束面板
function m.GameFinished()
	--结束游戏，避免服务器响应过慢。进入无尽的都认为是胜利的
	if m.IsInfinite() then
		GameRules:SetCustomVictoryMessage("#info_game_finished" )
		GameRules:MakeTeamLose(TEAM_ENEMY)
	else
		GameRules:SetCustomVictoryMessage("#info_game_over" )
		GameRules:MakeTeamLose(TEAM_PLAYER)
	end
end

---整队失败，团队模式下，整体失败（怪物数量上限或者没有击杀最终boss），只会获取基础波次，无尽总是0
--<br><font color='red'>失败之前要已经记录过玩家的失败波次才行</font>
function m.TeamFinished()
	local Players = PlayerUtil.GetAllPlayersID()
	
	local aids = nil;
	local data = {}
	for _, PlayerID in pairs(Players) do
		local base = PlayerUtil.getAttrByPlayer(PlayerID,m.key_finish_base) or 0
		local aid = PlayerUtil.GetAccountID(PlayerID)
		if aid and aid ~= "" then
			SetNetTableValue("player_states","final_wave_"..tostring(PlayerID),{base=base,extra=0})
			
			data[aid] = {base = base,extra = 0,sid=PlayerUtil.GetSteamID(PlayerID),gid=setup.GetGID()}
			if aids then
				aids = aids .. "," .. aid
			else
				aids = aid
			end
		end
	end
	
	if aids then
		data = JSON.encode(data)
		http.load("xxj_gfr",{aid=aids,nd=GetTDDifficulty(),data=data},function(result)
			if result and result.success == "1" then
				local reward = result.reward
				if reward then
					for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
						local pReward = reward[PlayerUtil.GetAccountID(PlayerID)]
						if pReward then
							SetNetTableValue("player_states","reward_"..tostring(PlayerID),pReward)
						else
							---如果没有结果，则也设置nettable值，不过都是空的，这样客户端不会显示问号（问号是因为获取不到这个以这个玩家的id为key的nettable）
							SetNetTableValue("player_states","reward_"..tostring(PlayerID),{})
						end
					end
					return ;
				end
			end
			
			---如果没有结果，则也设置nettable值，不过都是空的，这样客户端不会显示问号（问号是因为获取不到这个以这个玩家的id为key的nettable）
			for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
				SetNetTableValue("player_states","reward_"..tostring(PlayerID),{})
			end
		end)
	end
end

---某个玩家失败了，单人模式或者无尽模式下一个玩家失败了。
--<br><font color='red'>失败之前要已经记录过玩家的失败波次才行</font>
function m.PlayerFinished(PlayerID)
	local base = PlayerUtil.getAttrByPlayer(PlayerID,m.key_finish_base) or 0
	local extra = PlayerUtil.getAttrByPlayer(PlayerID,m.key_finish_infinite) or 0
	--基础波都没完，理论上不会有无尽波，这里以防万一
	if base < config_td_base_wave_count() then
		extra = 0
	end
	local aid = PlayerUtil.GetAccountID(PlayerID)
	if aid and aid ~= "" then
		SetNetTableValue("player_states","final_wave_"..tostring(PlayerID),{base=base,extra=extra})
		local data = {[aid]={base = base,extra = extra,sid=PlayerUtil.GetSteamID(PlayerID),gid=setup.GetGID()}}
		
		data = JSON.encode(data)
		http.load("xxj_gfr",{aid=aid,nd=GetTDDifficulty(),data=data},function(result)
			if result and result.success == "1" then
				local reward = result.reward
				if reward then
					local pReward = reward[PlayerUtil.GetAccountID(PlayerID)]
					if pReward then
						SetNetTableValue("player_states","reward_"..tostring(PlayerID),pReward)
						return;
					end
				end
			end
			
			---如果没有结果，则也设置nettable值，不过都是空的，这样客户端不会显示问号（问号是因为获取不到这个以这个玩家的id为key的nettable）
			SetNetTableValue("player_states","reward_"..tostring(PlayerID),{})
		end)
	end
end


---***********************************波次切换处理逻辑*********************************

--所有波次切换的监听函数
local listeners = {}

---注册一个波次变化(增加了)的监听，无尽波也会触发。这个监听的触发在波次奖金和清空上一波单位伤害之前
--@param #function func 监听函数，会传入参数：now（变化后的波次），返回true，则移除该监听
--@return #string 返回监听名字，可以用RemoveWaveChangeListener移除监听
function m.RegisterWaveChangeListener(func)
	if type(func) == "function" then
		local name = DoUniqueString("listener")
		listeners[name] = {func=func}
		return name
	end
end

---移除一个波次变化的监听
function m.RemoveWaveChangeListener(name)
	if type(name) == "string" then
		local listener = listeners[name]
		if listener then
			listener.invalid = true
		end
	end
end

---波次变化（增加了），要在波次奖金和清空上一波单位伤害之前触发。无尽波也会触发
function m.WaveChange(now)
	for name, listener in pairs(listeners) do
		if not listener.invalid then
			local status,msg = pcall(listener.func,now)
			if status and msg then
				listener[name] = nil
			elseif not status then
				DebugPrint(msg)
			end
		else
			listener[name] = nil
		end
	end
end

return m;