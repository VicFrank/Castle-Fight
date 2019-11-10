LinkLuaModifier("modifier_frost_attack", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_attack_freeze", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_attack_freeze_fx", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)

hrimthrusa_frost_attack = class({})
function hrimthrusa_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end
ice_troll_frost_attack = class({})
function ice_troll_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end
ice_queen_frost_attack = class({})
function ice_queen_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end

modifier_frost_attack = class({})

function modifier_frost_attack:IsHidden() return true end

function modifier_frost_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
  self.chance = self.ability:GetSpecialValueFor("chance")
end

function modifier_frost_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_frost_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not target:HasFlyMovementCapability() and
    not IsCustomBuilding(target) and self.chance >= RandomInt(1, 100) then
    local debuffName = "modifier_frost_attack_freeze"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

----------------------------------------------------------------------------------------------------

modifier_frost_attack_freeze = class({})

function modifier_frost_attack_freeze:IsDebuff()
  return true
end

function modifier_frost_attack_freeze:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_frost_attack_freeze:OnCreated( kv )
  if IsServer() then
    self.caster = self:GetCaster()
    self.dps = self:GetAbility():GetSpecialValueFor("dps")
    self.playerHero = self:GetCaster():GetPlayerHero()
    local parent = self:GetParent()

    parent:EmitSound("Hero_Crystal.Frostbite")
    local particleNameA = "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
    local particleNameB = "particles/generic_gameplay/generic_slowed_cold.vpcf"
    self.particleA = ParticleManager:CreateParticle(particleNameA, PATTACH_ABSORIGIN_FOLLOW, parent)
    self.particleB = ParticleManager:CreateParticle(particleNameB, PATTACH_POINT_FOLLOW, parent)
    parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_frost_attack_freeze_fx", {duration = self:GetDuration()})

    self:StartIntervalThink(1)
  end
end

function modifier_frost_attack_freeze:OnIntervalThink()
  if IsServer() then
    ApplyDamage({
      attacker = self.playerHero,
      victim = self:GetParent(),
      ability = self:GetAbility(),
      damage = self.dps,
      damage_type = DAMAGE_TYPE_MAGICAL
    })
  end
end

function modifier_frost_attack_freeze:GetEffectName()
  return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_frost_attack_freeze:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frost_attack_freeze:OnDestroy()
  if IsServer() then
    self:GetParent():RemoveModifierByName("modifier_frost_attack_freeze_fx")
    ParticleManager:DestroyParticle(self.particleA, false)
    ParticleManager:DestroyParticle(self.particleB, false)
    ParticleManager:ReleaseParticleIndex(self.particleA)
    ParticleManager:ReleaseParticleIndex(self.particleB)
  end
end

----------------------------------------------------------------------------------------------------

modifier_frost_attack_freeze_fx = class ({})

function modifier_frost_attack_freeze_fx:DeclareFunctions()
  return {}
end

function modifier_frost_attack_freeze_fx:GetStatusEffectName()
  return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_frost_attack_freeze_fx:StatusEffectPriority()
  return FX_PRIORITY_CHILLED
end

function modifier_frost_attack_freeze_fx:IsHidden()
  return true
end

function modifier_frost_attack_freeze_fx:IsDebuff()
  return false
end

function modifier_frost_attack_freeze_fx:IsPurgable()
  return false
end