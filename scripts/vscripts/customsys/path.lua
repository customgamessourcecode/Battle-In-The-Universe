local m = {
	
}
--extra类的节点，主要是为了让单位尽可能走直线添加的
local map = {
	spawner0 = "path_node_0",
	spawner1 = "path_node_4",
	spawner2 = "path_node_19",
	spawner3 = "path_node_15",
	spawner4 = "path_node_20",
	spawner5 = "path_node_22",
	
	path_node_0 = "path_node_1",
	path_node_1 = {"path_node_2","path_node_8"},
	path_node_2 = {"path_node_1","path_node_3","path_node_6"},
	path_node_3 = {"path_node_2","path_node_11"},
	path_node_4 = "path_node_3",
	path_node_5 = {"path_node_6","path_node_9"},
	path_node_6 = {"path_node_2","path_node_5","path_node_7"},
	path_node_7 = {"path_node_6","path_node_10"},
	path_node_8 = {"path_node_1","path_node_9","path_node_16"},
	path_node_9 = {"path_node_5","path_node_8","path_node_12"},
	path_node_10 = {"path_node_7","path_node_11","path_node_14"},
	path_node_11 = {"path_node_3","path_node_10","path_node_18"},
	path_node_12 = {"path_node_9","path_node_13"},
	path_node_13 = {"path_node_12","path_node_14","path_node_17"},
	path_node_14 = {"path_node_10","path_node_13"},
	path_node_15 = "path_node_16",
	path_node_16 = {"path_node_8","path_node_17"},
	path_node_17 = {"path_node_13","path_node_16","path_node_18"},
	path_node_18 = {"path_node_11","path_node_17"},
	path_node_19 = "path_node_18",
	path_node_20 = "path_node_21",
	path_node_21 = {"path_node_12","path_node_13"},
	path_node_22 = "path_node_23",
	path_node_23 = {"path_node_6","path_node_7"}
}

---移动到下一个节点
--@param #handle unit 单位实体
--@param #boolean init 是否是初始化。初始化的时候，会添加一个额外的定时器
function m.moveNext(unit,init)
	if unit.pathNode then
		--标记正在移动，避免混乱
		unit.ChangingPathNode = true
		pcall(function()
			local next = map[unit.pathNode]
			if type(next) == "table" then
				--有多个位置，随机一个位置移动
				--排除掉之前的节点
				local reachable = {}
				for key, nodeName in ipairs(next) do
					if nodeName ~= unit.previous then
						table.insert(reachable,nodeName)
					end
				end
				if #reachable > 0 then
					next = reachable[RandomInt(1,#reachable)]
				else
					next = next[RandomInt(1,#next)]
				end
			end
			
			local target = EntityHelper.findEntityByName(next)
			if target then
				unit.previous = unit.pathNode
				unit.pathNode = next
				
				unit.targetPos = target:GetAbsOrigin()
				--立即移动，不等think中的逻辑， 那个间隔比较大
				unit:Stop()
				unit:MoveToPosition(unit.targetPos)
				
				
				if init then
					--初始的时候，使用moveToPostion，并不能移动，需要加一个延迟执行才行
					--使用SetInitialGoalEntity倒是能立刻移动，但是那个移动有问题，怪多的时候会导致都走的特别慢
					--另外为了防止某些情况下怪物卡住了就不会动了，这里做一个简单的ai。会移动，会施法
					TimerUtil.createTimerWithDelay(0.2,function()
						EnemyAI:MakeInstance(unit)
					end)
				end
			end
		end)
		unit.ChangingPathNode = nil
	end
end

return m

