---唐三：蓝银草特效
function ts_lyc_particle(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	local point = target:GetAbsOrigin()
	
	--创建特效
	local path = "particles/items_fx/ironwood_tree_grass.vpcf"
	local ringWidth = radius / 4
	local nums = {1,2,4,8}
	--原点特效
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
	SetParticleControlEx(pid,0,point)
	--外圈特效
	for ringNum=1, 4 do
		local count = nums[ringNum]
		local step = 360 / count
		local pos = nil
		for num=1, count do
			if pos then
				pos = RotateVector2DWithCenter(point,pos,step)
				local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
				SetParticleControlEx(pid,0,pos)
			else
				pos = point+RandomVector(ringWidth * ringNum)
				local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
				SetParticleControlEx(pid,0,pos)
			end
		end
	end
end

---唐三：蓝银绞杀
function ts_lyjs_check(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = caster:FindAbilityByName("dldl_TangSan_lyjs")
	
	if ability and ability:GetLevel() > 0 then
		if not target:HasModifier("modifier_dldl_TangSan_lyjs")
		 	and not target:HasModifier("modifier_dldl_TangSan_lyjs_root") then
			AddDataDrivenModifier(ability,caster,target,"modifier_dldl_TangSan_lyjs",{})
		end
	end
end

---蓝银绞杀：缠绕效果
function ts_lyjs_root(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	--仍然在蓝银草范围内，被缠绕
	if target:FindModifierByName("modifier_dldl_TangSan_lyc_damage")
		and not target:HasModifier("modifier_dldl_TangSan_lyjs_cooldown") then
		AddDataDrivenModifier(ability,caster,target,"modifier_dldl_TangSan_lyjs_root",{})
	end
end

---唐三：暴雨梨花针
function ts_bylhz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	--Hero_Bristleback.QuillSpray.Cast
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	
	local path = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_fear_debuff.vpcf"
	local pid = CreateParticleEx(path,PATTACH_WORLDORIGIN,caster,duration)
	SetParticleControlEx(pid,0,point+Vector(0,0,250))
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			EmitSound(caster,"Hero_Bristleback.QuillSpray.Cast")
			
			local effect = "particles/econ/items/bristleback/bristle_spikey_spray/bristle_spikey_quill_spray_sparks.vpcf"
			local effectID = CreateParticleEx(effect,PATTACH_CUSTOMORIGIN,caster,1)
			SetParticleControlEx(effectID,0,point+Vector(0,0,200))		
			
			DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
			
			duration = duration - interval
			return interval
		end
	end)
end

---唐三：佛怒唐莲
function ts_fntl_spell(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]
	
	local level = caster:GetLevel()
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local damage_interval = GetAbilitySpecialValueByLevel(ability,"damage_interval")
	
	local path = "particles/econ/items/dark_willow/dark_willow_ti8_immortal_head/dw_crimson_ti8_immortal_cursed_crownstart.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,duration)
	SetParticleControlEx(pid,0,point + Vector(0,0,200))
	
	path = "particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm_charge.vpcf"
	pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,duration)
	SetParticleControlEx(pid,0,point)
	
	path = "particles/dldl/tangsan_fntl_ring.vpcf"
	pid = CreateParticleEx(path,PATTACH_ABSORIGIN,caster,duration)
	SetParticleControlEx(pid,0,point + Vector(0,0,150))
	SetParticleControlEx(pid,2,Vector(radius,0,0))
	
	TimerUtil.createTimer(function()
		if duration > 0 then
			local enemies= FindEnemiesInRadiusEx(caster,point,radius)
			if enemies and #enemies > 0 then
				for _, unit in pairs(enemies) do
					local damage = caster:GetAverageTrueAttackDamage(unit) * level * level * 300
					ApplyDamageEx(caster,unit,ability,damage)
				end
			end
			duration = duration - damage_interval;
			return damage_interval;
		end
	end)
	
end
