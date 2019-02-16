---冥灵：水之灵
function ml_szl(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	
	ability.ml_szl_count = count
	ability.ml_szl_center = target:GetAbsOrigin()
	
	local path = "particles/units/heroes/hero_tidehunter/tidehunter_gush.vpcf"
	CreateProjectileWithTarget(caster,target,ability,path,1800)
end

---冥灵：水之灵命中目标
function ml_szl_landed(keys)
	local ability = keys.ability
	local target = keys.target
	
	local path = "particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf"
	CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,target,1)
	PurgeUnit(target,false,true,false,true,true)
	
	local purgedUnits = ability.ml_szl_units
	if not purgedUnits then
		purgedUnits = {}
		ability.ml_szl_units = purgedUnits
	end
	
	table.insert(purgedUnits,target)
	ability.ml_szl_count = ability.ml_szl_count - 1
	
	if ability.ml_szl_count > 0 then
		local radius = GetAbilitySpecialValueByLevel(ability,"radius")
		--搜索附近玩家控制的非幻象单位和马甲单位（马甲单位都是魔免的）
		local units = FindAlliesInRadiusEx(target,ability.ml_szl_center,radius,DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS+DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED+DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES)
		if #units > 0 then
			for key, unit in pairs(units) do
				---每个单位只会被净化一次
				local notPurged = true
				for key, purged in pairs(purgedUnits) do
					if unit == purged then
						notPurged = false;
						break;
					end
				end
				if notPurged then
					path = "particles/units/heroes/hero_tidehunter/tidehunter_gush.vpcf"
					CreateProjectileWithTarget(target,unit,ability,path,1800)
					return
				end
			end
		end
	end
	
	--清空标记
	ability.ml_szl_count = nil
	ability.ml_szl_units = nil
	ability.ml_szl_center = nil
end