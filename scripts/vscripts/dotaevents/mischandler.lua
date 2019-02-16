local m = {}

---玩家（英雄）升级的时候触发
function m:OnPlayerLevelUp(keys)
	--如果英雄等级超过可获得技能点的等级，则设置技能点为：最大点数-使用的技能点
	local player = EntityHelper.findEntityByIndex(keys.player);
	if player then
		local hero = player:GetAssignedHero();
		if hero then
			hero:SetAbilityPoints(0);
		end
	end

end

return m
