LinkLuaModifier("modifier_overtake", "abilities/corrupted/overtake.lua", LUA_MODIFIER_MOTION_NONE)

incubus_overtake = class({})
function incubus_overtake:GetIntrinsicModifierName() return "modifier_overtake" end

modifier_overtake = class({})

function modifier_overtake:IsHidden() return true end

function modifier_overtake:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
end

function modifier_overtake:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_overtake:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) and not target:IsLegendary() then
    if self.chance >= RandomInt(1, 100) then
      local position = target:GetAbsOrigin()
      local relative_health = target:GetHealthPercent() * 0.01
      if relative_health == 0 then return end
      local fv = target:GetForwardVector()
      local unitName = target:GetUnitName()
      local playerID = self.parent.playerID
      local team = self.parent:GetTeam()
      local new_unit = CreateLaneUnit(unitName, position, team, playerID)
      new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
      new_unit:SetMana(target:GetMana())
      new_unit:SetForwardVector(fv)
      FindClearSpaceForUnit(new_unit, position, true)

      target:RemoveSelf()
    end
  end
end
