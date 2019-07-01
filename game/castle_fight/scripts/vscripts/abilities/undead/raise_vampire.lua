raise_lesser_vampire = class({})
raise_vampire = class({})
LinkLuaModifier("modifier_raise_lesser_vampire", "abilities/undead/raise_vampire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_raise_vampire", "abilities/undead/raise_vampire.lua", LUA_MODIFIER_MOTION_NONE)

function raise_lesser_vampire:GetIntrinsicModifierName()
  return "modifier_raise_lesser_vampire"
end
function raise_vampire:GetIntrinsicModifierName()
  return "modifier_raise_vampire"
end

modifier_raise_lesser_vampire = class({})
modifier_raise_vampire = class({})

function modifier_raise_lesser_vampire:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_raise_lesser_vampire:OnDeath(params)
  if not IsServer() then return end

  if params.attacker == self:GetParent() then
    local unitname = "lesser_vampire"
    local position = params.unit:GetAbsOrigin()
    local team = self:GetParent():GetTeam()
    local playerID = self:GetParent().playerID

    local vampire = CreateLaneUnit(unitname, position, team, playerID)

    local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    ParticleManager:SetParticleControl(particle, 0, vampire:GetAbsOrigin())
    vampire:EmitSound("ui.trophy_levelup")
  end
end

function modifier_raise_vampire:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_raise_vampire:OnDeath(params)
  if not IsServer() then return end

  if params.attacker == self:GetParent() then
    local unitname = "vampire"
    local position = params.unit:GetAbsOrigin()
    local team = self:GetParent():GetTeam()
    local playerID = self:GetParent().playerID
    
    local vampire = CreateLaneUnit(unitname, position, team, playerID)

    local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    ParticleManager:SetParticleControl(particle, 0, vampire:GetAbsOrigin())
    vampire:EmitSound("ui.trophy_levelup")
  end
end