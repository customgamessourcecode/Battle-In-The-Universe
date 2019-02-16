local m = {}

---点击抽卡技能后，如果成功打开抽卡界面，则在玩家数据中缓存使用的抽卡技能。保证同一时刻只能用一个技能<br>
--如果是plus赠送的抽卡物品，则存储的不是技能而是一个布尔值 true，主要为了避免再抽卡期间再次打开抽卡界面
local key_draw_source = "DrawingCardSource"

---抽卡的时候，出现高等级卡的概率。
local highLevelChance = {
	[2] = 30,
	[3] = 25,
	[4] = 20,
	[5] = 10,
}

---获取某玩家本局所选世界中指定品质的所有卡片：必须该玩家拥有的卡片才会返回<br>
--有两个返回值：
--<pre>
--第一个是所有卡片的名字的数组（用来做随机用）
--第二个是卡片数据的table（可以通过名字索引获取到卡片信息)。
--卡片数据：
--{
--	cardName = {
--		grade = 12345,
--		element = 1,2,3,4,5
--		ability = {
--			ability1,ability2
--		}
--		world = worldName
--	}
--}
--</pre>
function m.GetSpecificCards(PlayerID,selectedWorlds,quality)
	local result = {}
	local names = {};
	for _, worldName in pairs(selectedWorlds) do
		local cards = Cardmgr.GetCardsInWorld(worldName,quality);
		if cards then
			for cardName, data in pairs(cards) do
				if PlayerUtil.GetCard(PlayerID,worldName,cardName) then
					table.insert(names,cardName)
					result[cardName] = data;
				end
			end
		end
	end
	
	if #names > 0 then
		return names,result;
	end
end

---游戏内抽卡功能
--@param #handle caster 
--@param #handle ability 抽卡技能
--@param #number quality 最低品质，顶级及以下的抽卡必然会抽到最低品质的，有一定概率抽取的高一级的品质
--@param #number goldCost 金币花费，技能抽卡会消耗金币，某些特殊抽卡不需要消耗金币，此时传入0即可
--@param #boolean notHighQuality 抽卡时候是否不抽取比quality高一阶的品质
function m.DrawInGame(caster,ability,quality,goldCost,notHighQuality)
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	local selectedWorlds = setup.GetSelectWorlds(PlayerID)
	--同一时刻只能使用一种抽卡技能
--	if selectedWorlds and not PlayerUtil.getAttrByPlayer(PlayerID,key_draw_source) and not ability.IsDrawing then
	if selectedWorlds and not PlayerUtil.getAttrByPlayer(PlayerID,key_draw_source) then
		if PlayerUtil.GetGold(PlayerID) < goldCost then
			NotifyUtil.ShowError(PlayerID,"#error_need_more_gold",3)
			return;
		end
	
		PlayerUtil.SpendGold(PlayerID,goldCost)
		ability.DrawGoldCost = goldCost
		--物品的话，添加一个标记，避免A玩家先点出来抽卡界面，然后把物品再给B玩家，这样，B的draw_source为空，就可以再次使用了
		--由于目前物品不可共享，不可丢弃，所以暂时不会出现上边的情况，如果有需要再加上就行了。但是加上以后要在客户端确认的逻辑中特殊处理：
		--由于物品可以叠加，如果有多个，则应该减少一个，并将物品的IsDrawing置为false
--		if ability:IsItem() then
--			ability.IsDrawing = true
--		end
	
		local status,error = pcall(function()
			local allCards,allData = m.GetSpecificCards(PlayerID,selectedWorlds,quality)
			--高品质卡信息
			local highLevelCards,highData = nil,nil
			if not notHighQuality then
				highLevelCards,highData = m.GetSpecificCards(PlayerID,selectedWorlds,quality+1)
			end
			
			---是一个数组，保证1.2.3.。。的顺序。每一个元素是一个table{name=xxx,data=cardData}
			local result = {}
			
			---随机卡片，第三张的时候，有几率获取到高级卡片
			if allCards and allData then
				--共随机多少张
				local max = 3;
				
				for var=1, max do
					if var < max then
						local cardName = table.remove(allCards,RandomInt(1,#allCards))
						if cardName then
							--以数组的形式存储，保证顺序
							local t = {}
							t.name = cardName
							t.data = allData[cardName]
							table.insert(result,t)
						end
					else
						--最后一张有概率随机到高级的
						local chance = highLevelChance[quality+1];
						if highLevelCards and highData and chance and RandomLessInt(chance) then
							local cardName = table.remove(highLevelCards,RandomInt(1,#highLevelCards))
							if cardName then
								--以数组的形式存储，保证顺序
								local t = {}
								t.name = cardName
								t.data = highData[cardName]
								t.high = true --标记高品质
								table.insert(result,t)
							end
						else
							local cardName = table.remove(allCards,RandomInt(1,#allCards))
							if cardName then
								--以数组的形式存储，保证顺序
								local t = {}
								t.name = cardName
								t.data = allData[cardName]
								table.insert(result,t)
							end
						end
					end
				end
			end
			
			--如果忽略选择，直接随机卡片
			if m.IsDrawIgnoreChoiceEnabled(PlayerID) then
				local card = result[RandomInt(1,#result)]
				if card.high then
					local path = "particles/generic_gameplay/screen_arcane_drop.vpcf"
					CreateParticleEx(path,PATTACH_MAIN_VIEW,caster,2,true)
					NotifyUtil.BottomGroup(PlayerID,{"#info_draw_got_high_quality_card","#DOTA_Tooltip_ability_item_"..card.name},3,"yellow")
				end
				m.Client_Confirm(nil,{PlayerID=PlayerID,card=card.name})
			else
				m.ShowGoldDrawResultForClient(PlayerID,result,ability)
			end
		end)
		
		--出错了，清空缓存的技能
		if not status then
			PlayerUtil.setAttrByPlayer(PlayerID,key_draw_source,nil)
			if goldCost > 0 then
				PlayerUtil.AddGold(PlayerID,goldCost)
			end
			
			if ability:IsItem() then
				ability.IsDrawing = false;
			end
			
			DebugPrint("draw card error:")
			DebugPrint(error)
		end
	end
end

---为某个玩家显示金币抽卡结果<p>
--@param #number PlayerID 玩家数字id
--@param #table cards 
--<pre>
--{
--	{
--		name = cardName,
--		data = {
--			grade = 12345,
--			element = 1,2,3,4,5
--			ability = {
--				ability1,ability2
--			}
--			world = worldName
--		}
--	},
--	...
--}</pre>
--@param #any source 抽卡源，用来避免重复抽卡的。
--@param #boolean isPrivilege 是否是特权卡赠送的，客户端特殊显示
function m.ShowGoldDrawResultForClient(PlayerID,cards,source,isPrivilege)
	if not PlayerUtil.getAttrByPlayer(PlayerID,key_draw_source) then
		PlayerUtil.setAttrByPlayer(PlayerID,key_draw_source,source)
		SendToClient(PlayerID,"draw_card_in_game_result",{cards=cards,privilege=isPrivilege})
	end
end

---客户端选择了某张卡片后，增加物品。
function m.Client_Confirm(_,keys)
	local PlayerID,cardName = keys.PlayerID,keys.card
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	
	local ability = PlayerUtil.getAttrByPlayer(PlayerID,key_draw_source)
	if type(ability) == "table" then
		if not ability:IsItem() then
			--全都没有要，返还一半金币
			if not cardName and ability.DrawGoldCost and ability.DrawGoldCost > 0 then
				local gold = math.ceil(ability.DrawGoldCost / 2)
				PlayerUtil.AddGold(PlayerID,gold)
				ShowOverheadMsg(PlayerUtil.GetHero(PlayerID),OVERHEAD_ALERT_GOLD,gold,PlayerUtil.GetPlayer(PlayerID,true))
			end
		else
			local goldCost = ability:GetCost()
			--返还物品价格一半的金币
			if goldCost > 0 and not cardName then
				local gold = math.ceil(goldCost / 2)
				PlayerUtil.AddGold(PlayerID,gold)
				ShowOverheadMsg(PlayerUtil.GetHero(PlayerID),OVERHEAD_ALERT_GOLD,gold,PlayerUtil.GetPlayer(PlayerID,true))
			end
			--如果是道具，移除掉。这种直接删除了实体，所以即便先扔在地上再点击抽卡，拾取后也不会再有了
			if ability:GetCurrentCharges() > 1 then
				--可叠加的，特殊处理
				ability:SetCurrentCharges(ability:GetCurrentCharges() - 1)
			else
				EntityHelper.remove(ability)
			end
		end
	end
	--清空缓存
	PlayerUtil.setAttrByPlayer(PlayerID,key_draw_source,nil)
	
	---选择了卡片名字，创建物品
	if type(cardName) == "string" and cardName ~= "" then
		local hero = PlayerUtil.GetHero(PlayerID);
		ItemUtil.AddItem(hero,"item_"..cardName,true)
	end
end

---某玩家是否开启了忽略抽卡选择的功能
function m.IsDrawIgnoreChoiceEnabled(PlayerID)
	return PlayerUtil.getAttrByPlayer(PlayerID,"draw_ignore_choice")
end

---玩家重连，清空缓存数据，避免在抽卡界面出来以后就掉线了，导致重连后不能抽卡
function m.PlayerReconnect(PlayerID)
	if PlayerUtil.IsValidPlayer(PlayerID) then
		PlayerUtil.setAttrByPlayer(PlayerID,key_draw_source,nil)
	end
end

---抽卡忽略选择状态改变：激活状态下，抽卡的时候不弹出选择界面，直接随机一张卡片
function m.Client_IgnoreChoiceChange(_,keys)
	local PlayerID = keys.PlayerID
	--非游戏内玩家不响应这个时间。否则有人观战就会弹出一次这个按钮的选择状态界面（观战人员传过来的PlayerID为-1，代表了所有人）
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	local drawIgnoreChoice = PlayerUtil.getAttrByPlayer(PlayerID,"draw_ignore_choice")
	if keys.change == 1 then
		drawIgnoreChoice = not drawIgnoreChoice;
		PlayerUtil.setAttrByPlayer(PlayerID,"draw_ignore_choice",drawIgnoreChoice)
	end
	
	SendToClient(PlayerID,"draw_card_in_game_ignore_choice",{enabled=drawIgnoreChoice})
end

local init = function()
	RegisterEventListener("draw_card_in_game_confirmed",m.Client_Confirm)
	RegisterEventListener("draw_card_in_game_ignore_choice_change",m.Client_IgnoreChoiceChange)
end
init()
return m;