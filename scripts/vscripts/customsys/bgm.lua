local m = {}


function m.live()
	if m.entity then
		if m.bgm then
			StopSoundOnEntity(m.entity,m.bgm)
		end
		m.bgm = "bgm_live"
		EmitSound(m.entity,m.bgm)
		
		m.entity:SetContextThink(DoUniqueString("bgm"),function()
			if m.bgm == "bgm_live" then
				m.live()
			end
		end,129)
	else
		DebugPrint("[bgm]:create entity faild")
	end
end

function m.infinite(type)
	if m.entity then
		if m.bgm then
			StopSoundOnEntity(m.entity,m.bgm)
		end
		
		if type == 1 then
			m.bgm = "bgm_infinite1"
			EmitSound(m.entity,m.bgm)
			
			m.entity:SetContextThink(DoUniqueString("bgm"),function()
				if m.bgm == "bgm_infinite1" then
					m.infinite(1)
				end
			end,62)
		elseif type == 2 then
			m.bgm = "bgm_infinite2"
			EmitSound(m.entity,m.bgm)
			
			m.entity:SetContextThink(DoUniqueString("bgm"),function()
				if m.bgm == "bgm_infinite2" then
					m.infinite(2)
				end
			end,125)
		end
	else
		DebugPrint("[bgm]:create entity faild")
	end
end

function m.init()
	if not m.entity then
		m.entity = CreateUnitByName("npc_dummy_unit", Vector(0,0,0), true, nil, nil, TEAM_PLAYER)
		if not m.entity then
			DebugPrint("[bgm]:create entity faild")
		end
	end
end

return m;