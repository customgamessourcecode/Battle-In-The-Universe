
function lqt_hazl(keys)
	local caster = keys.caster

	local ability = keys.ability

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local bonus = GetAbilitySpecialValueByLevel(ability,"bonus")

	local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius)

	local path = "particles/items_fx/arcane_boots.vpcf";

	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
	SetParticleControlEx(pid,1,caster:GetAbsOrigin())

	for key, unit in pairs(units) do

		unit:GiveMana(bonus)
	end

end
