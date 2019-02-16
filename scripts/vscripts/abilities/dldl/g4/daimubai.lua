---戴沐白：白虎烈光波
function dmb_bhlgb(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	local damage = caster:GetAverageTrueAttackDamage(target) * ratio
	
	local lxy = caster:FindAbilityByName("dldl_DaiMuBai_bhlxy");
	local path = "particles/units/heroes/hero_luna/luna_eclipse_impact.vpcf";
	if lxy:GetLevel() > 0 then
		local radius = GetAbilitySpecialValueByLevel(lxy,"radius")
		local enemies = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
		for key, unit in pairs(enemies) do
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,unit,2.5)
			SetParticleControlEx(pid,1,unit:GetAbsOrigin())
			ApplyDamageEx(caster,unit,ability,damage)
		end
		
	else
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target,2.5)
		SetParticleControlEx(pid,1,target:GetAbsOrigin())
		ApplyDamageEx(caster,target,ability,damage)
	end
end

---戴沐白：白虎真身开始
function dmb_bhzs_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	
	AddLuaModifier(caster,caster,"dmb_bhzs_damage_out",{},ability)	
	caster:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
	--设置模型大小，modifier里面的属性不好使了，不知道为啥
	caster:SetModelScale(1);
end
---戴沐白：白虎真身结束
function dmb_bhzs_destroy(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	
	caster:RemoveModifierByName("dmb_bhzs_damage_out")
	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
	caster:SetModelScale(4.5);
end