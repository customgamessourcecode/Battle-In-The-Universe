local m = {}
local thinks = {}

---注册一类塔的技能释放规则。<p>
--默认的Ai里面有一套基本的释放规则，仅仅根据技能类型来判断。
--有些技能可能需要特殊的逻辑，此时需要注册一个自定义的处理函数<p>
--abilityExecutor函数的传入参数有：<br>
--tower：释放技能的塔<br>
--ai：ai实体<br>
--@param #string towerName 塔的单位名字
--@param #function abilityExecutor 技能释放逻辑，一个函数
function m.Register(towerName,abilityExecutor)
	if type(towerName) == "string" and type(abilityExecutor) == "function" then
		thinks[towerName] = abilityExecutor
	end
end

---获取一类塔的技能释放处理函数，没有的话，返回nil<p>
--调用参数有：<br>
--tower：释放技能的塔<br>
--ai：ai实体<br>
--@param #string towerName 塔的单位名字
function m.GetAbilityExecutor(towerName)
	if type(towerName) == "string" then
		return thinks[towerName]
	end
end

return m