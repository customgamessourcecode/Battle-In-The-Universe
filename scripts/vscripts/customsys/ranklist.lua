--排行榜
local m = {}

--排行榜启动。
--添加计时器，定时更新游戏数据。定时器在启动一小时后第一次自动执行。
function m.start()
	--添加计时器，定时更新排行榜信息
	TimerUtil.createTimer(function()
		local ids;
		--查询所有玩家的排行
		for _, PlayerID in ipairs(PlayerUtil.GetAllPlayersID()) do
			local accountID = PlayerUtil.GetAccountID(PlayerID,false)
			if accountID then
				if ids then
					ids = ids .. "," .. accountID
				else
					ids = accountID
				end
			end
		end
		if ids then
			http.load("xxj_rank",{aid=ids},function(data)
				m.data = data
				m.Sync()
			end)
			--一小时更新一次
			return 3600;
		else
			return 30
		end
	end);
end

function m.Sync(PlayerID,tryWhenNoData)
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return
	end
	if m.data then
		local timeList = {}
		local timePlayer = {}
		
		local waveList = {}
		local wavePlayer = {}
		
		if m.data.time then
			local timeData = m.data.time
			if timeData.week then
				timeList.week = timeData.week.list
				timePlayer.week = timeData.week.player
			end
			if timeData.month then
				timeList.month = timeData.month.list
				timePlayer.month = timeData.month.player
			end
		end
		if m.data.wave then
			local waveData = m.data.wave
			if waveData.week then
				waveList.week = waveData.week.list
				wavePlayer.week = waveData.week.player
			end
			if waveData.month then
				waveList.month = waveData.month.list
				wavePlayer.month = waveData.month.player
			end
		end
		
		
		if PlayerID then
			local data = {}
			data.count = m.data.count
			data.timeList = timeList;
			data.waveList = waveList
			
			local aid = PlayerUtil.GetAccountID(PlayerID)
			if aid then
				data.timeMine = {}
				if timePlayer.week then
					data.timeMine.week = timePlayer.week[aid]
				end
				if timePlayer.month then
					data.timeMine.month = timePlayer.month[aid]
				end
				data.waveMine = {}
				if wavePlayer.week then
					data.waveMine.week = wavePlayer.week[aid]
				end
				if wavePlayer.month then
					data.waveMine.month = wavePlayer.month[aid]
				end
			end
			
			SendToClient(PlayerID,"XXJ_RefreshRankList",data)
		else
			for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID(true)) do
				local data = {}
				data.count = m.data.count
				data.timeList = timeList;
				data.waveList = waveList
				
				local aid = PlayerUtil.GetAccountID(PlayerID)
				if aid then
					data.timeMine = {}
					if timePlayer.week then
						data.timeMine.week = timePlayer.week[aid]
					end
					if timePlayer.month then
						data.timeMine.month = timePlayer.month[aid]
					end
					data.waveMine = {}
					if wavePlayer.week then
						data.waveMine.week = wavePlayer.week[aid]
					end
					if wavePlayer.month then
						data.waveMine.month = wavePlayer.month[aid]
					end
				end
				
				SendToClient(PlayerID,"XXJ_RefreshRankList",data)
			end
		end
		
		return true;
	elseif tryWhenNoData then
		TimerUtil.createTimerWithDelay(5,function()
			m.Sync(PlayerID,tryWhenNoData)
		end)
	end
end

local init = function()
	RegisterEventListener("XXJ_RefreshRankList_request",function(_,keys)
		m.Sync(keys.PlayerID,true)
	end)
end
init()
return m;
