
function xtzh_zmly(keys)
	local caster = keys.caster

	local ability = keys.ability

	local point = keys.target_points[1]


	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local damage = GetAbilitySpecialValueByLevel(ability,"damage")

	local units = FindEnemiesInRadiusEx(caster,point,radius)



	--local path = "particles/econ/items/legion/legion_overwhelming_odds_ti7/legion_commander_odds_ti7_shard_group.vpcf";
	local path = "particles/econ/items/legion/legion_overwhelming_odds_ti7/legion_commander_odds_ti7.vpcf";

	for i=1,10 do
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,1)
		local point2 = FindRandomPoint(point,radius)
		SetParticleControlEx(pid,0,point2)
		SetParticleControlEx(pid,1,point2)
	--	SetParticleControlEx(pid,2,point2)
	end


	for key,unit in pairs(units) do
		ApplyDamageEx(caster,unit,ability,damage)
	end

end


function xtzh_jtzsy(keys)
	local caster = keys.caster

	local ability = keys.ability

	local point = keys.target_points[1]

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local damage = GetAbilitySpecialValueByLevel(ability,"damage")

	local units = FindEnemiesInRadiusEx(caster,point,radius)

	local path = "particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf";
	local count = 0

	TimerUtil.createTimer(function()
		if count < 3 then
			local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,3)
			SetParticleControlEx(pid,0,point)

			for key, unit in pairs(units) do
				ApplyDamageEx(caster,unit,ability,damage)
			end
			count = count + 1
		end
		return 1
	end )

end
