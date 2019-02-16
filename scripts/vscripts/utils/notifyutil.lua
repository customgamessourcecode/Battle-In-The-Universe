local m = {}
---发送顶端提示消息
--@param #number PlayerID 接收消息的玩家id，为空，则发送给所有人
--@param #string text 消息文本 ，支持"#xxx" 的国际化形式
--@param #number duration 消息持续时间
--@param #string color 消息颜色(html标准，颜色名，比如green，yellow等；或者#XXXXXX)
--@param #boolean continue 表示是否要把当前这条信息和上一条拼接成一条信息来显示
--@param #table styles CSS样式，可以给消息Label额外加样式，比如{["background-color"]="rgba(128,0,0, 0.6)"}
function m.Top(PlayerID,text,duration,color,continue,styles)
	local msg = {["text"]=text,["duration"]=duration,["style"]={["color"]=color},["continue"]=continue or false}
	
	if type(styles) == "table" then
		for key, var in pairs(styles) do
			msg.style[key] = var
		end
	end
	
	if PlayerID and PlayerResource:IsValidPlayer(PlayerID)  then
		Notifications:Top(PlayerID,msg);
	else
		Notifications:TopToAll(msg)
	end
end

---发送底部提示消息
--@param #number PlayerID 接收消息的玩家id，为空，则发送给所有人
--@param #string text 消息文本 ，支持"#xxx" 的国际化形式
--@param #number duration 消息持续时间
--@param #string color 消息颜色(html标准，颜色名，比如green，yellow等；或者#XXXXXX)
--@param #boolean continue 表示是否要把当前这条信息和上一条拼接成一条信息来显示
--@param #table styles CSS样式，可以给消息Label额外加样式，比如{["background-color"]="rgba(128,0,0, 0.6)"}
function m.Bottom(PlayerID,text,duration,color,continue,styles)
	local msg = {["text"]=text,["duration"]=duration,["style"]={["color"]=color},["continue"]=continue or false}
	
	if type(styles) == "table" then
		for key, var in pairs(styles) do
			msg.style[key] = var
		end
	end
	
	if PlayerID and PlayerResource:IsValidPlayer(PlayerID) then
		Notifications:Bottom(PlayerID,msg);
	else
		Notifications:BottomToAll(msg)
	end
end

---发送唯一性底部消息，重复显示的时候只会显示一条，不支持拼接
--@param #number PlayerID 接收消息的玩家id，为空，则发送给所有人
--@param #string text 消息文本 ，支持"#xxx" 的国际化形式
--@param #number duration 消息持续时间
--@param #string color 消息颜色(html标准，颜色名，比如green，yellow等；或者#XXXXXX)
--@param #table styles CSS样式，可以给消息Label额外加样式，比如{["background-color"]="rgba(128,0,0, 0.6)"}
function m.BottomUnique(PlayerID,text,duration,color,styles)
	if text then
		local msg = {["text"]=text,["duration"]=duration,["style"]={["color"]=color}}
		
		if type(styles) == "table" then
			for key, var in pairs(styles) do
				msg.style[key] = var
			end
		end
		
		if PlayerID and PlayerResource:IsValidPlayer(PlayerID) then
			Notifications:ClearBottom(PlayerID,text)
			Notifications:Bottom(PlayerID,msg);
		else
			Notifications:ClearBottomFromAll(text)
			Notifications:BottomToAll(msg)
		end
	end
end

---将给定的信息拼接显示在底部
--@param #number PlayerID 接收消息的玩家id，为空，则发送给所有人
--@param #table textGroup 所有的消息文本，按照table中的顺序拼接成最终显示的文本（支持 "#xxx" 的国际化形式）
--@param #number duration 消息持续时间
--@param #string color 消息颜色(html标准，颜色名，比如green，yellow等；或者#XXXXXX)
--@param #table styles CSS样式，可以给消息Label额外加样式，比如{["background-color"]="rgba(128,0,0, 0.6)"}（Error信息的背景色）
function m.BottomGroup(PlayerID,textGroup,duration,color,styles)
	if type(textGroup) == "table" and #textGroup > 0 then
		for i, text in ipairs(textGroup) do
			if i == 1 then
				m.Bottom(PlayerID,text,duration,color,false,styles)
			else
				m.Bottom(PlayerID,text,duration,color,true,styles)
			end
		end
	end
end

---将给定的信息拼接显示在底部，并且显示唯一，<font color="red">以group的第一个文本作为id保证唯一性</font>
--@param #number PlayerID 接收消息的玩家id，为空，则发送给所有人
--@param #table textGroup 所有的消息文本，按照table中的顺序拼接成最终显示的文本（支持 "#xxx" 的国际化形式）
--@param #number duration 消息持续时间
--@param #string color 消息颜色(html标准，颜色名，比如green，yellow等；或者#XXXXXX)
--@param #table styles CSS样式，可以给消息Label额外加样式，比如{["background-color"]="rgba(128,0,0, 0.6)"}（Error信息的背景色）
function m.BottomGroupUnique(PlayerID,textGroup,duration,color,styles)
	if type(textGroup) == "table" and #textGroup > 0 then
		local id = textGroup[1]
		m.clearBottom(PlayerID,id)
	
		for i, text in ipairs(textGroup) do
			if i == 1 then
				m.Bottom(PlayerID,text,duration,color,false,styles)
			else
				m.Bottom(PlayerID,text,duration,color,true,styles)
			end
		end
	end
end

---清除某玩家底部的所有提示信息
--@param #number PlayerID 玩家id
--@param #string text 删除展示内容是这个text的所有的消息，可以是国际化形式 #xxx。注意：如果信息文本是拼接出来的(用continue属性)，则这里只需要传入拼接语句的第一个文本即可
function m.clearBottom(PlayerID,text)
	Notifications:ClearBottom(PlayerID,text)
end

---显示一个错误信息：显示在底部、红底白字，并有声音提示
function m.ShowError(PlayerID,text,duration,continue)
	if text then
		local msg = {
			text=text,
			duration=duration,
			error=1,
			continue = continue
		}
		if PlayerID and PlayerResource:IsValidPlayer(PlayerID) then
			Notifications:ClearBottom(PlayerID,text)
			Notifications:Bottom(PlayerID,msg);
			EmitSoundForPlayer("ui.error",PlayerUtil.GetPlayer(PlayerID))
		else
			Notifications:ClearBottomFromAll(text)
			Notifications:BottomToAll(msg)
		end
	end
end

---在左下角显示一条系统信息。
--@param #number PlayerID 玩家id，为空的时候发送给所有玩家
--@param #any textGroup 文本信息。可以是字符串或者一个包含字符串的表，支持国际化形式#xxx。如果为空，则不发送
--@param #number duration 持续时间，持续时间结束后，将隐藏该信息。默认3秒
function m.ShowSysMsg(PlayerID,textGroup,duration)
	if textGroup then
		if type(textGroup) == "string" then
			textGroup = {textGroup}
		end
		
		duration = duration or 3
		
		if PlayerID then
			SendToClient(PlayerID,"xxdld_show_sys_msg",{msg=textGroup,duration=duration})
		else
			SendToAllClient("xxdld_show_sys_msg",{msg=textGroup,duration=duration})
		end
	end
end

return m;
