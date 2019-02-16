LinkLuaModifier("modifier_custom_armor_multi","customsys/custom_armor/modifier_custom_armor_multi.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_armor_damage_reduce","customsys/custom_armor/modifier_custom_armor_damage_reduce.lua",LUA_MODIFIER_MOTION_NONE)

---单位缓存custom_armor_data{base=123，bonus=123，last={base=123,bonus=123}（主要用于向客户端发送）}
local m = {}
---所有单位的基础护甲:unitName=123，单位刷新的时候设置
local baseArmor = {}

---更新某个单位的护甲数据到客户端
function m.UpdateArmorNettable(unit)
	if EntityIsNull(unit) then
		return;
	end
	local data = unit.custom_armor_data
	if not data then
		data = {}
		unit.custom_armor_data = data
	end
	local before = data.bonus or 0
	--先初始化附加值，然后再累计所有buff的值
	local bonus = 0
	local modifiers = unit:FindAllModifiersByName("modifier_custom_armor_multi")
	if modifiers and #modifiers > 0 then
		for _, modifier in pairs(modifiers) do
			if EntityNotNull(modifier) then
				local armor = modifier:GetCustomArmor() or 0
				bonus = bonus + armor
			end
		end
	end
	
	if before ~= bonus then
		data.bonus = bonus
		--SetNetTableValue("custom_armor",tostring(unit:entindex()).."_bonus",{v=data.bonus})
	end
end

---技能增加某个单位的护甲。同一类技能只会有一个生效
--@param #handle caster 施法者
--@param #handle target 目标单位
--@param #handle ability 技能实体
--@param #handle key 技能实体
--@param #handle refModifier 护甲关联的modifier（必须是ability添加的），当这个护甲效果是可叠加的时候，需要添加这个参数，这样在实际计算的时候会以这个关联的modifier的叠加层数计算护甲
--@param #string uniqueKey 唯一索引，同索引的效果不会重复添加效果。不可为空
function m.AddAbilityArmor(caster,target,ability,refModifier,uniqueKey)
	if not uniqueKey or type(uniqueKey) ~= "string" then
		return;
	end
	--将添加成功的信息缓存在单位身上，方便移除。缓存在单位身上也最稳定，只要单位不死，就肯定会获取到。如果单位死了，那获取不到也无所谓了
	local key = "custom_armor_"..uniqueKey
	if EntityIsNull(target[key]) then
		target[key] = AddLuaModifier(nil,target,"modifier_custom_armor_multi",{ref=refModifier},ability)
		if target[key] then
			--计算一下护甲值并更新到客户端
			m.UpdateArmorNettable(target)
		end
	end
end

---移除某个技能加在单位身上的护甲加成
function m.RemoveAbilityAddedArmor(unit,uniqueKey)
	if type(uniqueKey) == "string" then
		local key = "custom_armor_"..uniqueKey
		if EntityNotNull(unit[key]) then
			unit[key]:Destroy()
			m.UpdateArmorNettable(unit)
		end
		unit[key] = nil
	end
end

---设置某个单位基础护甲为给定值
function m.SetBaseArmor(unit,armor)
	if unit and type(armor) == "number"then
		local data = unit.custom_armor_data
		if not data then
			data = {}
			unit.custom_armor_data = data
		end
		
		local before = data.base or 0
		if before ~= armor then
			data.base = armor
			--SetNetTableValue("custom_armor",tostring(unit:entindex()).."_base",{v=data.base})
		end
	end
end

---获取某个单位的基础护甲值
function m.GetBaseArmor(unit)
	local data = unit.custom_armor_data or {}
	return data.base or 0
end

---单位刷新的时候，设置基础护甲，并添加护甲buff。
--目前没有处理单位升级增加的护甲
function m.UnitSpawned(unit)
	AddLuaModifier(nil,unit,"modifier_custom_armor_damage_reduce",{})
	m.SetBaseArmor(unit,baseArmor[unit:GetUnitName()] or 0)
end


function m.Client_GetArmor(_,keys)
	local PlayerID,unitIndex,force = keys.PlayerID,keys.unit,keys.force
	if unitIndex then
		local unit = EntityHelper.findEntityByIndex(unitIndex)
		if EntityIsAlive(unit) and unit.custom_armor_data then
			local data = unit.custom_armor_data
			local last = data.last or {}
			local base = data.base or 0
			local bonus = data.bonus or 0
			if force or last.base ~= base or last.bonus ~= bonus then
				last.base = base;
				last.bonus = bonus;
				data.last = last
				SendToClient(PlayerID,"custom_armor_response",{index=unitIndex,base=base,bonus=bonus})
			end
		end
	end
end

--初始化，记录所有单位的基础护甲
local init = function()
	local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for unitName, unit in pairs(units) do
		if unit.xxj_custom_armor then
			baseArmor[unitName] = tonumber(unit.xxj_custom_armor)
		end
	end
	
	RegisterEventListener("custom_armor_request",m.Client_GetArmor)
end
init()
return m;