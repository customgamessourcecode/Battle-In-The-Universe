function hz_jsxj(keys)
	local caster = keys.caster

	local ability = keys.ability

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local bonus = GetAbilitySpecialValueByLevel(ability,"bonus")

	local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius)

	for key, unit in pairs(units) do
		unit:ReduceMana(bonus)
	end

end
