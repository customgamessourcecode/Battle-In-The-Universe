	
	function swk_rybf(keys)

		local caster = keys.caster

		local ability = keys.ability

		


	--local units = keys.units
	--local units = FindAlliesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
		

		local level = caster:GetLevel()
	
		local damage = caster:GetAttackDamage() * level * level









		
		local path = "particles/units/heroes/hero_monkey_king/monkey_king_strike_model.vpcf"

		local path2 = "particles/units/heroes/hero_monkey_king/monkey_king_strike_motion_streak_yellow.vpcf"

		local pid =  CreateParticleEx(path,PATTACH_ABSORIGIN,caster,1)

		local pid2 = CreateParticleEx(path2,PATTACH_ABSORIGIN,caster,1)

			SetParticleControlEx( pid2, 1, caster:GetAbsOrigin())

		
			
			local casterOrigin	= caster:GetAbsOrigin()
			
			local casterForward	= caster:GetForwardVector()

			casterOrigin = casterOrigin + casterForward * 1200 



			SetParticleControlEx( pid, 1, casterOrigin)			

			local units = FindEnemiesInLineEx(caster,caster:GetAbsOrigin(),casterOrigin,200,DOTA_UNIT_TARGET_FLAG_NONE)

			for key, unit in pairs(units) do
		
					ApplyDamageEx(caster,unit,ability,damage)		

			end


		
	end


		
