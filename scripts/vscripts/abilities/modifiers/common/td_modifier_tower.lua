---塔的buff。主要是为了限制塔不能移动。
--如果直接设置单位不能移动，有目标的技能将不能正常释放；
--如果设置可移动，但是速度设置为0，不知道为毛线会自动多一个100移速的buff，导致塔可以移动。
--（应该是dota限制最小移动速度为100了，使用modifier的最小移速和绝对移速都无法修改该属性）
--只能设置目标被固定状态
if td_modifier_tower == nil then
	td_modifier_tower = class({})
	
	local m = td_modifier_tower;
	
	--无敌保持
	function m:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE;
	end
	
	function m:IsHidden()
		return true;
	end
	
	--是否可以被净化
	function m:IsPurgable()
		return false;
	end
	
	function m:CheckState()
		local state = {
			[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true
		}
	 
		return state
	end
end

