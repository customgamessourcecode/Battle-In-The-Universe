
function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	if indent == 0 then
		print("{")
	end
	for k, tableKey in ipairs(l) do
		-- Ignore FDesc
		if tableKey ~= 'FDesc' then
			local value = t[tableKey]

			if type(value) == "table" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(tableKey).. "  ("..type(tableKey)..")"..":")
				PrintTable (value, indent + 2, done)
			elseif type(value) == "userdata" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(tableKey)..": "..tostring(value))
				PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
			else
				if t.FDesc and t.FDesc[tableKey] then
					print(string.rep ("\t", indent)..tostring(t.FDesc[tableKey]))
				else
					--普通kv结果显示：key(type):value(type)
					print(string.rep ("\t", indent)..tostring(tableKey).. "  ("..type(tableKey)..")"..": "..tostring(value) .. "  ("..type(value)..")")
				end
			end
		end
	end
	if indent == 0 then
		print("}")
	end
end

function dumpTable(t,msg)
	if msg then
		print("================ "..msg.." ================")
	end
	if type(t) == "table" then
		PrintTable(t)
	elseif t ~= nil then
		print(tostring(t))
	else
		print("nil")
	end
end

function DebugPrint(...)

	if IsInToolsMode() then
		print(...)
	end
end

function DebugPrintTable(...)

	if IsInToolsMode() then
		PrintTable(...)
	end
end


--- 用法:
-- local list = Split("abc,123,345", ",")，list是一个数组。<p>
-- 数组长度 #list，数组元素 list[index] (index从1开始)
function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

--判断一个数是否是小数
function isFloat(num)
	if type(num) ~= "number" then
		return false
	else
		return math.floor(num) < num
	end
end
---将浮点数转为n位小数，如果精度n为nil，则默认是2位
--@param num 数字
--@param n 精度（小数位）
--@param numRes 是否返回数值型结果，如果为否（或nil），则返回字符串
function ParseFloatToDecimal(num,n,numRes)
	n = n or 2;
	local fmt = "%."..n.."f"
	if not isFloat(num) then
		return num
	else
		if numRes then
			return tonumber(string.format(fmt,num))
		else
			return string.format(fmt,num)
		end

	end
end

---将传入的值转换为数值型
--@param value 可以是数值型和字符型，当是字符型的时候，可以包括"%"(如50%)，此时返回的是一个小数(0.5)；其他类型的返回0
--@return 两个返回值，第一个是数值，第二个是个布尔型，表明是否是百分比
function parseNumber(value)
	local isPercent = false --是否是百分比数字
	if type(value) == "string" then --字符型的话判断是否有%
		local percentIndex,_ = string.find(value,"%%");
		if percentIndex ~= nil and percentIndex > 1 then
			isPercent = true
			value = tonumber(string.sub(value,1,percentIndex - 1)) or 0
			value = value / 100 --百分比的求为小数
		else
			value = tonumber(value) or 0
		end
	else
		value = tonumber(value) or 0
	end

	return value,isPercent
end



---位运算测试数值full是否包含target值。如果有一个不是数字，则直接返回false
--@param #number full 测试值
--@param #number target 要检查是否存在的值
--@return #boolean 返回value是否包含test位
function BitAndTest(full,target)
	if type(full) == "number" and type(target) == "number" then
		return target == bit32.band(full,target)
	end
	return false;
end

---获取任意一个table中的非空元素数量
function tableLen(t)
	if t then
		local len = 0;
		for key, var in pairs(t) do
			len = len +1;
		end
		return len;
	end
	return 0
end
