---诛仙：林惊羽
AICenter.Register("tower_zx_linjingyu",function(tower,ai)
	--攻击范围内有敌方单位才释放技能
	local enemies = FindEnemiesInRadiusEx(tower,tower:GetAbsOrigin(),tower:Script_GetAttackRange())
	if enemies and #enemies > 0 then
		--旋龙震天
		local ability = tower:FindAbilityByName("zx_linjingyu_xlzt")
		if ability and ability:GetLevel() > 0 and ability:IsFullyCastable() then
			tower:CastAbilityNoTarget(ability,-1);
			return;
		end
		--斩鬼神
		ability = tower:FindAbilityByName("zx_linjingyu_zgs")
		if ability and ability:GetLevel() > 0 and ability:IsFullyCastable() then
			tower:CastAbilityNoTarget(ability,-1);
			return;
		end
		--御剑诀，并不是技能冷却好了就立刻释放，而是技能冷却好了以后再间隔一定时间，毕竟到后期伤害太低了，还不如平A
		ability = tower:FindAbilityByName("zx_linjingyu_yjj")
		if ability and ability:GetLevel() > 0 and ability:IsFullyCastable() 
			and (not ability._CastAbilityTime or GameRules:GetGameTime() - ability._CastAbilityTime > (ability:GetCooldown(0) + 2) ) then
			ability._CastAbilityTime = GameRules:GetGameTime()
			
			local castRange = ability:GetCastRange();
			local target = tower:GetAttackTarget()
			if target then
				local targetLoc = target:GetAbsOrigin()
				if (targetLoc - tower:GetAbsOrigin()):Length2D() <= castRange then --在施法范围内，才使用。
					tower:CastAbilityOnPosition(targetLoc,ability,-1);
				end
			end
			return;
		end
	end
end)