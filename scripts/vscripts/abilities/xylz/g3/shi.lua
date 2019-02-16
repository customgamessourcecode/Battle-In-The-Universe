function shi_extradamage(keys)

--	dumpTable(keys,"shi_extradamage")
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	--local units = keys.units
	--local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	local units = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)

	local level = caster:GetLevel()
	
	local damage = caster:GetAttackDamage() * level * level



	for key, unit in pairs(units) do

		ApplyDamageEx(caster,unit,ability,damage)
	end
end

 