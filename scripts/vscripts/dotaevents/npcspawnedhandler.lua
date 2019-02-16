--NPC刷新（产生对应实体）的时候刷新，每次刷新都会调用
local m = {}

---npc刷新事件(包括英雄刷新)
--keys:{
--	entindex: (number)
--	splitscreenplayer: (number)
--}
function m:OnNPCSpawned(keys)
	local unit = EntityHelper.findEntityByIndex(keys.entindex)
	local unitName = unit:GetUnitName()
	
	if unitName == "npc_dota_hero_wisp" then
		unit:AddNoDraw()
	else
		--建造者技能设置了升级间隔是0，所以初始会额外获得一点技能点，这里清空掉
		if unit:IsHero() then
			unit:SetAbilityPoints(0)
		end
		
		--非虚拟单位才添加相关buff
		if unitName ~= "npc_dummy_unit" then
			--给玩家的单位添加一个获取金币的modifier。用默认的过滤器的话，幻象击杀进不去过滤器
			--所以所有单位都统一在这个modifier里面处理获取金币的逻辑
			if unit:GetTeamNumber() == TEAM_PLAYER then
				AddLuaModifier(nil,unit,"modifier_unit_kill_gold",{})
			else--敌方单位才添加护甲
				CustomArmor.UnitSpawned(unit)
			end
		end
	end
end

return m