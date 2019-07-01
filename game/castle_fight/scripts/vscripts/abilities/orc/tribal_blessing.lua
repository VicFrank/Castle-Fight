tribal_blessing = class({})

LinkLuaModifier("modifier_tribal_blessing", "abilities/orc/tribal_blessing.lua", LUA_MODIFIER_MOTION_NONE)

function tribal_blessing:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local allies = FindAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local target = FindFirstUnit(allies, function(target)
    return not IsCustomBuilding(target) and not target:IsRealHero()
  end)

  if not target then return end

  local abilities = {
    "tribal_blessing_critical_strike",
    "tribal_blessing_evasion",
    "tribal_blessing_demolish",
  }

  local abilityToAdd = GetRandomTableElement(abilities)

  if target:HasAbility(abilityToAdd) then
    for _,abilityName in ipairs(abilities) do
      if not target:HasAbility(abilityName) then
        abilityToAdd = abilityName
        break
      end
    end
  end

  local ability = target:AddAbility(abilityToAdd)
  ability:SetLevel(1)
  target:AddNewModifier(caster, ability, "modifier_tribal_blessing", {})
end

modifier_tribal_blessing = class({})

function modifier_tribal_blessing:OnCreated()
  self.damage_increase = self:GetAbility():GetSpecialValueFor("damage_increase")
  self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
  self.health = self:GetAbility():GetSpecialValueFor("health")
end

function modifier_tribal_blessing:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_tribal_blessing:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_tribal_blessing:GetModifierHealthBonus()
  return self.health
end

function modifier_tribal_blessing:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_tribal_blessing:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage_increase
end