---
--★★★★★★★★!!!重要：关于防守塔技能等级的说明!!!★★★★★★★★★
--
--防守塔单位升级后，dota会自动升级所有的技能(只要该技能没有达到最大等级)
--这里可能就会出现问题
--1.比如某个单位使用了onUPgrade事件，就会导致这里触发了，但是可能实际现在并不能升级该技能（等级不符等），就会出现错误。
--2.某些技能buff是被动的，但是需要单位达到特定等级才能生效，但是因为技能被自动升级，导致这个buff直接就被加上了
--3.其他无法确定的问题
--
--为了解决这些问题，将【【【所有技能的KV最大等级默认都设置为0，如果必须要最大等级，通过键值设置】】】，
--然后使用自定义的技能升级逻辑，即下面的setTowerAbilityLevel
--这样默认dota在单位升级的时候就不会给技能升级了，只有达到条件后才会由自定义的逻辑去升级
--
--同时，以下KV属性不能通过kv直接设置，需要通过键值（=后面就是键值中的key，value是数字）设置：
--1.最大等级 = maxLevel 。默认和单位等级相同
--2.初学等级 = requireLevel。只有单位达到该等级才会学习该技能。默认是1
--3.升级间隔 = betweenLevel。比如1,3,5这种，学习间隔就是2。默认是1
--
-- ****************** 塔物品说明 ****************
--	如果塔有存在数量的话，则在塔对应的人物卡物品中添加键值：existLimit（存在上限，同时创建的单位不能超过存在上限）即可
local m = {}
---各品质卡片的等级上限
local gradeMax = {
	[1] = 3,
	[2] = 6,
	[3] = 6,
	[4] = 9,
	[5] = 9
}

---各个vip等级对应的升级花费优惠
local vipReduce = {
	[1] = 0.01,[2] = 0.02,[3] = 0.03,[4] = 0.04,[5] = 0.05,
	[6] = 0.06,[7] = 0.07,[8] = 0.08,[9] = 0.09,[10] = 0.1,
}

---塔被创建的监听，某些特殊逻辑里面要用到
local listeners = {}

---每个玩家当前拥有的塔单位
--key是玩家id，value是一个表{entindex=entity,...}
local playerTowers = {}
--记录玩家存在的所有塔
local function addTower(PlayerID,tower)
	local towers = playerTowers[PlayerID]
	if not towers then
		towers = {}
		playerTowers[PlayerID] = towers
	end
	local index = tower:entindex()
	if not towers[index] then
		towers[index] = tower
	end
end
--移除一个玩家的塔
local function removeTower(PlayerID,towerIndex)
	local towers = playerTowers[PlayerID]
	if towers and towers[towerIndex] then
		towers[towerIndex] = nil
	end
end

---获取某个玩家当前创建的指定塔数量
local GetTowerCountByName = function(PlayerID,towerName)
	local count = 0
	local towers = playerTowers[PlayerID]
	if towers then
		for key, entity in pairs(towers) do
			if EntityIsAlive(entity) and entity:GetUnitName() == towerName then
				count = count + 1;
			end
		end
	end
	towers = nil
	return count
end

---玩家人口信息,key是玩家id，value{now=123（当前已用人口）,max=333（人口上限），limitExtra=123（最大人口数量额外提升的数量，某些技能会提高最大人口数量，比如唐心莲的技能）}
local populations = {}
---最大人口数量。人口上限可以通过购买物品增加，最多不超过这个值
local populationLimit = 20


---塔创建成功以后（动画播放完毕），恢复各种属性
local AfterCreated = function(tower,sourceItem,modelScale,upgrade)
	tower:SetHealth(tower:GetMaxHealth())
	tower:SetModelScale(modelScale)
	tower:RemoveModifierByName("td_modifier_tower_building")
 	
 	if TD_GMAE_MODE_TEST then
 		local card = Cardmgr.GetCard(tower:GetUnitName())
		if card and card.grade then
			m.ResetTowerLevel(tower,gradeMax[card.grade])
		end
 	else
 		--建造完成，升级。解决有些技能需要塔完成创建才能生效的问题
		if sourceItem._towerLevel and sourceItem._towerLevel > 1 then
			m.ResetTowerLevel(tower,sourceItem._towerLevel)
		else
			m.setTowerAbilityLevel(tower)
		end
 	end
	
	
	m.ShowTowerHeader(tower)
	
	--设置魔法值，放在单位升级之后，单位升级的话会填满魔法值
	tower:SetMana(sourceItem._RestMana or 0)
	sourceItem._RestMana = nil
	
	
	--设置升级技能的等级（这里怕直接写死第一个技能以后有问题，所以稍微遍历一下）
	if tower:GetLevel() > 1 then
		for index=0, 12 do
			local ability = tower:GetAbilityByIndex(index)
			if ability and string.find(ability:GetAbilityName(),"tower_levelup_") > 0 then
				ability:SetLevel(tower:GetLevel())
				break;
			end
		end
	end
	
	--技能冷却时间
	if sourceItem._abilities then
		for abilityName, cooldown in pairs(sourceItem._abilities) do
			local ability = tower:FindAbilityByName(abilityName)
			if ability then
				ability:StartCooldown(cooldown)
			end
		end
		--清空掉
		sourceItem._abilities = nil
	end
	
	--额外添加一个禁用AI的技能
	local ai = tower._ai
	if ai then
		ai.disabled = sourceItem._disableAI
		if ai.disabled then
			local ability = tower:AddAbility("tower_disable_ai");
			ability:SetLevel(1)
		else
			local ability = tower:AddAbility("tower_enable_ai");
			ability:SetLevel(1)
		end
	end
	
	--添加塔的物品
	if sourceItem._items then
		for key, item in pairs(sourceItem._items) do
			tower:AddItem(item)
		end
		--交换到之前的位置上
		for slot=8, 0,-1 do
			local item = tower:GetItemInSlot(slot)
			if item ~= nil and item.slot and item.slot ~= slot then
				tower:SwapItems(slot,item.slot)
			end
		end
		--清空掉
		sourceItem._items = nil
	end
	
	--加上这个标记才表示真正建造完成了
	AddLuaModifier(nil,tower,"td_modifier_tower",{})
	--记录释放过的技能的modifier
	AddLuaModifier(nil,tower,"td_modifier_unit_ability_recorder",{})
	
	---触发监听
	if #listeners > 0 then
		for _, listener in pairs(listeners) do
			local status,err = pcall(listener,tower)
			if not status then
				DebugPrint(err)
			end
		end
	end

end

---创建塔
--@param #handle owner 塔所属的英雄
--@param #handle sourceItem 创建塔使用的物品。会在该物品存储以下信息：
--<ul>
--	<li>_towerOwner：塔的拥有者。塔是可共享的，但是人物卡第一次使用的时候是谁创建的，就归属谁。</li>
--	<li>_towerName：塔单位名字</li>
--	<li>_towerLevel：塔的等级，在塔升级的时候更新</li>
--	<li>_goldcost：塔升级消耗的金币，在塔升级的时候更新</li>
--	<li>_items：塔佩戴的物品，在收回塔的时候记录</li>
--	<li>_abilities：记录了各个技能的冷却时间，收回塔时记录</li>
--	<li>_disableAI：是否禁用了自动施法，收回塔时记录</li>
--	<li>_RestMana：塔被收起的时候，剩余的魔法值，收回塔时记录</li>
--	<li>_tmgr_cached_kv：其他功能记录在该塔上的数据，和塔实体中的一致，收回塔的时候记录</li>
--</ul>
--@param #string towerName 塔对应的单位名字。会在创建好的塔单位实体中存储以下信息：
--<ul>
--	<li>_source：对应上边的sourceItem实体</li>
--	<li>_tmgr_cached_kv：用来记录其他模块需要记录的信息。在塔收回的时候记录，重新放置的时候添加进去。
--	以保证某些逻辑（比如某些技能会累计攻击力，收回再放出要保留之前累计的），用GetTowerKV和SetTowerKV来操作</li>
--</ul>
--@param #vector postion 出生点
--@param #boolean immediately 立刻创建，不播放动画。主要用在升级的时候。
--由于默认的creature升级逻辑有问题，导致某些modifier的效果会在升级的时候叠加，
--比如回蓝，但是在第一次创建单位的时候升级却不会出现这种效果，不知道为什么。
--所以将升级的逻辑做成销毁重新生成，这个时候就不播放渐变的过程了。如果immediately为true，则成功创建后，返回创建的塔对象
function m.create(owner,sourceItem,towerName,postion,upgrade)
	local PlayerID = PlayerUtil.GetOwnerID(owner)
	local owner = PlayerUtil.GetHero(PlayerID)--保证无论外部传进来的是啥，这里都把塔的拥有者定为玩家操作的英雄
	
	---拥有人发生变化，则不可使用
	if sourceItem._towerOwner and owner ~= sourceItem._towerOwner then
		NotifyUtil.ShowError(PlayerID,"error_card_has_been_upgrade_by_other",3)
		return;
	end
	
	local population = populations[PlayerID]
	--初始化人口
	if not population then
		population = m.InitPopulation(PlayerID)
	end
	
	if population.now == population.max then
		NotifyUtil.ShowError(PlayerID,"#error_population_reached_max",2)
		return;
	end
	
	--判断数量是否达到上限
	local existLimit = GetAbilitySpecialValueByLevel(sourceItem,"existLimit")
	if not TD_GMAE_MODE_TEST and existLimit > 0 then
		local count = GetTowerCountByName(PlayerID,towerName)
		if count >= existLimit then
			NotifyUtil.ShowError(PlayerID,"#error_tower_exist_reached_limit",3)
			return;
		end
	end

	local tower = CreateUnitEX(towerName,postion,true,owner)
	if tower then
		--记录拥有者
		sourceItem._towerOwner = owner
		
		tower.TD_IsTower = true
	
		addTower(PlayerUtil.GetOwnerID(owner),tower)
		--更新人口
		m.AddPopulationNow(PlayerID,1)
		
		--AI
		BaseAI:MakeInstance(tower)
		
		sourceItem._towerName = towerName
		tower._source = sourceItem
		---塔的缓存kv，要在设置技能等级之前，避免技能中找不到
		tower._tmgr_cached_kv = sourceItem._tmgr_cached_kv	
		
		owner:TakeItem(sourceItem)
		AddLuaModifier(nil,tower,"td_modifier_tower_building",{})
		
		--是否可以进行控制，如果不可被控制，则即便能选中，也不能移动、操作。并且该单位攻击的话不显示伤害
		tower:SetControllableByPlayer(PlayerUtil.GetOwnerID(owner),true)
		--塔占位60
		tower:SetHullRadius(60)
		--设置基础血量和基础模型大小，用来模拟“动态”效果
		tower:SetHealth(1)
		--并不是所有单位的模型大小都是默认为1的，所以这里要特殊处理一下
		local modelScale = tower:GetModelScale()
		tower:SetModelScale(0.1 * modelScale)
		--1秒建造完毕
		local count = 1
		
		if upgrade then
			AfterCreated(tower,sourceItem,modelScale,upgrade)
			return tower
		else
			TimerUtil.createTimer(function()
				if tower:GetHealth() < tower:GetMaxHealth() then
					tower:SetHealth(tower:GetMaxHealth() * 0.1 * count)
					tower:SetModelScale(0.1 * count * modelScale)
					count = count + 1
					return 0.1
				else
					AfterCreated(tower,sourceItem,modelScale)
				end
			end)
		end
	else
		DebugPrint("create tower faild!!!!",towerName)
	end
end

---<font color="red">塔在被重新放置的时候</font>，设置其等级和技能等级
function m.ResetTowerLevel(tower,targetLevel)
	---单位升级
	tower:CreatureLevelUp(targetLevel - tower:GetLevel())
	--在塔对应的物品上记录塔的等级
	if tower._source then
		tower._source._towerLevel = tower:GetLevel()
	end
	
	m.setTowerAbilityLevel(tower)
end

---判断塔是否可以升级：没有达到该塔所属级别的最大等级
function m.canUpgrade(tower)
	if tower and tower:IsCreature() then
		local card = Cardmgr.GetCard(tower:GetUnitName())
		if card and card.grade then
			local max = gradeMax[card.grade]
			if max then
				if tower:GetLevel() < max then
					return true;
				else
					NotifyUtil.ShowError(PlayerUtil.GetOwnerID(tower),"#error_tower_upgrade_maxed",2)
				end
			else
				DebugPrint("tower "..tower:GetUnitName().." Grade Invalid,can't find MAX Level.grade is:")
			end
		end
	end
	return false
end

---升级塔。
--@param #handle tower 塔单位
--@param #number goldCost 花费的金币，可以为空
--@return #boolean 是否升级成功
--@return #handle tower，如果成功了返回升级后的塔实体。主要是因为目前升级后塔实体发生了变化。后续如果dota接口修复了就不需要这个了
function m.upgrade(tower,goldCost)
	if m.canUpgrade(tower) then
		local PlayerID = PlayerUtil.GetOwnerID(tower)
		local sourceItem = tower._source
		--消耗金币
		if goldCost then
			--vip优惠
			local vipLevel = Store.GetVipLevel(PlayerID)
			if vipLevel and vipLevel > 0 then
				goldCost = goldCost * (1 - (vipReduce[vipLevel] or 0))
			end
		
			if PlayerUtil.GetGold(PlayerID) >= goldCost then
				PlayerUtil.SpendGold(PlayerID,goldCost)
			else
				NotifyUtil.ShowError(PlayerID,"#error_need_more_gold",3)
				return false
			end
		end
		
		local targetLevel = tower:GetLevel() + 1
		
		local status,err = pcall(function()
			--单位升级，蓝量不回满。这个升级单位会导致某些特殊buff效果升级叠加0
			--比如回蓝装备，本身只提供0.5回蓝，但是戴上该装备升级单位，会变成+1回蓝，并且取下装备也不会降低了
			--应该是把这个回蓝也算进基础里面计算了。
--			local manaPercent = tower:GetManaPercent()
--			tower:CreatureLevelUp(1)
--			tower:SetMana(tower:GetMaxMana() * manaPercent / 100)
--			m.setTowerAbilityLevel(tower)
			
			local towerName = tower:GetUnitName()
			local pos = tower:GetAbsOrigin()
			local hero = PlayerUtil.GetHero(PlayerID)
			local dps = tower.dps_total_damage
			--提升等级
			sourceItem._towerLevel = targetLevel
			--先销毁，再原位置创建
			m.destroy(tower,hero,true)
			tower = m.create(hero,sourceItem,towerName,pos,true)
			if tower then
				tower.dps_total_damage = dps
			end
		end)
		
		if status then
			if sourceItem then
				--记录金币消耗
				if goldCost then
					sourceItem._goldcost = (sourceItem._goldcost or 0) + goldCost
				end
			end
			return true,tower
		else
			if sourceItem then
				--记录等级
				sourceItem._towerLevel = targetLevel - 1
			end
			--退还金币
			if goldCost then
				PlayerUtil.AddGold(PlayerID,goldCost)
			end
		end
	end
end

---根据塔的等级设置技能等级。塔等级相关信息，查看最上边的说明
--ability:SetLevel()会触发技能的onUpgrade事件，无论设置的是多少级（降级也触发）
function m.setTowerAbilityLevel(tower)
	---塔被收回重建的时候，使用销毁--创建的流程，这种情况下，buff类的光环并不会立刻消失，当整个过程比较短的时候，
	--新创建出来的单位在升级技能后不能添加新等级的buff效果（由于之前的已经存在了，不能同时存在），
	--这就导致之前的buff效果也保留的是旧等级的（因为之前的单位已经死了，无法获取新等级了），会出现各种问题。
	--所以这里稍微延迟一下，光环的buff实际上是每0.5秒刷新一次的。所以这里延迟0.5即可
	TimerUtil.createTimerWithDelay(0.5,function()
		--避免放下后立刻收回，还会设置技能的问题
		if not EntityIsAlive(tower) then
			return;
		end
	
		local towerLevel = tower:GetLevel()
		--设置技能等级
		for index=0, tower:GetAbilityCount() - 1 do
			local ability = tower:GetAbilityByIndex(index)
			--可以学习的才升级
			if ability and not BitAndTest(GetAbilityBehaviorNum(ability),DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE) then
				
				local abilityLevel = ability:GetLevel()
				--最大等级，如果没有设置的话，一般不会有问题，因为塔的等级有上限，所以不会出现无限升级的情况。
				--但是有可能跟实际想要的maxLevel不一致。比如某个技能最多只能有1级。这种情况下就要专门设置maxLevel了
				local maxLevel = GetAbilitySpecialValueByLevel(ability,"maxLevel",1)
				if not maxLevel or maxLevel <= 0 or abilityLevel < maxLevel then
					---由于所有塔都是creature，ability的GetHeroLevelRequiredToUpgrade不能正常获取到kv中设置的需求等级
					--所以用键值来实现。这里要获取1级的效果，因为这个技能默认是0级，不指定等级的话键值总会返回0
					local requireLevel = GetAbilitySpecialValueByLevel(ability,"requireLevel",1)
					if requireLevel == 0 then
						requireLevel = 1
					end
					--没有接口可以获取间隔，从键值获取
					local betweenLevel = GetAbilitySpecialValueByLevel(ability,"betweenLevel",1)
					if betweenLevel == 0 then
						betweenLevel = 1
					end
					
					local targetLevel = 0
					if towerLevel >= requireLevel then
						targetLevel = 1 + math.floor((towerLevel - requireLevel) / betweenLevel)
					end
					
					if abilityLevel ~= targetLevel then
						ability:SetLevel(targetLevel)
					end
				end
			end
		end
	
	end)
end

---收回塔。
--@param #handle tower 塔实体
--@param #handle caster 回收人
--@param #boolean upgrade 立刻创建，不播放动画。主要用在升级的时候。
--由于默认的creature升级逻辑有问题，导致某些modifier的效果会在升级的时候叠加，
--比如回蓝，但是在第一次创建单位的时候升级却不会出现这种效果，不知道为什么。
--所以将升级的逻辑做成销毁重新生成，这个时候就不播放渐变的过程了。
function m.destroy(tower,caster,upgrade)
	if tower and tower._source then
		local ownerPlayer = PlayerUtil.GetOwnerID(tower)
		
		if not upgrade then
			if ownerPlayer ~= PlayerUtil.GetOwnerID(caster) then
				NotifyUtil.ShowError(PlayerUtil.GetOwnerID(caster),"#error_cannot_takeback_tower_not_owner",3)
				return;
			end
			if tower:HasModifier("td_modifier_tower_building") then
				NotifyUtil.ShowError(PlayerUtil.GetOwnerID(caster),"#error_cannot_takeback_tower_building",3)
				return;
			end
			
			--特效
			local path = "particles/units/heroes/hero_chen/chen_teleport_flash.vpcf"
			CreateParticleEx(path,PATTACH_ABSORIGIN,tower)
		end
		
		local sourceItem = tower._source
		
		--记录塔的物品
		local items = {}
		for slot=0, 8 do
			local item = tower:GetItemInSlot(slot)
			if EntityNotNull(item) then
				item.slot = slot
				tower:TakeItem(item)
				table.insert(items,item)
			end
		end
		if #items > 0 then
			sourceItem._items = items
		end
		
		--技能冷却时间
		local abilities = {}
		local exist = false;
		for index=0, tower:GetAbilityCount() - 1 do
			local ability = tower:GetAbilityByIndex(index)
			if ability and ability:GetCooldownTimeRemaining() > 0 then
				abilities[ability:GetAbilityName()] = ability:GetCooldownTimeRemaining()
				exist = true;
			end
		end
		if exist then
			sourceItem._abilities = abilities
		end
		
		--ai禁用状态
		local ai = tower._ai
		if ai then
			sourceItem._disableAI = ai.disabled
		end
		
		--蓝量
		if tower:GetMana() > 0 then
			sourceItem._RestMana = tower:GetMana()
		end
		
		local towerIndex = tower:entindex()
		---有些技能需要用到单位的死亡事件，如果直接用实体的移除，就进不去死亡事件了，这里改用杀死的逻辑
		--但是杀死单位后，单位模型仍然会存在一段事件，才渐渐消失，比较僵硬。所以先将模型大小设置为0，然后再杀死单位
		--同时为了显示上边的特效，不能使用AddNoDraw
		if not upgrade then
			tower:SetModelScale(0)
			tower:ForceKill(false)--kill以后并不会立刻变成null，会经过一个短暂延迟，应该是处理后续的逻辑的
		else
			EntityHelper.kill(tower,true)
		end
		removeTower(ownerPlayer,towerIndex)
		
		--缓存数据。放在杀死后面去缓存。有些技能逻辑缓存数据是在单位死亡的时候触发的，所以把这个缓存逻辑放在死亡后面。
		--由于死亡后lua对象并不会清空，所以这样也没有毛病
		sourceItem._tmgr_cached_kv = tower._tmgr_cached_kv
		
		--更新人口数量
		m.AddPopulationNow(ownerPlayer,-1)
		
		--添加物品给玩家，身上没位置了就掉地上
		if not upgrade then
			ItemUtil.AddItem(caster,sourceItem,true)
		end
	end
end

---获取某个玩家所有在建的塔
--@param #any PlayerID 该玩家拥有的单位实体或者玩家id，entity有可能为空
--@return #table {entindex=entity,...}
function m.getPlayerTowers(PlayerID)
	if type(PlayerID) == "table" then
		PlayerID = PlayerUtil.GetOwnerID(PlayerID)
	end
	if PlayerID then
		return playerTowers[PlayerID]
	end
end

---移除单位创建的某个塔实体（主要用在诸如唐心莲这种塔和对应物品都被删除的情况）<br>
--只是清空对应的缓存表，并不涉及到人口变化以及单位实体的删除
function m.RemovePlayerTower(PlayerID,towerIndex)
	if PlayerID and towerIndex then
		removeTower(PlayerID,towerIndex)
	end
end

---初始化玩家的人口，只有第一次调用生效。
--<br/>玩家初始人口上限是10个，可以通过购买物品增加。
--@return #table 返回玩家人口信息
function m.InitPopulation(PlayerID)
	if not populations[PlayerID] then
		local t = {now=0,max=10,limitExtra=0}
		if TD_GMAE_MODE_TEST then
			t.max = 999999
		end
		populations[PlayerID] = t
		return t;
	end
end

---向客户端同步玩家的人口信息，没有的话，不同步
function m.UpdatePopulation(PlayerID)
	local population = populations[PlayerID]
	if population then
		SendToClient(PlayerID,"ingame_status_polupation_update",population)
	end
end

---增加当前人口数量
--@param #number PlayerID 玩家id
--@param #number count 要增加的数量。可以是负数
function m.AddPopulationNow(PlayerID,count)
	if PlayerID and count then
		local population = populations[PlayerID]
		if population then
			population.now = population.now + count
			m.UpdatePopulation(PlayerID)
		end
	end
end

---给某个玩家增加人口上限
--@return #boolean 返回是否增加成功
function m.AddPopulationMax(PlayerID)
	local population = populations[PlayerID]
	if population and population.max < populationLimit + population.limitExtra then
		population.max = population.max + 1
		m.UpdatePopulation(PlayerID)
		return true;
	end
end

---获取某个玩家的人口上限
--@return #number 当前最大人口数量
--@return #boolean 是否可以继续增加
function m.GetPopulationMax(PlayerID)
	local population = populations[PlayerID]
	if population then
		--当前人口上限要减少额外提升的。否则升级的时候消耗的金币会增加
		return population.max - population.limitExtra,population.max < populationLimit + population.limitExtra;
	end
end

---永久增加最大人口数量。默认情况下最大只能有20个人口。有些特殊技能可以提高这个上限。
function m.AddPopulationLimit(PlayerID,limit)
	local population = populations[PlayerID]
	if population then
		population.limitExtra = population.limitExtra + limit
	end
end

---开启同步dps的计时器
function m.StartSyncDPS(PlayerID)
	local timer = PlayerUtil.getAttrByPlayer(PlayerID,"sync_dps_timer_created")
	if not timer then
		TimerUtil.createTimer(function()
			--排序后的结果。在服务端就直接排好序。不知道会不会有压力。
			local sorted = {}
			local towers = m.getPlayerTowers(PlayerID)
			if towers then
				for entityIndex, tower in pairs(towers) do
					if EntityIsAlive(tower) then
						local damage = tower.dps_total_damage or 0
						local data = {index=entityIndex,damage=damage,name=tower:GetUnitName()}
						
						if #sorted == 0 then
							table.insert(sorted,data)
						else
							local findPos = false;
							for index, towerDamage in pairs(sorted) do
								if damage > towerDamage.damage then
									table.insert(sorted,index,data)
									findPos = true;
									break;
								elseif damage == towerDamage.damage then
									--伤害相等的时候，比较单位名字，谁的名字小，谁在前（相等的时候就无所谓啦。。。。）
									--这里没有判断此时towerDamage对应的单位是否还存在，那样太麻烦了。到客户端判断就行了，如果不存在了不显示就行
									--所以为了能够获取towerDamage对应的单位名字，在上边要缓存起来，避免这个时候没有了
									if tower:GetUnitName() <= towerDamage.name then
										table.insert(sorted,index,data)
									else --名字大排后面
										table.insert(sorted,index + 1,data)
									end
									findPos = true;
									break;
								end
							end
							--最小的排在最后
							if not findPos then
								table.insert(sorted,data)
							end
						end
					end
				end
			end
			
			--只取前十
			local netdata = {}
			for key, data in pairs(sorted) do
				netdata[data.index] = data.damage
				if key == 10 then
					break;
				end
			end
			
--			--使用netTable存储，这样在观战模式下也可以看
--			SetNetTableValue("dps",tostring(PlayerID),netdata)
			SendToClient(PlayerID,"ingame_sync_dps",netdata)
			
			--每隔2秒同步一次
			return 2;
		end)
		PlayerUtil.setAttrByPlayer(PlayerID,"sync_dps_timer_created",true)
	end
end

---清空所有塔上缓存的伤害。在波次刷新等情况下调用
function m.ClearTowerDamageRecord()
	for PlayerID, towers in pairs(playerTowers) do
		for index, tower in pairs(towers) do
			tower.dps_total_damage = 0
		end
	end
end

---在塔上记录一些数据，在收回塔的时候会保留这些数据，再次创建的时候会重新设置
--@param #handle tower 塔单位实体，不可为空
--@param #string key 要保存的数据key，不可为空，要保证唯一，重复设置会覆盖
--@param #string value 要保存的值，可以为空
function m.SetTowerKV(tower,key,value)
	if tower and key then
		local data = tower._tmgr_cached_kv
		if not data then
			data = {}
			tower._tmgr_cached_kv = data
		end
		
		data[key] = value
	end
end

---获取记录在塔中的缓存数据
function m.GetTowerKV(tower,key)
	if tower and key then
		local data = tower._tmgr_cached_kv
		if data then
			return data[key]
		end
	end
end

---清空一个玩家的所有塔实体。这个会删除实体，并且不记录任何信息。主要用在玩家彻底断开连接或失败的情况下
function m.ClearPlayerTower(PlayerID)
	local towers = playerTowers[PlayerID]
	if towers then
		for entityIndex, tower in pairs(towers) do
			EntityHelper.kill(tower,true)
		end
		playerTowers[PlayerID] = nil
	end
end

---添加创建塔的监听，任意一个塔被创建了都会执行该监听。该监听在单位完全成长起来，并且设置完等级、技能冷却、物品等信息以后才会被调用
--@param #function func 监听逻辑，调用的时候会传入tower实体
function m.RegisterTowerCreatedListener(func)
	if type(func) == "function" then
		table.insert(listeners,func)
	end
end


function m.Client_RequestUpdatePopulation(_,keys)
	local PlayerID = keys.PlayerID
	if not PlayerUtil.IsValidPlayer(PlayerID) then
		return;
	end
	
	local population = populations[PlayerID]
	if not population then
		population = m.InitPopulation(PlayerID)
	end
	SendToClient(PlayerID,"ingame_status_polupation_update",population)
end

function m.ShowTowerHeader(tower)
--	if EntityIsAlive(tower) then
--		local card = Cardmgr.GetCard(tower:GetUnitName())
--		local max = ""
--		local maxNum = 0;
--		if card and card.grade and gradeMax[card.grade] then
--			max = "/"..tostring(gradeMax[card.grade])
--			maxNum = gradeMax[card.grade]
--		end
--		if maxNum > 0 and tower:GetLevel() == maxNum then
--			tower:SetCustomHealthLabel("Lv.MAX",124,252,0)
--		else
--			tower:SetCustomHealthLabel("Lv."..tostring(tower:GetLevel())..max,124,252,0)
--		end
--		local cardData = Cardmgr.GetCard(tower:GetUnitName())
--		
--		local data = {}
--		if cardData then
--			data.quality = cardData.grade
--			data.unit = tower:entindex()
--		end
--		
--		WorldPanels:CreateWorldPanelForAll(
--		{
--			layout = "file://{resources}/layout/custom_game/ingame/header/header.xml",
--			entity = tower,
--			data = data
--		})
--	end
end


local init = function()
	RegisterEventListener("ingame_status_polupation_update_request",m.Client_RequestUpdatePopulation)
end

init()
return m