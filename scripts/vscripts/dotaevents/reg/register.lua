local GameStateChange = require("DotaEvents.GameStateChange") --游戏阶段改变
local PlayerConnectHandler = require("DotaEvents.PlayerConnectHandler") --玩家连接或者断开的处理器
local NPCSpawnedHandler = require("DotaEvents.NPCSpawnedHandler") --npc刷新(产生)事件处理
local MiscHandler = require('DotaEvents.MiscHandler') --其他事件
--技能相关的事件处理
--local AbilityHandler = require("eventHandlers.AbilityHandler")

---单位死亡处理，主要是物品掉落，任务处理等<br/>
--通过调用其中的监听注册函数，添加特殊的处理逻辑
--UnitDiedHandler = require("DotaEvents.UnitDiedHandler")



local m = {};

--注册各种内置事件的处理器(具体查看workshopAPI)
function m.register(context)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameStateChange, 'OnGameRulesStateChange'), context)
	
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(PlayerConnectHandler, 'OnConnectFull'), context)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(PlayerConnectHandler, 'OnDisconnect'), context)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(PlayerConnectHandler, 'OnPlayerReconnect'), context)--MOD事件中也有这一项，两个事件的传入参数不一样（具体查看API），不确定到底注册的是哪个
	
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(NPCSpawnedHandler, 'OnNPCSpawned'), context)
	
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(MiscHandler, 'OnPlayerLevelUp'), context)
	
	--ListenToGameEvent('entity_killed', Dynamic_Wrap(UnitDiedHandler, 'OnEntityKilled'), context)
	
	local ChatHandler = require("DotaEvents.ChatHandler")
	ListenToGameEvent("player_chat", Dynamic_Wrap(ChatHandler, 'OnPlayerChat'), context) --公频玩家聊天
end

return m;