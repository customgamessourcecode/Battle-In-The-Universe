local m = {}

--各个vip等级的消费积分
local vipPoints = {30,100,200,300,500,1000,2500,5000,10000,20000}

---缓存玩家数据，主要用于断线重连的场景。
--key是玩家id，value={
--	point=123,vip="2018-11",soul=123,magic=123,jing=123,vipLvl={point=123,lvl=123}（这个参数在getVipLevel的时候更新）
--}
local PlayerData = {}

---天帝宝库数据
local mystery = {}

---更新缓存的特定玩家数据
--point=123,vip="2018-11",soul=123,magic=123,jing=123
local UpdatePlayerData = function(PlayerID,key,value)
	local data = PlayerData[PlayerID]
	if not data then
		data = {}
		PlayerData[PlayerID] = data
	end
	data[key] = value
end

---正在支付中的订单
--key是玩家id，value是订单号
local orders = {}

---获取某个玩家支付中的订单。同一时刻只能有一个订单存在
local GetCacheOrder = function(PlayerID)
	return orders[PlayerID]
end
---缓存某个玩家正在支付中的订单
local SetCacheOrder = function(PlayerID,order)
	if PlayerID then
		orders[PlayerID] = order
	end
end

---更新玩家数据到客户端
function m.UpdatePlayerDataNetTable(PlayerID)
	local data = PlayerData[PlayerID]
	
	local lvl = 0
	local current = 0
	local max = vipPoints[1]
	local soul = 0
	local magic = 0
	local jing = 0
	local vip = nil
	
	if data then
		soul = data.soul
		magic = data.magic
		jing = data.jing
		vip = data.vip
	
		--计算vip等级
		local all = data.point or 0
		if all > 0 then
			for level, needPoint in pairs(vipPoints) do
				if all <= needPoint or level == #vipPoints then
					if all < needPoint then
						lvl = level - 1
						
						local last = vipPoints[level - 1] or 0
						current = all - last
						max = needPoint - last
					else
						lvl = level
						
						current = 0
						if level == #vipPoints then
							max = 0
						else
							max = vipPoints[level + 1] - needPoint
						end
					end
					break;
				end
			end
		end
	end
	
	local netdata = {
		soul = soul,
		magic = magic,
		jing = jing,
		vip = vip,
		lvl = lvl,
		current = current,
		max = max
	}
	
	SetNetTableValue("custom_store","data_"..tostring(PlayerID),netdata)
end


--为了避免客户端快速点击（比如用连点器之类的操作），导致过量请求，在所有操作前添加一步判断
--如果在客户端判断，使用连点器的话，还是避免不了重复发送请求，在服务端的话，由于客户端服务器肯定存在延迟，被重复触发的可能性更低
local CanAction = function(PlayerID,action,delay)
	if PlayerUtil.getAttrByPlayer(PlayerID,"store_action_processing_"..action) then
		return false;
	end
	PlayerUtil.setAttrByPlayer(PlayerID,"store_action_processing_"..action,true)
	TimerUtil.createTimerWithDelay(delay,function()
		PlayerUtil.setAttrByPlayer(PlayerID,"store_action_processing_"..action,nil)
	end)
	return true;
end

local UpdateAfterRecharge = function(PlayerID)
	local aid = PlayerUtil.GetAccountID(PlayerID)
	http.load("xxdld",{aid=aid,mode="6"},function(data)
		if data and data.store and data.store.player then
			local userData = data.store.player[aid]
			if userData then
				for key, value in pairs(userData) do
					UpdatePlayerData(PlayerID,key,value)
				end
				m.UpdatePlayerDataNetTable(PlayerID)
			end
		end
	end)
end

---查询订单状态
function m.QueryOrderStatus(PlayerID,orderNumber)
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	http.get("rechargeQuery",{payno=orderNumber},function(data)
		local cachedOrder = GetCacheOrder(PlayerID)
		if cachedOrder == orderNumber then --订单没有变化的时候才处理
			if data then
				if data and data.status == "2" then
					--充值成功，发送消息，刷新仙石数量
					SetCacheOrder(PlayerID,nil)
					SendToClient(PlayerID,"custom_store_recharge_result_notify",{success="1"})
					
					UpdateAfterRecharge(PlayerID)
				elseif data.status == "3" or data.status == "4" then
					--充值失败
					SetCacheOrder(PlayerID,nil)
					SendToClient(PlayerID,"custom_store_recharge_result_notify",{success="0"})
				end
			end
		end
	end)
end

---判断某个玩家是否有特权卡。<p>
--这个判断并不能保证在调用时特权卡仍然有效，也就是说如果一个玩家在一局游戏内特权卡失效了，则游戏内的福利仍然可以获取到，比如开局送的人物卡。
--但是其他的依托于服务器时间的福利将不可获取，比如通关卡牌经验加成
function m.HasPrivilegeCard(PlayerID)
	if PlayerUtil.IsValidPlayer(PlayerID) then
		local data = PlayerData[PlayerID]
		if data then
			return data.vip ~= nil
		end
	end
end

---获取某个玩家的vip等级
function m.GetVipLevel(PlayerID)
	if PlayerUtil.IsValidPlayer(PlayerID) then
		local data = PlayerData[PlayerID]
		if data then
			local vipLvl = data.vipLvl
			if not vipLvl then
				vipLvl = {}
				data.vipLvl = vipLvl
			end
			local point = data.point or 0
			if point > 0 then
				if vipLvl.point ~= point then
					vipLvl.point = point
					vipLvl.lvl = 1
					for level, needPoint in pairs(vipPoints) do
						if point < needPoint then
							vipLvl.lvl = level - 1
							break;
						elseif point == needPoint or level == #vipPoints then
							vipLvl.lvl = level
							break;
						end
					end
					return vipLvl.lvl
				else
					return vipLvl.lvl
				end
			end
		end
	end
	return 0
end

---充值
function m.Client_Recharge(_,data)
	local PlayerID,count,type,content = data.PlayerID,data.count,data.type,data.content
	if not PlayerUtil.IsValidPlayer(PlayerID) or not CanAction(PlayerID,"Recharge",3) then
		return;
	end
	--同时只能有一个订单
	local cachedOrder = GetCacheOrder(PlayerID)
	if count > 0 and not cachedOrder then
		local orderNO = PlayerUtil.GetAccountID(PlayerID).."_"..GetDateTime()
		SetCacheOrder(PlayerID,orderNO)
		
		local aid = PlayerUtil.GetAccountID(PlayerID);
		local params = {
			aid = aid,
			payno = orderNO,
			msc = count,
			type = type,
			content = content
		}
		http.get("recharge",params,function(data)
			if data and data.success == "1" and data.url and data.url ~= "" then--成功创建订单
				---订单变化，可能被取消
				local orderNumber = GetCacheOrder(PlayerID);
				if orderNumber ~= orderNO then
					return;
				end
				
				SendToClient(PlayerID,"custom_store_recharge_update_qr",{order=orderNO,url=data.url,type=type})
				
				local count = 15 * 60 --15分钟
				local delay = 5 --5秒查询一次结果
				TimerUtil.createTimerWithRealTime(function()
					local orderNumber = GetCacheOrder(PlayerID);
					--缓存的订单发生了变化，就不再查询了
					if orderNumber == orderNO then
						count = count-1;
						if count == 0 then --时间结束了也没有支付，取消订单
							SetCacheOrder(PlayerID,nil)
							SendToClient(PlayerID,"custom_store_recharge_order_canceld",{})
						else
							--更新客户端显示的有效时间
							SendToClient(PlayerID,"custom_store_recharge_update_qr_timer",{time=count})
							--每隔一段时间异步查询一次支付结果
							delay = delay - 1
							if delay == 0 then
								m.QueryOrderStatus(PlayerID,orderNumber)
								delay = 5;
							end
							return 1;
						end
					end
				end)
			else --请求失败，删除掉
				SetCacheOrder(PlayerID,nil)
				SendToClient(PlayerID,"custom_store_recharge_update_qr",{})
			end
		end)
	end
end
---取消充值订单。
function m.Client_CancelOrder(_,data)
	local PlayerID,order = data.PlayerID,data.order
	if PlayerUtil.IsValidPlayer(PlayerID) and CanAction(PlayerID,"CancelOrder",2)  then
		SetCacheOrder(PlayerID,nil)
		SendToClient(PlayerID,"custom_store_recharge_order_canceld",{})
	end
end

---更新玩家的商城数据
function m.Client_UpdatePlayerData(_,data)
	local PlayerID = data.PlayerID
	if PlayerUtil.IsValidPlayer(PlayerID) then
		m.UpdatePlayerDataNetTable(PlayerID)
	end
end

---抽卡
function m.Client_Draw(_,data)
	local PlayerID,type = data.PlayerID,data.type
	if PlayerUtil.IsValidPlayer(PlayerID) and type and CanAction(PlayerID,"Draw",3)  then
		local aid = PlayerUtil.GetAccountID(PlayerID)
		http.load("card_draw",{aid=aid,mode=type},function(data)
			if data and data.success == "1" then
				if data.exp then
					PlayerUtil.SetCardExp(PlayerID,data.exp)
				end
				if data.jing then
					UpdatePlayerData(PlayerID,"jing",data.jing)
					m.UpdatePlayerDataNetTable(PlayerID)
				end
				---客户端需要抽卡结果，元素包含：name、world、own
				local items = {}
				---发往客户端更新配置界面的卡片数据，只需要包含新增的卡片即可：{worldName={cardName={exp=123}}}
				local newCards = nil
				local needSyncSetup = false;
				local needSyncAbility = false;
				if data.items then
					for _, data in pairs(data.items) do
						local name = data.name
						if data.isCard then
							local cardData = Cardmgr.GetCard(name)
							if cardData then
								local world = cardData.world
								table.insert(items,{name=name,world=world,own=data.own,quality=cardData.grade})
								
								--新增的卡片，发送到配置界面
								if not data.own or data.own < 0 then
									--更新拥有的卡片信息
									PlayerUtil.UpdateCard(PlayerID,world,name,0)
									
									--发送往客户端的数据
									if not newCards then
										newCards = {}
									end
									
									local worldData = newCards[world]
									if not worldData then
										worldData = {}
										newCards[world] = worldData
									end
									worldData[name] = {exp=0}
									
									needSyncSetup = true;
								end
							else
								DebugPrint("card data not exist for :"..name)
							end
						else
							--技能
							table.insert(items,{name=name})
							PlayerUtil.UpdateBuilderAbility(PlayerID,name)
							
							needSyncSetup = true
							needSyncAbility = true;
						end
					end
				end
				
				SendToClient(PlayerID,"custom_store_draw_result",{type=type,items=items})
				if needSyncSetup then
					if needSyncAbility then
						setup.RefreshSetupData(PlayerID,newCards,PlayerUtil.GetBuilderAbility(PlayerID))
					else
						setup.RefreshSetupData(PlayerID,newCards)
					end
				end
			end
		end)
	end
end

function m.Client_BuyItem(_,keys)
	local PlayerID,itemName,type,count = keys.PlayerID,keys.name,keys.type,keys.count
	if PlayerUtil.IsValidPlayer(PlayerID) and CanAction(PlayerID,"BuyItem",1) then
		local aid = PlayerUtil.GetAccountID(PlayerID)
		http.load("xxj_store",{aid=aid,item=itemName,count=count},function(data)
			local success = 0
			local error = nil
			if data then
				if data.success == "1" then
					local needSync = false;
					
					if data.msc then
						UpdatePlayerData(PlayerID,"magic",data.msc)
						needSync = true;
					end
					if data.soul then
						UpdatePlayerData(PlayerID,"soul",data.soul)
						needSync = true;
					end
					if data.jing then
						UpdatePlayerData(PlayerID,"jing",data.jing)
						needSync = true;
					end
					if data.point then
						UpdatePlayerData(PlayerID,"point",data.point)
						needSync = true;
					end
					if data.vip then
						UpdatePlayerData(PlayerID,"vip",data.vip)
						needSync = true;
					end
					
					if needSync then
						m.UpdatePlayerDataNetTable(PlayerID)
					end
					
					--建造者
					if type == 1 then
						PlayerUtil.AddBuilderModel(PlayerID,itemName)
					end
					--天帝宝库
					if type == 3 then
						if keys.itemType == 1 and data.exp then
							PlayerUtil.SetCardExp(PlayerID,data.exp)
						elseif keys.itemType == 2 and data.card == "1" then
							local cardInfo = Cardmgr.GetCard(itemName)
							if cardInfo then
								PlayerUtil.UpdateCard(PlayerID,cardInfo.world,itemName)
								local card = {
									[cardInfo.world]={
										[itemName]={
											exp=0
										}
									}
								}
								setup.RefreshSetupData(PlayerID,card)
							end
						elseif keys.itemType == 3 and data.ability == "1" then
							PlayerUtil.UpdateBuilderAbility(PlayerID,itemName)
							setup.RefreshSetupData(PlayerID,nil,PlayerUtil.GetBuilderAbility(PlayerID))
						end
					end
					
					success = 1;
				else
					error = data.error
				end
			end
			if type == 3 then
				SendToClient(PlayerID,"custom_store_buy_response",{type=type,success=success,item=itemName,itemType=keys.itemType,error=error})
			else
				SendToClient(PlayerID,"custom_store_buy_response",{type=type,success=success,item=itemName,error=error})
			end
		end)
	end
end

function m.Client_InitBuilder(_,data)
	local PlayerID = data.PlayerID
	if PlayerUtil.IsValidPlayer(PlayerID) then
		local cl_data = {}
		local builders = PlayerUtil.GetBuilderModel(PlayerID) or {}
		SendToClient(PlayerID,"custom_store_builder_update",builders)
	end
end


function m.Client_Refresh(_,data)
	local PlayerID = data.PlayerID
	if PlayerUtil.IsValidPlayer(PlayerID) and not PlayerUtil.getAttrByPlayer(PlayerID,"store_refresh_key") then
		UpdateAfterRecharge(PlayerID);
		PlayerUtil.setAttrByPlayer(PlayerID,"store_refresh_key",true)
		TimerUtil.createTimerWithDelay(10,function()
			PlayerUtil.setAttrByPlayer(PlayerID,"store_refresh_key",nil)
		end)
	end
end

function m.Client_GetDouble(_,data)
	local PlayerID = data.PlayerID
	if PlayerUtil.IsValidPlayer(PlayerID) then
		local aid = PlayerUtil.GetAccountID(PlayerID)
		http.load("xxdld",{aid=aid,mode="6"},function(data)
			if data and data.store then
				local pdata = data.store.player
				if pdata and pdata[aid] and pdata[aid].double == "1" then
					SendToClient(PlayerID,"custom_store_recharge_double",{})
				end
			end
		end)
	end
end


function m.registerListener()
	--玩家数据加载完毕后再向客户端同步一次，避免客户端发送过来请求的时候，数据还没加载出来
	PlayerUtil.RegisterLoadedListener(function(data)
		local storeData = data.store or {}
		local price = storeData.price or {}
		
		SetNetTableValue("custom_store","price",price)
		
		local allUserData = storeData.player or {}
		for _, PlayerID in pairs(PlayerUtil.GetAllPlayersID()) do
			local userData = allUserData[PlayerUtil.GetAccountID(PlayerID)] or {}
			PlayerData[PlayerID] = userData
			m.UpdatePlayerDataNetTable(PlayerID)
			
			--双倍福利
			if userData.double == "1" then
				SendToClient(PlayerID,"custom_store_recharge_double",{})
			end
			
			--更新建造者模型
			local builders = PlayerUtil.GetBuilderModel(PlayerID) or {}
			SendToClient(PlayerID,"custom_store_builder_update",builders)
			
			--游戏开始了发送每日奖励提示信息
			TimerUtil.createTimer(function()
				if setup.IsGameStarted() then
					--检查是否有每日奖励，如果有，给出提示
					if userData.reward then
						local reward = userData.reward
						
						if reward.vip then
							local vip = reward.vip
							if type(reward.vip.exp) == "number" and reward.vip.exp > 0 then
								NotifyUtil.ShowSysMsg(PlayerID,{"info_vip_level_reward_exp",reward.vip.exp},15);
							end
						end
						
						if reward.plus then
							local plus = reward.plus
							if type(plus.exp) == "number" and plus.exp > 0 then
								NotifyUtil.ShowSysMsg(PlayerID,{"info_privilege_card_reward_exp",plus.exp},15);
							end
							if type(plus.jing) == "number" and plus.jing > 0 then
								NotifyUtil.ShowSysMsg(PlayerID,{"info_privilege_card_reward_jing",plus.jing},15);
							end
						end
					end
					
					return 
				end
				return 1
			end)
		end
		
		--天帝宝库
		mystery = data.mystery
		if mystery then
			local exp = nil
			local cards = nil
			local abilities = nil
			for name, value in pairs(mystery) do
				if value.type == "1" then
					exp = value.ratio
				elseif value.type == "2" then
					if not cards then
						cards = {}
					end
					cards[name] = value.price
				elseif value.type == "3" then
					if not abilities then
						abilities = {}
					end
					abilities[name] = value.price
				end
			end
			
			SetNetTableValue("custom_store","mystery",{exp=exp,card=cards,ability=abilities})
		end
	end)
	
	RegisterEventListener("custom_store_player_data_update_request",m.Client_UpdatePlayerData)
	RegisterEventListener("custom_store_builder_init_request",m.Client_InitBuilder)
	RegisterEventListener("custom_store_recharge_request",m.Client_Recharge)
	RegisterEventListener("custom_store_recharge_cancel_order_request",m.Client_CancelOrder)
	RegisterEventListener("custom_store_draw_request",m.Client_Draw)
	RegisterEventListener("custom_store_buy_request",m.Client_BuyItem)
	RegisterEventListener("custom_store_refresh_request",m.Client_Refresh)
	RegisterEventListener("custom_store_recharge_double_request",m.Client_GetDouble)
end

m.registerListener()
return m;