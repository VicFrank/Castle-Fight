city_of_decay_decay = class({})
LinkLuaModifier("modifier_city_of_decay_aura", "abilities/undead/decay.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_city_of_decay_debuff", "abilities/undead/decay.lua", LUA_MODIFIER_MOTION_NONE)

function city_of_decay_decay:GetIntrinsicModifierName()
  return "modifier_city_of_decay_aura"
end

modifier_city_of_decay_aura = class({})

function modifier_city_of_decay_aura:IsAura()
  return true
end

function modifier_city_of_decay_aura:IsPurgable()
  return false
end

function modifier_city_of_decay_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = 99999
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_city_of_decay_aura:GetModifierAura()
  return "modifier_city_of_decay_debuff"
end

function modifier_city_of_decay_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_city_of_decay_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:IsMechanical()
end

function modifier_city_of_decay_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_city_of_decay_aura:GetAuraDuration()
  return 0.5
end

modifier_city_of_decay_debuff = class({})

function modifier_city_of_decay_debuff:IsPurgable()
  return false
end

function modifier_city_of_decay_debuff:OnCreated()
  if not IsServer() then return end

  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.dps = self.ability:GetSpecialValueFor("dps")

  self:StartIntervalThink(1)
end

function modifier_city_of_decay_debuff:OnIntervalThink()
  if not IsServer() then return end

  local damage = ApplyDamage({
    attacker = self.caster,
    victim = self.parent,
    ability = self.ability,
    damage = self.dps,
    damage_type = DAMAGE_TYPE_PURE,
    damage_flags = DOTA_DAMAGE_FLAG_HPLOSS
  })
end