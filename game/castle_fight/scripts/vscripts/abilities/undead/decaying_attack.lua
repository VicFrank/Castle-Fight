lich_decaying_attack = class({})
LinkLuaModifier("modifier_decaying_attack", "abilities/undead/decaying_attack.lua", LUA_MODIFIER_MOTION_NONE)

function lich_decaying_attack:GetIntrinsicModifierName()
  return "modifier_decaying_attack"
end

modifier_decaying_attack = class({})

function modifier_decaying_attack:IsPurgable()
  return false
end

function modifier_decaying_attack:IsHidden()
  return true
end

function modifier_decaying_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.soul_steal_chance = self.ability:GetSpecialValueFor("soul_steal_chance")
  self.soul_steal_absorb = self.ability:GetSpecialValueFor("soul_steal_absorb")
  self.death_and_decay_chance = self.ability:GetSpecialValueFor("death_and_decay_chance")
  self.death_and_decay_aoe = self.ability:GetSpecialValueFor("death_and_decay_aoe")
  self.death_and_decay_duration = self.ability:GetSpecialValueFor("death_and_decay_duration")
  self.death_and_decay_drain = self.ability:GetSpecialValueFor("death_and_decay_drain")
end

function modifier_decaying_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_decaying_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    if self.soul_steal_chance >= RandomInt(1,100) and not target:IsLegendary() then
      -- Instantly kill the target, gain 50% of its health
      local healAmount = target:GetHealth() * self.soul_steal_absorb * 0.01
      target:Kill(self.ability, self.parent)
      self.caster:Heal(healAmount, self.caster)
    elseif self.death_and_decay_chance >= RandomInt(1,100) then
      -- Casts death and decay centerd on the target
      CreateModifierThinker(self.caster, self.ability, "modifier_death_and_decay",
        {duration = self.death_and_decay_duration}, target:GetAbsOrigin(),
        self.caster:GetTeam(), false)
    end
  end
end

modifier_death_and_decay = class({})
LinkLuaModifier("modifier_death_and_decay", "abilities/undead/decaying_attack", LUA_MODIFIER_MOTION_NONE)

function modifier_death_and_decay:IsHidden()
  return true
end

function modifier_death_and_decay:OnCreated()
  if not IsServer() then return end

  self.ability = self:GetAbility()
  self.caster = self:GetCaster()
  self.parent = self:GetParent()

  self.radius = self.ability:GetSpecialValueFor("death_and_decay_aoe")
  self.damage = self.ability:GetSpecialValueFor("damage_percent") / 100

  self.team = self.caster:GetTeam()
  
  self:StartIntervalThink(1)

  local particleName = "particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, self.parent)
  ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, 1, 1))
  self:AddParticle(particle, false, false, 0, false, false)
  self:GetParent():EmitSound("Hero_Enigma.Midnight_Pulse")
end

function modifier_death_and_decay:OnDestroy()
  if IsServer() then self.parent:StopSound("Hero_Enigma.Midnight_Pulse") end
end

function modifier_death_and_decay:OnIntervalThink()
  if not IsServer() then return end

  local enemies = FindEnemiesInRadiusFromTeam(self.team, self.radius, self.parent:GetAbsOrigin())
  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) then
      local damage = ApplyDamage({
        victim = enemy,
        damage = enemy:GetMaxHealth() * self.damage,
        damage_type = DAMAGE_TYPE_PURE,
        attacker = self.caster,
        ability = self.ability
      })
    end
  end
end