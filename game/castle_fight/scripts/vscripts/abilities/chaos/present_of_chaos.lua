present_of_chaos = class({})

LinkLuaModifier("modifier_present_of_chaos", "abilities/chaos/present_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)

function present_of_chaos:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  -- One of the following happens
  -- The unit explodes (no bounty)
  -- The unit dies (you gain bounty)
  -- The unit transforms into a mutation that fights for you
  -- The unit is hexed
  -- The unit receives 500 damage
  -- The unit gets 400 bonus health and +25 damage and is fully healed
  -- The unit is stunned for 6 seconds and recieves 200 spell damage
  -- Nothing happens

  local options = {
    "EXPLODE",
    "DEATH",
    "MUTATE",
    "HEX",
    "DAMAGE",
    "BUFF",
    "STUN",
    "NOTHING",
  }

  local option = GetRandomTableElement(options)

  print(option)

  if option == "EXPLODE" then
    target:ForceKill(false)
  elseif option == "DEATH" then
    target:Kill(ability, caster)
  elseif option == "MUTATE" then
    CreateLaneUnit("mutation", target:GetAbsOrigin(), target:GetTeam(), caster:GetPlayerOwnerID())
    target:RemoveSelf()
  elseif option == "HEX" then
    target:AddNewModifier(caster, ability, "modifier_hexxed", {duration = 45})
  elseif option == "DAMAGE" then
    ApplyDamage({
      victim = target,
      damage = 500,
      damage_type = DAMAGE_TYPE_PURE,
      attacker = caster,
      ability = ability
    })
  elseif option == "BUFF" then
    target:Heal(target:GetMaxHealth(), ability)
    target:AddNewModifier(caster, ability, "modifier_present_of_chaos", {})
  elseif option == "STUN" then
    target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 6})
    ApplyDamage({
      victim = target,
      damage = 200,
      damage_type = DAMAGE_TYPE_MAGICAL,
      attacker = caster,
      ability = ability
    })
  elseif option == "NOTHING" then
    -- nothing happens
  end
end

modifier_present_of_chaos = class({})

function modifier_present_of_chaos:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_bonus = 25
  self.health_bonus = 400
end

function modifier_present_of_chaos:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
  return funcs
end

function modifier_present_of_chaos:GetModifierExtraHealthBonus()
  return self.health_bonus
end

function modifier_present_of_chaos:GetModifierPreAttack_BonusDamage()
  return self.damage_bonus
end