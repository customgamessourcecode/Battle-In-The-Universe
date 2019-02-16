local m = {}
---
--形式为：
--category={
--	{
--		name=itemName,
--		canBuy=true/false(发送到客户端是1和0)
--	},...
--}
local shopItems = {}

---存储限量销售的物品信息。
--itemName = {初始数量init、刷新时间time、最大数量max、当前数量now、正在刷新stocking、当前刷新剩余时间rest}
local stockItems = {}

local function increaseStockItem(itemName)
	local stock = stockItems[itemName]
	if stock and type(stock.time) == "number" then
		if stock.now < stock.max and not stock.stocking then
			local duration = stock.time
			TimerUtil.createTimer(function()
				stock.rest = duration
				if duration == 0 then
					stock.now = stock.now + 1
					stock.stocking = false
					stock.rest = 0
					m.itemStockChange(itemName)
					return
				end
				duration = duration - 1
				return 1
			end)
			stock.stocking = true
		end
	end
end

function m.itemStockChange(itemName)
	local stock = stockItems[itemName]
	if stock then
		--先执行这样，这样，在物品数量减为0的时候，才能正常获取到物品的刷新时间
		if stock.now < stock.max then
			increaseStockItem(itemName)
		end
		SendToAllClient("custom_shop_stock_count_change",{item=itemName,count=stock.now,duration=stock.time,rest=stock.rest})
	end
end

function m.initStockItem(PlayerID)
	for itemName, stock in pairs(stockItems) do
		SendToClient(PlayerID,"custom_shop_stock_count_change",{item=itemName,count=stock.now,duration=stock.time,rest=stock.rest})
	end
end


function m.initShop(_,data)
	local PlayerID = data.PlayerID
	
	if PlayerUtil.IsValidPlayer(PlayerID) then
		SendToClient(PlayerID,"custom_shop_init",shopItems)
		m.initStockItem(PlayerID)
	end
end

function m.buyItem(_,data)
	local buyerID ,itemName,unitIndex = data.PlayerID,data.item,data.unit
	if not PlayerUtil.IsValidPlayer(buyerID) then
		return
	end
	
	if itemName then
		local item = CreateItem(itemName,nil,nil)
		if not item:IsPurchasable() then
			NotifyUtil.ShowError(buyerID,"custom_shop_can_not_buy",2)
			EntityHelper.remove(item)
			return;
		end
		--要购买物品的单位和其所属玩家。
		--如果A玩家可以操作B玩家，则允许A玩家用B玩家的单位购买物品，消耗的是B的钱
--		local purchaser = EntityHelper.findEntityByIndex(unitIndex)
--		local purchaserPlayerID = purchaser:GetPlayerOwnerID()
--		if EntityIsNull(purchaser) then
--			return;
--		elseif purchaserPlayerID ~= buyerID then
--			if not PlayerResource:AreUnitsSharedWithPlayerID(purchaserPlayerID,buyerID) then
--				return
--			end
--		end
		
		--无论当前选中的是谁的单位，始终是买给自己的。如果后续需要，再使用上边的逻辑
		local purchaser = PlayerUtil.GetHero(buyerID)
		local purchaserPlayerID = buyerID
		
		local buySuccess = false;
		
		local cost = item:GetCost()
		if PlayerUtil.GetGold(purchaserPlayerID) >= cost then
			local stock = stockItems[itemName]
			if stock then
				if stock.now > 0 then
					item = ItemUtil.AddItem(purchaser,item,true)
					if item then
						PlayerUtil.SpendGold(purchaserPlayerID,cost)
						EmitSoundForPlayer("ui.buyItem",PlayerUtil.GetPlayer(buyerID))
						if buyerID ~= purchaserPlayerID then
							EmitSoundForPlayer("ui.buyItem",PlayerUtil.GetPlayer(purchaserPlayerID))
						end
						
						--购买人和购买时间
						item:SetPurchaser(purchaser)
						item:SetPurchaseTime(GameRules:GetGameTime())
						
						stock.now = stock.now - 1
						m.itemStockChange(itemName)
						buySuccess = true
					end
				else
					NotifyUtil.ShowError(buyerID,"custom_shop_error_out_of_stack",2)
				end
			else
				item = ItemUtil.AddItem(purchaser,item,true)
				if item then
					PlayerUtil.SpendGold(purchaserPlayerID,cost)
					EmitSoundForPlayer("ui.buyItem",PlayerUtil.GetPlayer(buyerID))
					if buyerID ~= purchaserPlayerID then
						EmitSoundForPlayer("ui.buyItem",PlayerUtil.GetPlayer(purchaserPlayerID))
					end
					buySuccess = true
				end
			end
		else
			NotifyUtil.ShowError(buyerID,"error_need_more_gold",2)
		end
		
		--购买失败，删掉这个实体
		if not buySuccess then
			EntityHelper.remove(item)
		end
		
	end
end

local init = function()
	local itemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
	
	for itemName, value in pairs(itemKV) do
		if value.ItemStockMax and value.ItemStockMax > 0 then
			local stock = {}
			stock.init = value.ItemStockInitial
			stock.time = value.ItemStockTime
			stock.max = value.ItemStockMax
			
			if not stock.time or stock.time == 0 then
				stock.now = stock.max
			else
				stock.now = stock.init
			end
			stockItems[itemName] = stock
			
			increaseStockItem(itemName)
		end
	end
	
	--所有商店物品
	local shopItemKV = LoadKeyValues("scripts/kv/shop.kv") 
	for categoryName, items in pairs(shopItemKV) do
		local category = {}
		shopItems[categoryName] = category
		
		---所有的物品按照key进行排序以后再发送到客户端，保证每次给客户端的结果都是一样的
		--由于key在LoadKeyValues中会解析成字符串，这里处理成数字进行排序，然后在下面使用的时候再转换为字符串
		local sortKey = {}
		for key, var in pairs(items) do
			local numKey = tonumber(key)
			if numKey then
				table.insert(sortKey,numKey)
			end
		end
		table.sort(sortKey)
		for _, key in ipairs(sortKey) do
			local itemName = items[tostring(key)]
			local item = CreateItem(itemName,nil,nil)
			if item then
				local itemData = {}
				itemData.name = itemName
				itemData.canBuy = item:IsPurchasable()
				table.insert(category,itemData)
				EntityHelper.remove(item)
			end
		end
	end

	RegisterEventListener("custom_shop_init_request",m.initShop)
	RegisterEventListener("custom_shop_buy_item",m.buyItem)
end

xpcall(function() return init() end,
function (msg)
	if IsInToolsMode() then
		print("shop init faild!!!\n"..msg..'\n'..debug.traceback()..'\n')
	end
end)

return m