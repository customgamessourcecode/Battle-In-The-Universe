--游戏状态变化时的处理逻辑
local m = {}

--游戏状态改变的时候触发（比如是选择英雄还是游戏进行中还是游戏结束等等状态）
function m:OnGameRulesStateChange(keys)
	--获取游戏进度
	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then--等待玩家加载游戏
		
	elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then --玩家加载完毕后，游戏设置界面。参考 https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Custom_Game_Setup
		--加载数据
		local params = PlayerUtil.GetAllAccount();
		http.get("gi",params,function(data)
			if data then
				PlayerUtil.InitPlayerData(data.xxdld)
			else
				DebugPrint("load data faild")
			end
		end)
		bgm.init()
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then --英雄选择阶段，这个阶段就可以获取到地图上的实体了
	
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then --游戏在准备阶段
	
	elseif newState == DOTA_GAMERULES_STATE_POST_GAME then --游戏结束，向服务器发送数据
		http.load("xxj_game",{finish=1,gid=setup.GetGID()},function()end)
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then  --游戏开始
		setup.SetupInit();
	end
end

return m;