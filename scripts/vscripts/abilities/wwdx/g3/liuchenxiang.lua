---刘沉香
function lcx_extraDamage(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	---计算3d距离
	local length = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length();
	local damage = length * length / 100
	ApplyDamageEx(caster,target,ability,damage)
end