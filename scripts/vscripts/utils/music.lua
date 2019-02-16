local m = {}

---所有音乐的配置信息。每一个配置元素包括四个参数：
--<ol>
--	<li>播放实体（音乐将在该实体上进行播放）</li>
--	<li>音乐名称</li>
--	<li>音乐时长</li>
--	<li>音乐类型：{1=角色曲,2=气势曲,3=琴武戏,4=战斗曲,5=特殊曲}</li>
--</ol>
m.music_table = {
	{"music_console","chiwufengtianliu",133.0,3},--赤舞凤天流 琴武戏
	{"music_console","data1070",92.0,3},			--持国天王 琴武戏
	{"music_console","feiyuyuanji",211.0,1},		--绯羽怨姬 角色曲
	{"music_console","fengduyue",202.0,2},		--酆都月 气势曲
	{"music_console","fengpolinyun",101.0,3},		--风破凌云 琴武戏
	{"music_console","fuxishentianxiang",180.0,5},	--伏羲神天降 琴武戏
	{"music_console","hanzhiyun",44.0,2},		--汉之云 气势曲
	{"music_console","jianwuqinyang",101.0,3},	--剑舞琴扬 琴武戏
	{"music_console","jinziling",82.0,1},	--金子凌 角色曲
	{"music_console","liming",120.0,1},	--黎民 角色曲
	{"music_console","moshenluan",94.0,2},--魔神乱 气势曲
	{"music_console","nanyangdu",77.0,2},--南阳度 气势曲
	{"music_console","sangeren",71.0,5},--三个人 气势曲
	{"music_console","shiigujiasha",173.0,3},--蚳蠱蛺殺 琴武戏
	{"music_console","shuixuyinyue",180.0,3},--水盈虚月 琴武戏
	{"music_console","tianfengmuyu",192.0,2},--天风沐雨	气势曲
	{"music_console","tianjiangfenhong",99.0,2},--天将枫红
	{"music_console","xiaozhan",91.0,4},--骁战 战斗曲
	{"music_console","zhuqufeixiang",190.0,1},--竹取飞翔 角色曲
	{"music_console","zhuxianqu",92.0,4},--诛仙曲 战斗曲
}
---当前播放的音乐类型。
--<ol>
--	<li>角色曲</li>	<li>气势曲</li>	<li>琴武戏</li>	<li>战斗曲</li>	<li>特殊曲</li>
--</ol>
m.type = 1
---当前播放音乐的状态。每次切换音乐(随机或者指定)或停止所有音乐的时候，都会进一位。<p>
--在当前音乐持续时间结束的时候进行判断：如果和开始时候的状态一致，则认为播放器状态没有被其他逻辑改变，将自动循环新歌曲
m.state = 0

---播放指定的背景音乐，并返回该音乐信息
--@param #table__string music 音乐配置信息或者音乐的名称。如果是音乐名称，但是找不到对应音乐的配置，则会随机播放一首音乐
--@return #table 音乐配置信息(可能为空)
function m.EmitBGM(music)
	local musicConfig = music;
	--如果是名字，则获取对应的音乐配置
	if type(musicConfig) == "string" then
		for _,config in pairs(m.music_table) do
			if config[2] == musicConfig then
				musicConfig = config;
				break;
			end
		end
	end
	--如果没有音乐配置信息，则随机一个
	if not musicConfig then
		musicConfig = m.RandomMusic(m.type)
	end
	--随机不到说明音乐类型可能是错误的，暂时不处理
	if musicConfig then
		local ent = Entities:FindByName(nil, musicConfig[1])
		if ent ~= nil then
			EmitSoundOn(musicConfig[2],ent) --最终播放音乐的关键
		end
	end
	return musicConfig;
end

---停止播放所有的背景音乐
function m.StopAll()
	m.state = m.state + 1 --更换状态，这样已经存在的计时器在结束的时候，就不会自动切歌导致停止音乐失效
	for k,v in pairs(m.music_table) do
		local ent = Entities:FindByName(nil, v[1])
		if ent ~= nil then
			StopSoundOn(v[2],ent)
		end
	end
end

---随机返回一首给定类型的音乐。如果没有给定类型的音乐，则返回nil
--@param #number type 音乐类型。1：角色曲 ，2：气势曲，3：琴武戏，4：战斗曲，5：特殊曲
--@return #table 返回随机到的音乐配置信息
function m.RandomMusic( type )
	local musiclist = {}
	for _,config in pairs(m.music_table) do
		if config[4] == type then
			table.insert(musiclist,config)
		end
	end
	if #musiclist > 0 then
		return musiclist[RandomInt(1, #musiclist)]
	end
end

---停止所有的背景音乐，然后随机一个背景音乐并播放,音乐类型由music.type决定。<p>
--如果音乐正常播放结束，则继续循环随机。
function m.PlayRandomMusic()
	m.StopAll()
	local music = m.RandomMusic(m.type)
	--播放状态改变。如果音乐播放完毕以后，状态没有变化，则
	local nowState = m.state;
	m.EmitBGM(music)
	TimerUtil.createTimerWithDelayAndRealTime(music[3],function()
		--这个判断主要是用来判断，当前背景音乐是否因为其他原因而改变了。
		--如果已经改变，则这里不再处理。否则，切换一个当前状态下其他音乐
		if nowState == m.state then
			m.state = m.state + 1
			m.PlayRandomMusic()
		end
	end)
	
end

---停止所有背景音乐，然后播放指定的音乐。
--<ul>
--	<li>如果指定音乐存在，则播放，播放结束后，进入随机播放循环（PlayRandomMusic）</li>
--	<li>如果指定音乐不存在，则随机播放一首</li>
--</ul>
--@param #table__string music 音乐配置信息或者名称。如果是名称，并且找不到对应的音乐配置信息，则会随机一首当前类型的歌曲
function m.PlayTargetMusic(music)
	m.StopAll();
	local nowState = m.state
	local musicTable = m.EmitBGM(music)
	if musicTable then --持续时间结束后，进入随机播放
		TimerUtil.createTimerWithDelayAndRealTime(musicTable[3],function()
			if nowState == m.state then
				m.PlayRandomMusic()
			end
		end)
	end
end


---停止所有背景音乐，然后播放<b style="color:red;">指定类型</b>的音乐。<p>
--如果指定音乐存在，则播放，播放结束后，进入随机播放循环（PlayRandomMusic）<br/>
--如果指定音乐不存在，则随机播放一首
--@param #number musicType 音乐类型 
--<ol>
--	<li>角色曲</li>	<li>气势曲</li>	<li>琴武戏</li>	<li>战斗曲</li>	<li>特殊曲</li>
--</ol>
function m.PlayTargetTypeMusic(musicType)
	m.PlayTargetMusic(m.RandomMusic(musicType))
end
return m;
