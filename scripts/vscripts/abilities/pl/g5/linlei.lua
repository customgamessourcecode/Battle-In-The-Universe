--林雷：大地崩裂
function ll_ddbl(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local unitLevel = caster:GetLevel()
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local enemies = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	if enemies and #enemies > 0 then
		local ratio = GetAbilitySpecialValueByLevel(ability,"ratio") or 1
		local damage = ratio * caster:GetAttackDamage() * unitLevel
		local modifier = "modifier_pl_LinLei_ddbl_move"
		for key, unit in pairs(enemies) do
			AddDataDrivenModifier(ability,caster,unit,modifier,{})
			ApplyDamageEx(caster,unit,ability,damage)
		end
		
		EmitSound(caster,"Hero_Leshrac.Split_Earth")
		local path = "particles/econ/items/elder_titan/elder_titan_ti7/elder_titan_echo_stomp_ti7_physical.vpcf"
		CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
	end
end

--林雷：龙吟
function ll_ly(keys)
	local caster = keys.caster
	
	local path = "particles/econ/items/outworld_devourer/od_ti8/od_ti8_santies_eclipse_area_shockwave.vpcf"
	local count = 0
	TimerUtil.createTimer(function()
		if count < 2 then
			CreateParticleEx(path,PATTACH_ABSORIGIN,caster,2)
			count = count + 1
			return 0.5
		end
	end)
end

---林雷：龙化
function linlei_lh_start(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	AddLuaModifier(caster,caster,"linlei_lh_model_change",{duration=duration},ability)
	
	caster.projectile = caster:GetRangedProjectileName();
	caster:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_corrosive.vpcf")
end

---林雷：龙化
function linlei_lh_end(keys)
	local caster = keys.caster
	caster:SetRangedProjectileName(caster.projectile)
end