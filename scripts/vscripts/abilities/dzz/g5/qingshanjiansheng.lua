---青衫剑圣：仗剑天涯，击杀单位，叠加伤害buff
function qsjs_zjty_kill(keys)
	local caster = keys.caster
	local ability = keys.ability
	---收回的时候调用的击杀逻辑，也会进入这里。排除掉
	if caster == keys.unit then
		return;
	end
	
	local damage_modifier = ability._modifier
	if not damage_modifier then
		damage_modifier = AddLuaModifier(caster,caster,"modifier_multiple_damage_out",{},ability)
		ability._modifier = damage_modifier
	end
	
	
	local killBuff = caster:FindModifierByName("modifier_dzz_QingShanJianSheng_zjty")
	if killBuff then
		if killBuff:GetStackCount() < 3 then
			killBuff:IncrementStackCount()
			--保存起来
			Towermgr.SetTowerKV(caster,"qsjs_zjty_kill",killBuff:GetStackCount())
			return;
		else
			killBuff:SetStackCount(0)
			Towermgr.SetTowerKV(caster,"qsjs_zjty_kill",0)
			
			--击杀够5个，叠加侠义值。
			local max = GetAbilitySpecialValueByLevel(ability,"max")
			if damage_modifier and damage_modifier:GetStackCount() < max then
				damage_modifier:IncrementStackCount()
				
				Towermgr.SetTowerKV(caster,"qsjs_zjty_kill_modifier",damage_modifier:GetStackCount())
				
				local tooltipBuff = caster:FindModifierByName("modifier_dzz_QingShanJianSheng_zjty_damage_tooltip")
				if not tooltipBuff then
					tooltipBuff = AddDataDrivenModifier(ability,caster,caster,"modifier_dzz_QingShanJianSheng_zjty_damage_tooltip",{})
				end
				if tooltipBuff then
					tooltipBuff:SetStackCount(damage_modifier:GetStackCount())
				end
			end
		end
	end
end

---青衫剑圣：仗剑天涯，更新buff状态。主要用于处理单位收起重新放置的时候，恢复之前的侠义值和击杀数量
--注意这个逻辑要在技能升级的时候调用，在创建时调用会有问题，因为是默认拥有的，当创建单位的时候，就直接加上了。但是这个时候还获取不到缓存的数据。
--但是放在升级触发就没有问题了，创建单位后就会赋值缓存的数据，而升级是在单位“长大”以后了，至少是1秒以后了，此时就能获取到缓存数据了。
function qsjs_zjty_update(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	if ability.qsjs_zjty_update then
		return;
	end
	ability.qsjs_zjty_update = true
	
	local killBuff = caster:FindModifierByName("modifier_dzz_QingShanJianSheng_zjty")
	if killBuff then
		--更新击杀数
		local stack = Towermgr.GetTowerKV(caster,"qsjs_zjty_kill")
		if stack and stack > 0 then
			killBuff:SetStackCount(stack)
		end
		
		--更新侠义值
		stack = Towermgr.GetTowerKV(caster,"qsjs_zjty_kill_modifier")
		if stack and stack > 0 then
			local damage_modifier = ability._modifier
			if not damage_modifier then
				damage_modifier = AddLuaModifier(caster,caster,"modifier_multiple_damage_out",{},ability)
				ability._modifier = damage_modifier
			end
			if damage_modifier then
				damage_modifier:SetStackCount(stack)
				
				local tooltipBuff = caster:FindModifierByName("modifier_dzz_QingShanJianSheng_zjty_damage_tooltip")
				if not tooltipBuff then
					tooltipBuff = AddDataDrivenModifier(ability,caster,caster,"modifier_dzz_QingShanJianSheng_zjty_damage_tooltip",{})
				end
				if tooltipBuff then
					tooltipBuff:SetStackCount(stack)
				end
			end
		end
	end
end

---青衫剑圣：剑之世界释放，创建特效。缓存特效id，在移除单位的时候，立刻销毁特效（在modifier里面创建也能显示，但是消失是逐渐消失的）
function qsjs_jzsj_create(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local path = "particles/units/heroes/hero_riki/riki_tricks.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,duration)
	ability._pid = pid
	SetParticleControlEx(pid,1,Vector(radius,radius,radius))
	SetParticleControlEx(pid,2,Vector(duration,0,0))
end

---青衫剑圣：剑之世界销毁，移除特效。主要用在单位被收回的时候
function qsjs_jzsj_destroy(keys)
	local ability = keys.ability
	if ability._pid then
		ParticleManager:DestroyParticle(ability._pid, true)
	end
end

function qsjs_jzsj_damage(keys)
	local caster = keys.caster
	local target = keys.target
	
	--倒数第二个参数：bFakeAttack如果为true，则不会造成伤害
	--第三个参数如果为false，则会触发OnAttack事件，但是不会触发其余的几个事件（start、land、finish），这样有些攻击命中才生效的逻辑就不会触发了
	--PerformAttack(handle hTarget, bool bUseCastAttackOrb, bool bProcessProcs, bool bSkipCooldown, bool bIgnoreInvis, bool bUseProjectile, bool bFakeAttack, bool bNeverMiss)
	caster:PerformAttack(target,true,true,true,false,false,false,true)
end