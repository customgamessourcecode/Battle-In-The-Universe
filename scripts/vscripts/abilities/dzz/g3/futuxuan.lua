---浮屠玄-无尽光明体
function ftx_wjgmt_check(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	if Elements.GetArmorElement(target) == Elements.water then
		AddDataDrivenModifier(ability,caster,target,"modifier_dzz_FuTuXuan_wjgmt_debuff",{})
	end
end

---浮屠玄-浮屠塔
function ftx_ftt(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local dummy = FakeWall.CreateCylinder(ability,point,radius,duration,function()
		local path = "particles/dzz/futuxuan_ftt_model.vpcf"
		local pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster,duration,true)
		SetParticleControlEx(pid,0,point + Vector(0,0,60))
		SetParticleControlEx(pid,1,Vector(0.7,0.7,0.65))
		
		local step = 5
		local count = 60 / step
		TimerUtil.createTimer(function()
			if count > 0 then
				count = count - 1
				SetParticleControlEx(pid,0,point + Vector(0,0,step * count))
				
				return 0.01
			else
				SetParticleControlEx(pid,0,point)
			
				path = "particles/dzz/futuxuan_ftt_smoke.vpcf"
				pid = CreateParticleEx(path,PATTACH_CUSTOMORIGIN,caster)
				SetParticleControlEx(pid,3,point)
				
				EmitSoundOnLoc(point,"Hero_EarthSpirit.StoneRemnant.Impact",caster)
			end
		end)
	end)
end