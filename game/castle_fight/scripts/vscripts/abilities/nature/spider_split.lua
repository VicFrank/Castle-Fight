LinkLuaModifier("modifier_giant_spider_split", "abilities/nature/spider_split.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brood_mother_split", "abilities/nature/spider_split.lua", LUA_MODIFIER_MOTION_NONE)

giant_spider_split = class({})
function giant_spider_split:GetIntrinsicModifierName() return "modifier_giant_spider_split" end
brood_mother_split = class({})
function brood_mother_split:GetIntrinsicModifierName() return "modifier_brood_mother_split" end

modifier_giant_spider_split = class({})

function modifier_giant_spider_split:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_giant_spider_split:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    for i=1,2 do
      local unitName = "forest_spider"
      local position = self:GetParent():GetAbsOrigin()
      local team = self:GetParent():GetTeam()
      local playerID = self:GetParent().playerID
      CreateLaneUnit(unitName, position, team, playerID)
    end
  end
end

modifier_brood_mother_split = class({})

function modifier_brood_mother_split:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_brood_mother_split:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    local unitName = "giant_spider"
    local position = self:GetParent():GetAbsOrigin()
    local team = self:GetParent():GetTeam()
    local playerID = self:GetParent().playerID
    CreateLaneUnit(unitName, position, team, playerID)
  end
end