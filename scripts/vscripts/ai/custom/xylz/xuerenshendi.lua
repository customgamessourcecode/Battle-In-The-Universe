---雪鹰领主：血刃神帝AI
AICenter.Register("tower_xylz_xuerenshendi",function(tower,ai)
	if Spawner.IsInfinite() then
		return;
	end
	
	local ability = tower:FindAbilityByName("xylz_XueRenShenDi")
	if ability and ability:GetLevel() > 0 and ability:IsFullyCastable() then
		local radius = ability:GetCastRange();
		local enemies = FindEnemiesInRadiusEx(tower,tower:GetAbsOrigin(),radius)
		if enemies and #enemies > 0 then
			for _, unit in pairs(enemies) do
				if not unit:HasModifier("modifier_xylz_XueRenShenDi") then
					tower:CastAbilityOnTarget(unit,ability,-1);
					break;
				end
			end
		end
	end
end)