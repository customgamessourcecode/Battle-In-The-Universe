---团队模式下，地图上最多存活的敌人数量
config_td_max_enemy_count_team = function()
	local PlayerCount = PlayerUtil.GetPlayerCount()
	return PlayerCount * 42
end

---单人模式下，地图上最多存活的敌人数量
config_td_max_enemy_count_single = function()
	return 42
end

---准备界面的时间
config_td_time_setup = function() 
	return 300
end
---难度选择的时间
config_td_time_difficulty = function()
	return 45
end

---开始游戏最少选择的世界数量
config_td_min_selection = function()
	return 5
end
---基础进攻怪波数，结束后开启无限模式
config_td_base_wave_count = function()
	return 50
end

---基础波怪物刷新完毕后，延迟一定时间后，检测最后一波boss是否击杀， 如果击杀了则认为通关，可以进入无尽模式。
--否则游戏失败。这个是延迟的时间
config_td_delay_before_infinite = function()
	return 120
end

---成功进入无尽后，延迟多久开始无尽刷怪
config_td_infinite_start_delay = function()
	if TD_GMAE_MODE_TEST then
		return 240
	end
	return 120
end

---怪物数量达到上限后，延迟多久判定失败
config_td_faild_delay = function()
	return 6
end
---游戏开始前的准备时间
config_td_time_prepare = function()
	if IsInToolsMode() then
		return 100000000
	end
	return 30
end