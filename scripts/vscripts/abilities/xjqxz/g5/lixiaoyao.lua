---赤子之心升级
function lxy_czzx_upgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	--升级的时候会进来很多次，这里只处理一次
	if ability.lxy_czzx_upgrade then
		return;
	end
	ability.lxy_czzx_upgrade = true
	
	local stack = Towermgr.GetTowerKV(caster,"lxy_czzx_stack")
	if stack then
		local modifier = caster:FindModifierByName("modifier_xjqxz_LiXiaoYao_czzx")
		if not modifier then
			modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_xjqxz_LiXiaoYao_czzx",{})
		end
		if modifier then
			modifier:SetStackCount(stack)
			--添加增伤buff
			
			--将添加成功的信息缓存在单位身上，方便移除。缓存在单位身上也最稳定，只要单位不死，就肯定会获取到。如果单位死了，那获取不到也无所谓了
			local key = "do_xjqxz_LiXiaoYao_czzx"
			if EntityIsNull(caster[key]) then
				caster[key] = AddLuaModifier(caster,caster,"modifier_multiple_damage_out",{},ability)
				if caster[key] then
					caster[key]:SetStackCount(stack)
				end
			else
				caster[key]:SetStackCount(stack)
			end
			
		end
	end
end

---赤子之心单位销毁
function lxy_czzx_destroy(keys)
	local caster = keys.caster
	local modifier = caster:FindModifierByName("modifier_xjqxz_LiXiaoYao_czzx")
	if modifier then
		Towermgr.SetTowerKV(caster,"lxy_czzx_stack",modifier:GetStackCount())
	end
	local key = "do_xjqxz_LiXiaoYao_czzx"
	if EntityNotNull(caster[key]) then
		caster[key]:Destroy()
	end
	caster[key] = nil
end

function lxy_tj_ring_create(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	ability.center = target:GetAbsOrigin()
	
	local radius = GetAbilitySpecialValueByLevel(ability,"ring_radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"ring_duration")
	
	local path = "particles/units/heroes/hero_disruptor/disruptor_kineticfield.vpcf"
	ability.pid = ParticleManager:CreateParticle(path, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(ability.pid, 0, ability.center)
	ParticleManager:SetParticleControl(ability.pid, 1, Vector(radius, radius, 0))
	ParticleManager:SetParticleControl(ability.pid, 2, Vector(duration,0,0))
end

function lxy_tj_ring_destroy(keys)
	local ability = keys.ability
	ParticleManager:DestroyParticle(ability.pid, true)
end

function lxy_tj_ring_check(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local radius = GetAbilitySpecialValueByLevel(ability,"ring_radius")
	
	local distance = (target:GetAbsOrigin() - ability.center):Length2D()
	local distance_from_border = distance - radius
	
	--这里不考虑面向问题了，怪物撞上去就直接设置为被缠绕状态，不允许移动了（怪物ai目前也没有自动转向的逻辑）
	if math.abs(distance_from_border) <= 20 then
		if not target:HasModifier("modifier_xjqxz_LiXiaoYao_tj_debuff") then
			AddDataDrivenModifier(ability,caster,target,"modifier_xjqxz_LiXiaoYao_tj_debuff",{})
		end
	end
end
