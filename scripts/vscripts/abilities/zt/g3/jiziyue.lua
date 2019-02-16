---姬紫月：大虚空术
function jzy_dxks_mark(keys)
	local ability = keys.ability
	local target = keys.target
	
	target.jzy_dxks_point = target:GetAbsOrigin()
	target.jzy_dxks_forward = target:GetForwardVector()
	
	
	local path = "particles/units/heroes/hero_kunkka/kunkka_spell_x_spot.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target,keys.duration,true)
end

function jzy_dxks_return(keys)
	local ability = keys.ability
	local target = keys.target
	
	if EntityIsAlive(target) then
		if target.jzy_dxks_point then
			Teleport(target,target.jzy_dxks_point)
			target.jzy_dxks_point = nil
		end
		
		if target.jzy_dxks_forward then
			target:SetForwardVector(target.jzy_dxks_forward)
			target.jzy_dxks_forward = nil
		end
	end
end