LinkLuaModifier("modifier_bash_chance_custom", "abilities/generic/bash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bash_custom", "abilities/generic/bash.lua", LUA_MODIFIER_MOTION_NONE)

gryphon_bash = class({})
function gryphon_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end
crusader_bash = class({})
function crusader_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end
dragon_turtle_bash = class({})
function dragon_turtle_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end
skeleton_warrior_bash = class({})
function skeleton_warrior_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end
bear_bash = class({})
function bear_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end
ancient_protector_bash = class({})
function ancient_protector_bash:GetIntrinsicModifierName() return "modifier_bash_chance_custom" end

modifier_bash_chance_custom = class({})

function modifier_bash_chance_custom:IsHidden() return true end

function modifier_bash_chance_custom:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.bash_duration = self.ability:GetSpecialValueFor("bash_duration")
  self.bash_chance = self.ability:GetSpecialValueFor("bash_chance")
  self.bash_damage = self.ability:GetSpecialValueFor("bash_damage")
end

function modifier_bash_chance_custom:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL
  }
  return funcs
end

function modifier_bash_chance_custom:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_bash_chance_custom:OnAttack(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    if IsCustomBuilding(target) then return end

    local random = RandomInt(1,100)
    if self.bash_chance >= random then
      self.nextHitBash = true
    end
  end
end

function modifier_bash_chance_custom:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    if self.nextHitBash then
      self.nextHitBash = false
      if not IsCustomBuilding(target) then
        target:AddNewModifier(self.caster, self.ability, "modifier_bash_custom", {duration = self.bash_duration})
      end
    end
  end
end

function modifier_bash_chance_custom:GetModifierProcAttack_BonusDamage_Magical()
  if self.nextHitBash then
    return self.bash_damage
  end

  return nil
end

modifier_bash_custom = modifier_bash_custom or class({})

function modifier_bash_custom:IsPurgeException() return true end
function modifier_bash_custom:IsStunDebuff() return true end

function modifier_bash_custom:CheckState()
  local state = {[MODIFIER_STATE_STUNNED] = true}

  return state
end

function modifier_bash_custom:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_bash_custom:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_bash_custom:DeclareFunctions()
  local decFuncs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}

  return decFuncs
end

function modifier_bash_custom:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end
