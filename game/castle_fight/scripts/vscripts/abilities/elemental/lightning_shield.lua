lightning_shield = class({})

LinkLuaModifier("modifier_lightning_shield", "abilities/elemental/lightning_shield.lua", LUA_MODIFIER_MOTION_NONE)

function lightning_shield:GetIntrinsicModifierName() return "modifier_lightning_shield" end
-----------------------------

modifier_lightning_shield = class({})

function modifier_lightning_shield:IsHidden() return true end

function modifier_lightning_shield:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
  self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
end

function modifier_lightning_shield:OnRefresh()
  self.chance = self.ability:GetSpecialValueFor("chance")
  self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
end

function modifier_lightning_shield:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_lightning_shield:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if target == self.parent and IsValidAlive(attacker) then
    local distance = GetDistanceBetweenTwoUnits(target, attacker)

    if distance < 150 and RollPercentage(self.chance) then
      -- shoot lightning, stun target
      local particleName = "particles/units/heroes/hero_razor/razor_storm_lightning_strike.vpcf"
      particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, attacker)
      ParticleManager:SetParticleControl(particle, 0, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,1000)) -- height of the bolt
      ParticleManager:SetParticleControl(particle, 1, attacker:GetAbsOrigin()) -- point landing
      ParticleManager:SetParticleControl(particle, 2, attacker:GetAbsOrigin()) -- point origin  
      ParticleManager:ReleaseParticleIndex(particle) 

      target:EmitSound("Ability.static.start")

      attacker:AddNewModifier(self.caster, self.ability, "modifier_stunned", {stun_duration})
    end
  end
end
