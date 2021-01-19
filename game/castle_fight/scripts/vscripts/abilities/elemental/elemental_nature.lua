elemental_nature = class({})

LinkLuaModifier("modifier_elemental_nature", "abilities/elemental/elemental_nature.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_nature_discharge", "abilities/elemental/elemental_nature.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_nature_boulder", "abilities/elemental/elemental_nature.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_nature_immolation", "abilities/elemental/elemental_nature.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_nature_shield_of_mist", "abilities/elemental/elemental_nature.lua", LUA_MODIFIER_MOTION_NONE)

function elemental_nature:GetIntrinsicModifierName() return "modifier_elemental_nature_boulder" end

modifier_elemental_nature = class({})

function modifier_elemental_nature:IsHidden() return true end

function modifier_elemental_nature:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  -- randomly grant an elemental nature ability
  local abilityNames = {
    "elemental_nature_discharge",
    "elemental_nature_boulder",
    "elemental_nature_immolation",
    "elemental_nature_shield_of_mist",
  }

  local abilityToAdd = GetRandomTableElement(abilityNames)

  local addedAbility = self.parent:AddAbility(abilityToAdd)
  addedAbility:SetLevel(1)
end

elemental_nature_discharge = class({})

function elemental_nature_discharge:GetIntrinsicModifierName() return "modifier_elemental_nature_discharge" end

modifier_elemental_nature_discharge = class({})

function modifier_elemental_nature_discharge:IsHidden() return true end

function modifier_elemental_nature_discharge:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage = self.ability:GetSpecialValueFor("damage")
  self.interval = self.ability:GetSpecialValueFor("interval")
  self.radius = self.ability:GetSpecialValueFor("radius")
end

elemental_nature_boulder = class({})

function elemental_nature_boulder:GetIntrinsicModifierName() return "modifier_elemental_nature_boulder" end

modifier_elemental_nature_boulder = class({})

function modifier_elemental_nature_boulder:IsHidden() return true end

function modifier_elemental_nature_boulder:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
  self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
  self.damage = self.ability:GetSpecialValueFor("damage")
end

function modifier_elemental_nature_boulder:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL
  }
  return funcs
end

function modifier_elemental_nature_boulder:OnAttack(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent then
    if IsCustomBuilding(target) then return end
    local rockParticle = "particles/econ/events/ti9/rock_golem_tower/dire_tower_attack.vpcf"
    local normalParticle = "particles/econ/world/towers/ti10_dire_tower/ti10_dire_tower_attack.vpcf"

    if RollPercentage(self.chance) then
      print("Bash")
      attacker:SetRangedProjectileName(rockParticle)
      self.nextHitBash = true
    else
      print("Not bash")
      attacker:SetRangedProjectileName(normalParticle)
    end
  end
end

function modifier_elemental_nature_boulder:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent then
    if self.nextHitBash then
      self.nextHitBash = false
      target:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = self.stun_duration})
    end
  end
end

function modifier_elemental_nature_boulder:GetModifierProcAttack_BonusDamage_Magical()
  if self.nextHitBash then
    return self.damage
  end

  return nil
end


elemental_nature_immolation = class({})

function elemental_nature_immolation:GetIntrinsicModifierName() return "modifier_elemental_nature_immolation" end

modifier_elemental_nature_immolation = class({})

function modifier_elemental_nature_immolation:IsHidden() return true end

function modifier_elemental_nature_immolation:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.dps = self.ability:GetSpecialValueFor("dps")
  self.interval = self.ability:GetSpecialValueFor("interval")
  self.radius = self.ability:GetSpecialValueFor("radius")
end

elemental_nature_shield_of_mist = class({})

function elemental_nature_shield_of_mist:GetIntrinsicModifierName() return "modifier_elemental_nature_shield_of_mist" end

modifier_elemental_nature_shield_of_mist = class({})

function modifier_elemental_nature_shield_of_mist:IsHidden() return true end

function modifier_elemental_nature_shield_of_mist:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  -- make the unit unattackable by melee
  -- maybe just code this in the ai
end
