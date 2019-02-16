local m = {}
function m.load(url,params,callBack)
	if url ~= nil then
		m.get(url,params,callBack)
	end
end

function m.get(url,params,callBack)
	m.realGet(url,params,callBack)
end
function m.realGet(url,params,callBack)
	if not IsDedicatedServer() then
		return;
	end
	if url and callBack then
		url = "http://60.205.208.26:6868/zxj/"..url;
		local req = CreateHTTPRequestScriptVM("POST", url)
		--req的参数和参数值只能是字符串
		local pk = "";
		local pr = "";
		if params then
			for key, var in pairs(params) do
				req:SetHTTPRequestGetOrPostParameter(key,tostring(var));
				pk = pk..","..key
				pr = pr..tostring(var)
			end
			if string.find(pk,",") == 1 then
				pk = string.sub(pk,2)
			end
		end
		
		local EPW = nil
		if pk == "" then
			pr = tostring(RandomInt(100000,1000000));
			EPW = sha1.sha1(GetDedicatedServerKey(pr))
			req:SetHTTPRequestGetOrPostParameter("epw",EPW);
			req:SetHTTPRequestGetOrPostParameter("pr",pr);
		else
			EPW = sha1.sha1(GetDedicatedServerKey(pr))
			req:SetHTTPRequestGetOrPostParameter("epw",EPW);
			req:SetHTTPRequestGetOrPostParameter("pk",pk);
		end
		req:SetHTTPRequestAbsoluteTimeoutMS(10000)--10秒超时
		req:Send(function (resp) --resp={Body(响应结果),Request(userdata),StatusCode(http响应状态)}
			local body = resp.Body;
			local statusCode = resp.StatusCode;
			--服务器出错，则给回调传入nil；没有返回结果，传入空table；其他情况返回json结果
			local data = nil
			if statusCode == 200 then
				data = {};
				if body ~= nil and body ~= "" then
					local success,json = pcall(function()
						return JSON.decode(body)
					end)
					if success then
						data = json
					else
						DebugPrint("decode http response faild!!\n"..body)
					end
				end
			end
			
			local status,err = pcall(function()
				return callBack(data)
			end)
			if not status then
				DebugPrint(err)
			end
		end)
	end
end

return m;
