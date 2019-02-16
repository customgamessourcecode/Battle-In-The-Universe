local listenerInited = false

--塔创建监听。当塔被创建以后，检查是否使用过丹宝的丹药，如果用过了，再次添加物品和属性
local towerCreated = function(tower)
	local used = Towermgr.GetTowerKV(tower,"danbao_dy_used")
	if used then
		for itemName, data in pairs(used) do
			if data.modifier and data.count then
				--创建一个物品，不添加到单位身上了，避免单位身上没有位置。但是要设置拥有者，这样单位死亡的时候才会销毁
				local item = CreateItem(itemName, tower, tower)
				AddDataDrivenModifier(item,tower,tower,data.modifier,{})
				local modifier = tower:FindModifierByName(data.modifier)
				if modifier then
					modifier:SetStackCount(data.count)
				end
			end
		end
	end
end

---丹宝炼制的丹药使用，增加属性
--keys:
--modifier:要增加的buff名字
--max:最大使用次数
function danbao_dy_used(keys)
	local item = keys.ability
	local caster = keys.caster
	local modifierName = keys.modifier
	local max = keys.max
	
	if not listenerInited then
		Towermgr.RegisterTowerCreatedListener(towerCreated)
		listenerInited = true
	end
	
	if modifierName then
		local modifier = caster:FindModifierByName(modifierName)
		if not modifier then
			AddDataDrivenModifier(item,caster,caster,modifierName,{})
			modifier = caster:FindModifierByName(modifierName)
		end
		
		if max and modifier then
			if modifier:GetStackCount() == max then
				NotifyUtil.BottomUnique(PlayerUtil.GetOwnerID(caster),"ability_danbao_dy_used_max",3,"yellow")
				return 
			end
		
			modifier:IncrementStackCount()
			---记录使用过丹药数量，取回重新放置的时候再使用
			local used = Towermgr.GetTowerKV(caster,"danbao_dy_used")
			if not used then
				used = {}
				Towermgr.SetTowerKV(caster,"danbao_dy_used",used)
			end
			local itemName = item:GetAbilityName()
			local data = used[itemName]
			if not data then
				data = {}
				data.modifier = modifierName
				used[itemName] = data
			end
			data.count = (data.count or 0) + 1
			
			if modifier:GetStackCount() == 1 then
				--第一次使用，隐藏掉物品，不能直接删除，否则buff图标会消失。但是貌似仍然能作用。
				--这里隐藏物品，但是由于物品是可叠加的，要判断初始物品叠加数量是否超过了1，如果是的话，再添加一个物品，并设置叠加数量
				--这样后续就可以删除物品而不会出错了
				caster:TakeItem(item)
				if item:GetCurrentCharges() > 1 then
					local charge = item:GetCurrentCharges() - 1
					local item = ItemUtil.AddItem(caster,itemName,true)
					item:SetCurrentCharges(charge)
				end
			else
				if item:GetCurrentCharges() == 1 then
					--第二次及以后使用，删掉物品即可
					EntityHelper.remove(item)
				else
					item:SetCurrentCharges(item:GetCurrentCharges() - 1)
				end
			end
		end
	end
end