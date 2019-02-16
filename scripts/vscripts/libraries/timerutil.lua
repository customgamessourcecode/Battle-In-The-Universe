require('libraries.timers') --可以用来方便的创建定时器

local m = {}

---创建一个立即执行的计时器（依赖于游戏时间），返回计时器名字。
--@param #function func 执行函数
function m.createTimer(func)
  return Timers:CreateTimer(func);
end

---创建一个延迟执行的计时器（依赖于游戏时间），返回计时器名字
--@param #number delay 延迟时间,单位秒
--@param #function func 执行函数
function m.createTimerWithDelay(delay,func)
	return Timers:CreateTimer(delay,func);
end

---创建一个立即执行，且包含上下文的计时器（依赖于游戏时间），返回计时器名字。
--@param #function func 执行函数
--@param #any context 上下文
function m.createTimerWithContext(func,context)
  return Timers:CreateTimer(func,context);
end

--****************************下面是依赖于现实时间的计时器***********************

---创建一个立即执行的计时器（依赖于现实时间），返回计时器名字
--@param #function func 执行函数
function m.createTimerWithRealTime(func)
  return Timers:CreateTimer({
		useGameTime = false,
		callback = func
	});
end

---创建一个延迟执行的计时器（依赖于现实时间），返回计时器名字。时间单位秒
--@param #number delay 延迟时间,单位秒
--@param #function func 执行函数
function m.createTimerWithDelayAndRealTime(delay,func)
	return Timers:CreateTimer({
		useGameTime = false,
		endTime = delay,
		callback = func
	});
end

---根据计时器名字移除计时器
function m.removeTimer(name)
	if name then
		Timers:RemoveTimer(name)
	end
end

return m;