local m = {}

function m.Init(mode,context)
	--mode:SetModifierGainedFilter(Dynamic_Wrap(self, 'ModifierGainedFilter'),self)
	mode:SetDamageFilter(Dynamic_Wrap(m, 'DamageFilter'),context)
	mode:SetExecuteOrderFilter(Dynamic_Wrap(m, 'ExecuteOrderFilter'),context)
	mode:SetModifyExperienceFilter(Dynamic_Wrap(m, 'ExperienceFilter'),context)
	mode:SetModifyGoldFilter(Dynamic_Wrap(m, 'GoldFilter'),context)
end

---伤害过滤。单位的kill也是执行的伤害的逻辑，damage_type是0。
--如果是用NPC接口里的Kill(ability,attacker)的话会有伤害值；如果是NPC中的ForceKill，伤害值为0
--damage: 45.714286804199	(number)
--damagetype_const: 1	(number)
--entindex_attacker_const: 510	(number)
--entindex_victim_const: 395	(number)
--entindex_inflictor_const  (string): 388  (number) --伤害来源，可能是技能或者单位。没找到出现的规律。。。有时候杀死单位才有，有时候造成伤害就有。。。。
function m:DamageFilter(keys)
	local attacker = EntityHelper.findEntityByIndex(keys.entindex_attacker_const)
	local victim = EntityHelper.findEntityByIndex(keys.entindex_victim_const)
	
	--自杀的不处理
	if not attacker or not victim or attacker == victim then
		return true;
	end
	
	local originDamage = keys.damage
	local realDamage = originDamage
	
	---杀死单位也走的这个逻辑，由于很多虚拟单位和幻象都是用的击杀，这里就只考虑敌方单位受到伤害的处理
	if victim:GetTeamNumber() == TEAM_ENEMY then
		---只有物理伤害类的才进行削弱。一般技能都是物理类型的，物理攻击也是物理的。
		--这样改主要是因为【杀死单位也走的是这个伤害逻辑】，只是伤害类型是0，但是并不能保证这种就是击杀。
		--所以干脆只削弱物理伤害就行了，这样保证没啥问题。
		if keys.damagetype_const == DAMAGE_TYPE_PHYSICAL then
			realDamage = Elements.calculate(originDamage,attacker,victim)
			
			--无尽减伤
			if victim._infinite_real_damage_ratio then
				realDamage = realDamage * victim._infinite_real_damage_ratio
			end
		end
		
		---记录塔造成的伤害
		if attacker.TD_IsTower then
			--塔
			attacker.dps_total_damage = (attacker.dps_total_damage or 0) + realDamage
		elseif attacker:GetOwner() and attacker:GetOwner().TD_IsTower then
			--塔召唤出来的单位
			local tower = attacker:GetOwner()
			tower.dps_total_damage = (tower.dps_total_damage or 0) + realDamage
		end
	end
	
	keys.damage = realDamage
	return true;
end

--[[
duration: 1.5	(number)
entindex_caster_const: 142	(number)
entindex_parent_const: 446	(number)
name_const: modifier_stunned	(string)
]]--
function m:ModifierGainedFilter(keys)
	--CDOTA_BaseNPC:Purge( bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions )
end

--[[
entindex_ability  (string): 148  (number)
entindex_target  (string): 0  (number)
issuer_player_id_const  (string): 0  (number)
order_type  (string): 17  (number)
position_x  (string): 0  (number)
position_y  (string): 0  (number)
position_z  (string): 0  (number)
queue  (string): 0  (number)
sequence_number_const  (string): 2  (number)
units  (string):
		0  (string): 120  (number)
]]--
function m:ExecuteOrderFilter(keys)
	local PlayerID = keys.issuer_player_id_const
	--出售物品的时候，判断是不是塔，如果是的话，判断塔的等级和物品。升级过的返还升级的金币，有物品的，物品扔在单位脚下
	if keys.order_type == DOTA_UNIT_ORDER_SELL_ITEM then
		local hero = PlayerUtil.GetHero(PlayerID)
		if not EntityIsAlive(hero) then
			return false;
		end
	
		local item = EntityHelper.findEntityByIndex(keys.entindex_ability)
		if item then
			--塔类单位，被别人创建了的，不允许出售
			if item._towerOwner and item._towerOwner ~= PlayerUtil.GetHero(PlayerID) then
				NotifyUtil.ShowSysMsg(PlayerID,"error_card_has_been_upgrade_by_other",3)
				return false;
			end
			
			--物品拥有者死亡了就不增加金币了
			local owner = item:GetPurchaser()
			if EntityIsAlive(owner) then
				--出售物品增加金币
				local gold = item:GetCost()
	--			--使用kv中设置的价格进行出售。否则对于合成的物品，上边的cost会是合成累计价格
	--			local gold = GetItemCost(item:GetAbilityName())
				if gold > 0 then
					--可叠加物品金币也累加
					if item:GetCurrentCharges() > 0 then
						gold = gold * item:GetCurrentCharges()
					end
				
					if GameRules:GetGameTime() - item:GetPurchaseTime() > 10 then
						PlayerUtil.AddGold(PlayerID,math.ceil(gold / 2))
					else
						PlayerUtil.AddGold(PlayerID,gold)
					end
				end
				
				---有这个属性代表是塔，并且已经创建过了，返还升级金币、处理塔身上的物品
				if item._towerName then
					local towerName = item._towerName
					--返还金币，根据不同难度，返回率逐渐降低
					if item._goldcost and item._goldcost > 0 then
						local goldcost = item._goldcost
						local ratio = 0.6
						if GetTDDifficulty() >= 2 then
							ratio = 0.2
						end
						if ratio > 0 then
							goldcost = math.ceil(goldcost * ratio)
							PlayerUtil.AddGold(PlayerID,goldcost)
							NotifyUtil.ShowSysMsg(PlayerID,{"#info_tower_sold_hint_lvlup_cost","("..tostring(goldcost)..")"},3)
						end
						
					end
					--物品扔在脚下
					if item._items then
						local hero = PlayerUtil.GetHero(PlayerID)
						for _, bodyItem in pairs(item._items) do
							ItemUtil.CreateItemOnGround(bodyItem,hero,hero:GetAbsOrigin())
						end
						NotifyUtil.ShowSysMsg(PlayerID,"#info_tower_sold_hint_item",3)
					end
				end
			end
		else
			return false;
		end
	end
	
	return true
end

---经验过滤，保证获取到的经验都为0，避免由于kv写错了导致加经验
function m:ExperienceFilter(keys)
	keys.experience = 0;
	return true;	
end

---金币过滤器。获得金币的时候，如果玩家有金币加成buff。
--目前只有杀怪获得金币可以进这个过滤器
--
--gold  (string): 21  (number)
--player_id_const  (string): 0  (number)
--reason_const  (string): 13  (number)   (13=DOTA_ModifyGold_CreepKill)
--reliable  (string): 0  (number)
function m:GoldFilter(keys)
	keys.gold = 0
	return true
end

return m