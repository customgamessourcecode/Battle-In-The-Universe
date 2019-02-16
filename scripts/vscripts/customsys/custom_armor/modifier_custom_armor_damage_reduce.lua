---由于dota版本更新导致护甲叠加到一定上限后会使怪物承受的伤害减少100%。所以使用自定义的护甲来实现相应逻辑。
--基本思路是：所有增加护甲的地方都增加一个modifier（modifier_custom_armor_damage_reduce_multi），
--用来记录技能提供的护甲，即modifier护甲，这样能方便的获取技能数值，实现随技能等级动态变化。
--基础护甲在单位刷新的时候缓存进单位中。
--
--同时单位出生的时候添加这个modifier，用来计算护甲的减伤
if modifier_custom_armor_damage_reduce == nil then
	modifier_custom_armor_damage_reduce = class({})
	
	local m = modifier_custom_armor_damage_reduce;
	
	--无敌保持
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE;
	end
	
	function m:IsHidden()
		return true;
	end
	
	function m:IsPurgable()
		return false;
	end
	--对幻象有效
	function m:AllowIllusionDuplicate()
		return true;
	end
	
	--死亡的时候清空对应的nettable
--	function m:OnDestroy()
--		if IsServer() then
--			local unit = self:GetParent();
--			--死亡时，清空该单位所有的数据
--			SetNetTableValue("custom_armor",tostring(unit:entindex()).."_base",nil)
--			SetNetTableValue("custom_armor",tostring(unit:entindex()).."_bonus",nil)
--		end
--	end
	
	function m:DeclareFunctions()
	  local funcs = {
	  	--这个属性只会接受普通攻击的伤害
--	  	MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE,
		 --这个无论是技能伤害还是普通攻击的伤害都会进入.keys里面damage没有值，original_damage有值
	  	MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
	  	--这个属性的调用应该是在上边的调用后面的，调这个的时候，keys里面的damage已经有值了，并且是经过上一个削弱后的值
--	  	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	  }
	  return funcs;
	end
	
	function m:GetModifierIncomingSpellDamageConstant(keys)
		--local isSpell = keys.damage_category == DOTA_DAMAGE_CATEGORY_SPELL  --DOTA_DAMAGE_CATEGORY_SPELL(0),DOTA_DAMAGE_CATEGORY_ATTACK(1)
		
		if keys.damage_type == DAMAGE_TYPE_PHYSICAL then
			if IsServer() then
				local damage = keys.original_damage
				local unit = self:GetParent()
				local armor = 0
				local data = unit.custom_armor_data
				if data then
					armor = (data.base or 0) + (data.bonus or 0)
				end
				if armor ~= 0 then
					--减伤公式：0.05*护甲 / (1 + 0.05 * 护甲)
				
					local reduction = 0
					if armor > 0 then
						reduction = 0.05 * armor / (1 + 0.05 * armor)
					else
						reduction = 0.05 * armor / (1 - 0.05 * armor)
					end
					
					--这个返回值要受到魔抗影响，无论是魔法伤害还是物理伤害，实际应用的数值是这个值*（1-魔抗），所以这里转换一下
					--目前所有怪物的魔抗是0，所以这里其实没什么变化。但是为了避免以后有其他特殊技能逻辑，这里也保持这种转换
					local magicArmor = unit:GetMagicalArmorValue()
					--魔抗理论上是不会到1的，但是以防哪天v社修改逻辑，这里判断一下
					if magicArmor == 1 then
						return -reduction * damage
					else 
						return -reduction * damage / (1 - magicArmor) 
					end
				end
			end
		end
	end
end


