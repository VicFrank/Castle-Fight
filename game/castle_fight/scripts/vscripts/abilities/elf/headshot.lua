archer_headshot = class({})

LinkLuaModifier("modifier_archer_headshot", "abilities/elf/headshot", LUA_MODIFIER_MOTION_NONE)

function archer_headshot:GetIntrinsicModifierName()
  return "modifier_archer_headshot"
end

modifier_archer_headshot = class({})

function modifier_archer_headshot:OnCreated()
  if not IsServer() then return end

  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()
  
  self.chance = self.ability:GetSpecialValueFor("chance")
  self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
  self.damage = self.ability:GetSpecialValueFor("damage")
end

function modifier_archer_headshot:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_archer_headshot:OnAttackLanded(params)
  if not IsServer() then return end

  local caster = params.attacker
  local target = params.target
  local ability = self:GetAbility()

  if caster == self:GetCaster() and not IsCustomBuilding(target) then
    if self.chance >= RandomInt(1, 100) then

      target:AddNewModifier(target, ability, "modifier_stunned", {duration = self.stun_duration})
    
      -- Deal damage
      ApplyDamage({
        victim = target,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        attacker = caster,
        ability = ability
      })
    end
  end
end

function modifier_archer_headshot:IsPurgeException()
  return false
end

function modifier_archer_headshot:IsPurgable()
  return false
end

function modifier_archer_headshot:IsHidden()
  return true
end