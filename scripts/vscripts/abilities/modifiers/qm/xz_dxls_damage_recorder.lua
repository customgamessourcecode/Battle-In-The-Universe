--求魔——玄葬：毒性连琐
if xz_dxls_damage_recorder == nil then
	xz_dxls_damage_recorder = class({})
	
	local m = xz_dxls_damage_recorder;
	
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
	
	function m:DeclareFunctions()
	  local funcs = {
	     MODIFIER_EVENT_ON_TAKEDAMAGE,
	     MODIFIER_EVENT_ON_DEATH
	  }
	  return funcs;
	end
	
	function m:OnTakeDamage(keys)
		if IsServer() then
			self._damage = (self._damage or 0) + keys.damage
		end
	end
	
	function m:OnDeath(keys)
		if IsServer() then
			local unit = keys.unit
			if unit == self:GetParent() and self._damage then
				local caster = self:GetCaster()
				local ability = self:GetAbility()
				local radius = GetAbilitySpecialValueByLevel(ability,"radius")
				local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
				
				local loc = unit:GetAbsOrigin()
				
				EmitSoundOnLoc(loc,"Ability.SandKing_CausticFinale",caster)
				
				--放了特效也看不清，就不要了。
--				local path = "particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf"
--				CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,unit)
				
				DamageEnemiesWithinRadius(loc,radius,caster,self._damage * ratio / 100,ability)
			end
		end
	end
end

