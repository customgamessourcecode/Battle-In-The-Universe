local m = {}

---给某个单位添加物品
--@param #handle unit 单位实体
--@param #any itemOrName 物品名称或者物品实体
--@param #boolean canDrop 如果单位没有空余的空间了，是否可以扔在地上
--@return #handle 创建成功的物品实体
function m.AddItem(unit,itemOrName,canDrop)
	if EntityIsNull(unit) then
		return;
	end
	--对于英雄遍历了物品栏、背包和仓库，普通单位只遍历物品栏和背包，因为遍历仓库虽然会进入addItem，但是并不能加入到该玩家的仓库里面。
	local count = 8
	if unit:IsRealHero() then
		count = 14;
	end
	for slot=0, count do
		local item = unit:GetItemInSlot(slot)
		if not item then
			--创建物品，把购买时间置为0，用名称添加的可以被原价卖掉
			if type(itemOrName) == "string" then
				item = CreateItem(itemOrName, unit, unit)
			else
				item = itemOrName
			end
			if item then
				item:SetPurchaseTime(0)
				return unit:AddItem(item)
			end
		end
	end
	
	if canDrop then
		return m.CreateItemOnGround(itemOrName,unit,unit:GetAbsOrigin())
	end
end

---在地上创建一个物品
function m.CreateItemOnGround(itemOrName,owner,pos)
	local item = itemOrName 
	if type(itemOrName) == "string" then
		item = CreateItem(itemOrName, owner, owner)
	end
	
	if item and item.SetPurchaseTime then
		item:SetPurchaseTime(0)
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(60,100))

		--LaunchLoot:当物品掉落在地面时，将物品发射出去，使其落在某个地点。
		--第一个参数为true，则当该物品被某英雄捡起的时候，立即被使用
		--第二个参数是发射的高度
		--第三个是发射耗时，越小越快
		--第四个参数是掉落地点
		item:LaunchLoot(false, 200, 0.75, pos_launch)
		if owner then
			EmitSoundForPlayer("ui.item_drop_world",PlayerUtil.GetPlayer(owner))
		end
		return item;
	else
		DebugPrint("create item faild!!!\t itemName:"..tostring(itemOrName))
	end
end

return m;