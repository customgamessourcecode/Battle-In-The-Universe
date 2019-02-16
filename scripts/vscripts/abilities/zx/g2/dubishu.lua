---运来，当前玩家的单位释放技能的时候，增加金币
function dbs_yunlai(keys)
	local caster = keys.caster
	local target = keys.unit
	
	--无尽不生效
	if Spawner.IsInfinite() then
		return;
	end
	
	--同一个玩家的才有效
	if PlayerUtil.GetOwnerID(caster) == PlayerUtil.GetOwnerID(target) and not target:HasModifier("modifier_zx_dubishu_yl_cooldown") then
		local ability = keys.event_ability
		if ability and keys.gold and not ability:IsItem() then
			--不可学习类的技能，一般是特殊逻辑的技能，不能触发金币奖励
			local behavior = GetAbilityBehaviorNum(ability)
			if not BitAndTest(behavior,DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE) then
				AddDataDrivenModifier(keys.ability,caster,target,"modifier_zx_dubishu_yl_cooldown",{})
			
				local gold = keys.gold
				--检查施法者是否经过了卡牌等级提升的强化
				local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
				if bonusModifier and bonusModifier:GetStackCount() > 0 then
					gold = gold * (1 + bonusModifier:GetStackCount() / 100)
				end
				
				PlayerUtil.AddGold(target,gold)
				--不使用dota那个接口了，那个有金币声音，太多的话很乱。这个只显示特效即可
				PopupNum:PopupGoldGain(target,gold)
			end
		end
	end
end