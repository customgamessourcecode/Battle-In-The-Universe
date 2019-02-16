--第三方lib
require("libraries.reg.LibRegister")
--工具类
require("utils.reg.UtilRegister")
require("ai.reg.register")
require("customsys.reg.register")
--Dota事件
local DotaEvents = require("DotaEvents.reg.register")
require("abilities.modifiers.register")

if XXDLDGame == nil then
	XXDLDGame = class({})
end

--从各个文件中加载粒子特效、模型和声音文件
function PrecacheEveryThingFromKV( context )
	local kv_files = {
		"scripts/npc/npc_units_custom.txt",
		"scripts/npc/npc_abilities_custom.txt",
		"scripts/npc/npc_heroes_custom.txt",
		"scripts/npc/npc_items_custom.txt"}
	for index, kv in pairs(kv_files) do
		local kvs = LoadKeyValues(kv)
		if kvs then
			PrecacheEverythingFromTable( context, kvs)
			if index == 1 then --缓存一下单位信息
				local callBack = function(data) end;
				for key, var in pairs(kvs) do
					PrecacheUnitByNameAsync(key,callBack)
				end
			end
		end
	end
end

--加载粒子特效、模型和声音文件
function PrecacheEverythingFromTable( context, kvtable)
	for key, value in pairs(kvtable) do
		if type(value) == "table" then
			PrecacheEverythingFromTable( context, value);
		elseif type(value) == "string" then
			if string.find(value, "vpcf") then
				PrecacheResource( "particle",  value, context)
			elseif string.find(value, "vmdl") then
				PrecacheResource( "model",  value, context)
			elseif string.find(value, "vsndevts") then
				PrecacheResource( "soundfile",  value, context)
			end
		end
	end
end
--缓存特效
local precache_particles = function(context)
	PrecacheResource( "particle", "particles/generic_gameplay/illusion_killed.vpcf", context)
end
--缓存声音文件
local precache_sounds = function(context)
	PrecacheResource( "soundfile",  "soundevents/custom_sounds_ui.vsndevts", context)
	PrecacheResource( "soundfile",  "soundevents/voscripts/game_sounds_vo_announcer.vsndevts", context)
	PrecacheResource( "soundfile",  "soundevents/xxj_bgm.vsndevts", context)
end

--预加载
function Precache( context )
	--从kv文件加载数据
	PrecacheEveryThingFromKV( context )
	precache_particles(context)
	precache_sounds(context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = XXDLDGame()
	GameRules.AddonTemplate:InitGameMode()
end

local skipHeroSelect = true

function XXDLDGame:InitGameMode()
	GameRules:SetUseUniversalShopMode( true ) --为真时，所有物品当处于任意商店范围内时都能购买到，包括神秘商店商店物品
	
	GameRules:EnableCustomGameSetupAutoLaunch(true)
	GameRules:SetCustomGameSetupTimeout(0)
	
	GameRules:SetPostGameTime(60) --设置在结束游戏后服务器与玩家断线前的时间
	
	if skipHeroSelect then
		GameRules:SetHeroSelectionTime( 0) --设置选择英雄的时间，因为都设置了自动选择英雄，并且
	else
		GameRules:SetHeroSelectionTime(60) --设置选择英雄的时间，因为都设置了自动选择英雄，并且
	end
	GameRules:SetStrategyTime( 0 ) --设置英雄选择后的决策时间
	GameRules:SetShowcaseTime( 0 )  --设置 天辉vs夜魇 界面的显示时间。
	GameRules:SetSameHeroSelectionEnabled( true ) --允许选择重复英雄
	
	
	GameRules:SetPreGameTime(0) --这是游戏准备时间（英雄选择后到游戏开始）
	
	GameRules:SetHideKillMessageHeaders( true )  --设置是否隐藏击杀提示。
	
	GameRules:SetCustomGameTeamMaxPlayers(TEAM_PLAYER,6)--队伍人数，不设置的话游戏开始一会就会断开，而且会有人进不去游戏
	
	GameRules:SetHeroRespawnEnabled(false)--禁止英雄重生。在无尽模式或者单人模式中，如果玩家死亡了，避免重生。
	
	GameRules:SetStartingGold( 0 )  --设置 初始金钱为0。
	GameRules:SetGoldPerTick(0)
	GameRules:SetGoldTickTime(-1)
	
	GameRules:SetCustomGameAllowHeroPickMusic( false )
 	GameRules:SetCustomGameAllowBattleMusic( false )
	GameRules:SetCustomGameAllowMusicAtGameStart( false )
	
	local mode = GameRules:GetGameModeEntity()
	mode:SetFogOfWarDisabled(true) -- 是否关闭战争迷雾（对两方都有效）
	mode:SetUnseenFogOfWarEnabled(true) --启用/禁用战争迷雾（上边为false才有用）。启用的情况下，未探测区域显示不透明的黑色，探测后变成透明的灰色；禁用的情况下，未探测区域是透明的灰色覆盖
	mode:SetAnnouncerDisabled( true ) -- 禁用播音员
	mode:SetLoseGoldOnDeath(false)
	
	mode:SetStashPurchasingDisabled ( false ) -- 是否关闭/开启储藏处购买功能。如果该功能被关闭(true)，英雄必须在商店范围内购买物品
	
	mode:SetDaynightCycleDisabled(true)
	
	mode:SetCameraDistanceOverride(1500)
	
	--攻击速度是一个复杂的体系。简单来说，同一攻击间隔，最大攻击速度越大，满攻速时候的攻击频率就越高
	mode:SetMaximumAttackSpeed( 600 ) -- 设置单位的最大攻击速度
	mode:SetMinimumAttackSpeed( 20 ) -- 设置单位的最小攻击速度
	
	mode:SetBuybackEnabled(false)--禁止买活
	--默认所有人选择同一个单位，这个操作会导致游戏直接进入pregame阶段。
	if skipHeroSelect then
		mode:SetCustomGameForceHero("npc_dota_hero_wisp")
	end
	
	Filters.Init(mode,self)
	
	DotaEvents.register(self)
	
	self:RegisterCMD()
	
	
	--这个是服务端的，默认应该就有回收机制，这样做，稍微辅助一下
	GameRules:GetGameModeEntity():SetContextThink(
		DoUniqueString("collectgarbage"),
		function()
			collectgarbage("collect");
			return 300
		end,
		300)
	
	--物品数量限制
	SendToServerConsole("dota_max_physical_items_purchase_limit 99999");
end


function XXDLDGame:RegisterCMD()
--	Convars:RegisterCommand( "td_test_cmd",function() 
--		RankList.Sync(0)
--	end , "test_name", FCVAR_CHEAT )
end
