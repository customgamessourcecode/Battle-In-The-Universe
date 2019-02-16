local m = {}

---1
m.normal = 1
---2
m.wind = 2
---3
m.fire  = 3
---4
m.water = 4
---5
m.earth = 5

---元素类型数值和字符串转换
local map = {
	[m.normal] = "normal",
	[m.wind] = "wind",
	[m.fire] = "fire",
	[m.water] = "water",
	[m.earth] = "earth"
}

---单位的攻击元素类型。key是单位名字，value是对应的元素类型
local unitAttackElement = {}

---元素攻击对护甲伤害系数
--key是攻击类型，value是一个table，对应各个护甲类型受到的伤害
local d2a = {
	[m.normal] = {
		[m.normal] = 1,
		[m.wind] = 0.8,
		[m.fire] = 0.8,
		[m.water] = 0.8,
		[m.earth] = 0.8
	},
	[m.wind] = {
		[m.normal] = 0.85,
		[m.wind] = 0.6,
		[m.fire] = 0.8,
		[m.water] = 0.8,
		[m.earth] = 1.5
	},
	[m.fire] = {
		[m.normal] = 0.85,
		[m.wind] = 1.5,
		[m.fire] = 0.6,
		[m.water] = 0.8,
		[m.earth] = 0.8
	},
	[m.water] = {
		[m.normal] = 0.85,
		[m.wind] = 0.8,
		[m.fire] = 1.5,
		[m.water] = 0.6,
		[m.earth] = 0.8
	},
	[m.earth] = {
		[m.normal] = 0.85,
		[m.wind] = 0.8,
		[m.fire] = 0.8,
		[m.water] = 1.5,
		[m.earth] = 0.6
	}
}

---元素护甲对攻击的承伤系数
--key是护甲类型，value是一个table，对应各个攻击类型造成的伤害
local a2d = {}
for key, var in pairs(d2a) do
	a2d[key] = {}
	for key2, var2 in pairs(d2a) do
		a2d[key][key2] = var2[key]
	end
end

---根据伤害类型和护甲类型计算最终伤害
--@param #number damage 原始伤害（dota计算后的伤害）
--@param #handle attacker 攻击者，如果为空或者没有_damateType属性则伤害不变化
--@param #handle victim 受伤者，如果为空或者没有_armorType属性则伤害不变化
function m.calculate(damage,attacker,victim)
	if damage and attacker and victim then
		local damageType = m.GetAttackElement(attacker)
		local armorType = victim._armorType
		if damageType and armorType then
			--默认造成的伤害系数
			local ratio = d2a[damageType][armorType] or 1
			--增加元素伤害加深影响，在计算完基础的元素抗性因素后，再额外加深
			local extra = m.GetElementDamageIn(victim,damageType)
			if extra and extra ~= 0 then
				return damage * ratio * (1 + extra / 100)
			else
				return damage * ratio
			end
		end
	end
	return damage
end
---随机一个元素类型返回
function m.randomElement()
	return RandomInt(m.normal,m.earth)
end

---给单位随机一个护甲元素类型，并添加对应的护甲描述技能
function m.randomArmor(unit)
	if unit then
		unit._armorType = m.randomElement()
		local name = map[unit._armorType]
		if name then
			name = "monster_armor_tooltip_"..name
			local ability = unit:AddAbility(name)
			ability:SetLevel(1)
		end
	end
end
---给单位设置一个护甲元素类型
function m.SetArmor(unit,armorType)
	if unit and armorType then
		unit._armorType = armorType
	end
end

---获取某个单位的元素属性，用于向客户端的属性界面展示。有攻击属性，返回攻击属性；有防御返回防御属性。
function m.GetUnitElement(unitIndex)
	local result = {}
	local unit = EntityHelper.findEntityByIndex(unitIndex)
	if unit then
		result.unit = unitIndex
		
		if unit._armorType then
			local data = {}
			data._type = unit._armorType
			data.ratio = {}
			data.bonus = {}
			for attackType, baseRatio in pairs(a2d[data._type]) do
				--
				data.ratio[attackType] = tostring(baseRatio * 100)
				
				local extra = m.GetElementDamageIn(unit,attackType)
				if extra ~= 0 then
					--伤害加深是在基础系数之上，再进行比例换算，而不是直接叠加
					local bonusValue = ParseFloatToDecimal(baseRatio * extra,1,true)
					if bonusValue > 0 then
						data.bonus[attackType] = "+"..tostring(bonusValue).."%"
					else
						data.bonus[attackType] = tostring(bonusValue).."%"
					end
				end
			end
			result.armor = data
		end
		local damageType = m.GetAttackElement(unit)
		if damageType then
			local data = {}
			data._type = damageType
			data.ratio = {}
			--这里直接转换好，省的在客户端js小数好多小数位
			for key, var in pairs(d2a[data._type]) do
				data.ratio[key] = tostring(var * 100) 
			end
			
			result.damage = data
		end
	end
	return result
end

---添加提升受到的元素伤害的buff，并返回
--@param #handle caster 施法者，非空
--@param #handle target 目标单位，非空
--@param #handle ability 来源技能，非空
--@param #number type 元素类型，非空。且默认同一个施法者的同一个技能只会提供一种属性加成
--@param #number duration 持续时间，可为空。如果为空，需要使用返回的modifier自行处理移除逻辑
--@return #handle 返回modifier实体，可以在没有duration的情况下手动进行移除，避免出现因为caster或者ability为空，导致无法移除的情况
function m.AddElementDamageIn(caster,target,ability,type,duration)
	if caster and target and ability and type then
		local modifier = AddLuaModifier(caster,target,"td_multiple_element_damage_in",{duration=duration},ability)
		if modifier then
			modifier.td_element_type = type
			return modifier
		end
	end
end

---获取一个单位受到的某系元素伤害加成系数。<p>
--@param #handle unit 单位实体
--@param #number type 元素类型
function m.GetElementDamageIn(unit,type)
	local value = 0
	
	if unit and type then
		local all = unit:FindAllModifiersByName("td_multiple_element_damage_in")
		if all and #all > 0 then
			for key, modifier in pairs(all) do
				if modifier.td_element_type == type then
					value = value + modifier:GetElementDamageInRatio()
				end
			end
		end
	end
	return value
end

---获取单位的攻击属性
function m.GetAttackElement(unit)
	if unit then
		return unitAttackElement[unit:GetUnitName()] or unit._damageType --临时的攻击类型
	end
end

---获取单位的护甲属性
function m.GetArmorElement(unit)
	if unit then
		return unit._armorType
	end
end

local register = function()
	RegisterEventListener("xxdld_get_unit_element",m.getUnitElement)
	
	--加载单位信息，主要是获取塔的攻击属性
	local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for unitName, unit in pairs(units) do
		if unitName ~= "tower_world_name" and unit.tower_attack_element then
			if unit.tower_attack_element == "ae_1" then
				unitAttackElement[unitName] = 1
			elseif unit.tower_attack_element == "ae_2" then
				unitAttackElement[unitName] = 2
			elseif unit.tower_attack_element == "ae_3" then
				unitAttackElement[unitName] = 3
			elseif unit.tower_attack_element == "ae_4" then
				unitAttackElement[unitName] = 4
			elseif unit.tower_attack_element == "ae_5" then
				unitAttackElement[unitName] = 5
			end
		end
	end
end
register()
return m