LinkLuaModifier("modifier_ancient_hydra_split", "abilities/naga/hydra_split.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hydra_split", "abilities/naga/hydra_split.lua", LUA_MODIFIER_MOTION_NONE)

ancient_hydra_split = class({})
function ancient_hydra_split:GetIntrinsicModifierName() return "modifier_ancient_hydra_split" end
hydra_split = class({})
function hydra_split:GetIntrinsicModifierName() return "modifier_hydra_split" end

modifier_ancient_hydra_split = class({})

function modifier_ancient_hydra_split:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_ancient_hydra_split:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    for i=1,2 do
      local unitName = "hydra"
      local position = self:GetParent():GetAbsOrigin()
      local hero = self:GetParent():GetOwner()
      local team = self:GetParent():GetTeam()
      CreateUnitByName(unitName, position, true, hero, hero, team)
    end
  end
end

modifier_hydra_split = class({})

function modifier_hydra_split:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_hydra_split:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    for i=1,2 do
      local unitName = "lesser_hydra"
      local position = self:GetParent():GetAbsOrigin()
      local hero = self:GetParent():GetOwner()
      local team = self:GetParent():GetTeam()
      CreateUnitByName(unitName, position, true, hero, hero, team)
    end
  end
end