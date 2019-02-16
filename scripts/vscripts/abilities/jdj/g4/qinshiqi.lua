---秦十七：多重暴击
--攻击顺序正常情况下：start(s)---attack(a)---landed(l)---finished(f)。
--如果攻击动作没有完成就被取消了，则会提前进入finished
--比如，投射物发出去了，但是动作没完被s住了，顺序就是s-a-f-l
--或者投射物还没有出去就被s住了，就会是s-f
--攻击失败没有测试。
function qsq_multi_crit(keys)
	local caster = keys.caster
	local target = keys.target
	
	local ability_l = caster:FindAbilityByName("jdj_QinShiQi_zmyj")
	local chance_l = GetAbilitySpecialValueByLevel(ability_l,"chance")
	
	local ability_m = caster:FindAbilityByName("jdj_QinShiQi_twyj")
	local chance_m = GetAbilitySpecialValueByLevel(ability_m,"chance")
	
	local ability_h = caster:FindAbilityByName("jdj_QinShiQi_bsyj")
	local chance_h = GetAbilitySpecialValueByLevel(ability_h,"chance")
	
	---由于用默认的buff提供暴击的话会出现数值和特效不匹配的情况，所以这里在lua中模拟暴击
	if RollPercent(chance_h) then
		EmitSound(target,"Hero_PhantomAssassin.CoupDeGrace")
		
		local path = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_sparks_lv.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target,3)
		SetParticleControlEx(pid,1,target:GetAbsOrigin())
	
		local damageRatio = GetAbilitySpecialValueByLevel(ability_h,"damage") / 100
		local damage = caster:GetAttackDamage() * damageRatio
		ApplyDamageEx(caster,target,ability_h,damage)
		
		SendOverheadEventMessage(target,OVERHEAD_ALERT_CRITICAL,target,damage,caster)
	elseif RollPercent(chance_m) then
		EmitSound(target,"DOTA_Item.AbyssalBlade.Activate")
		
		local path = "particles/items_fx/abyssal_blade_crimson_jugger.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target,3)
		SetParticleControlEx(pid,0,target:GetAbsOrigin())
		
		local damageRatio = GetAbilitySpecialValueByLevel(ability_m,"damage") / 100
		local damage = caster:GetAttackDamage() * damageRatio
		ApplyDamageEx(caster,target,ability_m,damage)
		
		SendOverheadEventMessage(target,OVERHEAD_ALERT_CRITICAL,target,damage,caster)
	elseif RollPercent(chance_l) then
		EmitSound(target,"Hero_PhantomAssassin.CoupDeGrace.Mech")
	
		local damageRatio = GetAbilitySpecialValueByLevel(ability_l,"damage") / 100
		local damage = caster:GetAttackDamage() * damageRatio
		ApplyDamageEx(caster,target,ability_l,damage)
		
		SendOverheadEventMessage(target,OVERHEAD_ALERT_CRITICAL,target,damage,caster)
	end
end
