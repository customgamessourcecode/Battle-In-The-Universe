---唐心莲：奉献种子技能升级，检查是否还可以使用，如果不能使用了，禁用本技能
function txl_fxzz_upgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local used = PlayerUtil.getAttrByPlayer(caster,"txl_fxzz_used")
	if used then
		ability:SetActivated(false)
	end
end

---唐心莲：奉献种子使用，增加人口上限的最大值
function txl_fxzz_cast(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local used = PlayerUtil.getAttrByPlayer(caster,"txl_fxzz_used")
	if not used then
		PlayerUtil.setAttrByPlayer(caster,"txl_fxzz_used",true)
		--禁用技能
		ability:SetActivated(false)
		
		local increament = 1
		--检查施法者是否经过了卡牌等级提升的强化
		local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_tangxinlian");
		if bonusModifier and bonusModifier:GetStackCount() > 0 then
			increament = increament + math.floor(bonusModifier:GetStackCount() / 50)
		end
		
		local status,err = pcall(function()
			local PlayerID = PlayerUtil.GetOwnerID(caster)
			--先增加上限
			Towermgr.AddPopulationLimit(PlayerID,increament)
			--再增加可创建数量
			for var=1, increament do
				Towermgr.AddPopulationMax(PlayerID)
			end
			
			--删掉单位
			local towerIndex = caster:entindex()
			Towermgr.RemovePlayerTower(PlayerID,towerIndex)	
			
			local path = "particles/units/heroes/hero_chen/chen_teleport_flash.vpcf"
			CreateParticleEx(path,PATTACH_ABSORIGIN,caster)
			caster:SetModelScale(0)
			caster:ForceKill(false)--kill以后并不会立刻变成null，会经过一个短暂延迟，应该是处理后续的逻辑的
			Towermgr.AddPopulationNow(PlayerID,-1)
		end)
		
		if not status then
			PlayerUtil.setAttrByPlayer(caster,"txl_fxzz_used",false)
			ability:SetActivated(true)
			DebugPrint(err)
		end
	end
end