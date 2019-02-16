---灭生老人：如影随形
function mslr_ryxs(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local hero = PlayerUtil.GetHero(caster)
	---做判断，避免死循环。
	--因为创建分身的逻辑是在技能升级的时候触发的
	--（这个技能是一个被动，升级还会影响数量，要么做成计时器轮询，要么就在技能升级的时候触发），
	--而下面创建单位的时候又会触发技能升级事件，从而会出现死循环，为了避免这种情况，要加上特殊标记。
	--目前这种加标记的方式可能出现问题（有多个单位一起进入这个逻辑的时候，可能出错），所以通过将该技能设置为最大等级为0
	--来避免创建单位的时候就触发技能升级。这样就可以去掉这个标记了，后续如果确实需要的话，再去掉注释
--	if hero._mslr_ryxs_creating then
--		return
--	end
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local exist = ability._exist
	if not exist then
		exist = {}
		ability._exist = exist
	end
	count = count - #exist
	if count > 0 then
		for var=1, count do
			--新创建单位的owner必须设置成英雄，否则其造成的伤害，玩家看不到。具体原因看CreateUnitEx中的说明
			local unit = CreateUnitEX(caster:GetUnitName(),RandomPosInRadius(caster:GetAbsOrigin(),80),true,caster)	
			--删掉不继承的技能
			unit:RemoveAbility(ability:GetAbilityName())
			unit:RemoveAbility("xn_MieShengLaoRen_qzrw")
			unit:RemoveModifierByName("modifier_xn_MieShengLaoRen_rysx")
			unit:RemoveModifierByName("modifier_xn_MieShengLaoRen_qzrw")
			
			AddDataDrivenModifier(ability,caster,unit,"modifier_xn_MieShengLaoRen_rysx_fs",{})
			
			MakeUnitIllusion(unit,caster,ability,nil,100,100,true)
			
			table.insert(exist,unit)
		end
	end
end


---灭生老人：如影随形，本体死亡（被收回了），销毁掉所有幻象
function mslr_ryxs_destroy(keys)
	local ability = keys.ability
	if ability._exist then
		for key, unit in pairs(ability._exist) do
			EntityHelper.remove(unit)
		end
	end
end

---灭生老人：趋之若鹜伤害
function mslr_qzrw_damage(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	if target.mslr_qzrw_position == nil then
		target.mslr_qzrw_position = target:GetAbsOrigin()
	end
	local distance = (target.mslr_qzrw_position - target:GetAbsOrigin()):Length2D()
	if distance > 0 then
		ApplyDamageEx(caster,target,ability,damage * distance)
	end
	--记录新的位置
	target.mslr_qzrw_position = target:GetAbsOrigin()
end

---灭生老人：趋之若鹜debuff消失以后，去掉单位上临时存储的位置信息
--避免单位绕了特别远的距离以后重新进入攻击范围的时候，直接被造成大量伤害
function mslr_qzrw_destroy(keys)
	local target = keys.target
	target.mslr_qzrw_position = nil
end