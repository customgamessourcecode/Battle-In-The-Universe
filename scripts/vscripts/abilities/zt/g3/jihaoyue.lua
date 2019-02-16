---姬皓月：神王再生术
function jhy_swzss(keys)
	local caster = keys.caster

	local target = keys.target

	local ability = keys.ability

	local bonus = GetAbilitySpecialValueByLevel(ability,"bonus")
	target:GiveMana(bonus)
end


---姬皓月：天演神术
function jhy_tyss(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	
	local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),FIND_UNITS_EVERYWHERE)
	
	if #units > 0 then
		local path = "particles/econ/items/monkey_king/arcana/water/monkey_king_spring_cast_arcana_water.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
		
		path = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf"
		TimerUtil.createTimerWithDelay(0.8,function()
			local point = caster:GetAbsOrigin()
			pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,0.6,false)
			SetParticleControlEx(pid,0,point)
			SetParticleControlEx(pid,1,point + Vector(0,0,1000))
			SetParticleControlEx(pid,2,Vector(2000,0,0))
			
			EmitSound(caster,"Hero_VengefulSpirit.MagicMissile")
			--EmitSoundOnLoc(point,"Hero_VengefulSpirit.MagicMissile",caster)
		end)
		
		TimerUtil.createTimerWithDelay(2,function()
			for var=1, count do
				if #units == 0 then
					return ;
				end
			
				local index = RandomInt(1,#units)
				local unit = units[index]
				table.remove(units,index)
				
				while (EntityIsNull(unit) or unit.TD_IsBoss) and #units > 0 do
					index = RandomInt(1,#units)
					unit = units[index]
					table.remove(units,index)
				end
				
				if EntityNotNull(unit) and not unit.TD_IsBoss then
					local loc = unit:GetAbsOrigin()
					MinimapEvent(caster:GetTeamNumber(), unit, loc.x, loc.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 1)
					
					EmitSound(unit,"Hero_VengefulSpirit.MagicMissile")
					
					local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,unit)
					SetParticleControlEx(pid,0,unit:GetAbsOrigin() + Vector(0,0,800))
					SetParticleControlEnt(pid,1,unit,PATTACH_POINT_FOLLOW,"attach_hitloc",unit:GetAbsOrigin())
					SetParticleControlEx(pid,2,Vector(1600,0,0))
					
					TimerUtil.createTimerWithDelay(0.5,function()
						ParticleManager:DestroyParticle(pid,false)
						if EntityNotNull(unit) then
							EmitSound(unit,"Hero_VengefulSpirit.MagicMissileImpact")
							unit:Kill(ability,caster)
						end
					end)
				end
			end
		end)
	end
end
