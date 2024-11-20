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

function modifier_raise_lesser_vampire:IsHidden() return true end
function modifier_raise_vampire:IsHidden() return true end

function modifier_raise_lesser_vampire:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_raise_lesser_vampire:OnDeath(params)
  if not IsServer() then return end

  if params.attacker == self:GetParent() and not params.unit:IsMechanical() then
    local unitname = "lesser_vampire"
    local position = params.unit:GetAbsOrigin()
    local team = self:GetParent():GetTeam()
    local playerID = self:GetParent().playerID

    local vampire = CreateLaneUnit(unitname, position, team, playerID)
    ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_loadout_bats.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    Timers:CreateTimer(0.5, function()
      ParticleManager:DestroyParticle(particle, false)
      ParticleManager:ReleaseParticleIndex(particle)
    end)
    vampire:EmitSound("Hero_Nightstalker.Void")
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

  if params.attacker == self:GetParent() and not params.unit:IsMechanical() then
    local unitname = "vampire"
    local position = params.unit:GetAbsOrigin()
    local team = self:GetParent():GetTeam()
    local playerID = self:GetParent().playerID

    local vampire = CreateLaneUnit(unitname, position, team, playerID)

    ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_loadout_bats.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, vampire)
    Timers:CreateTimer(0.5, function()
      ParticleManager:DestroyParticle(particle, false)
      ParticleManager:ReleaseParticleIndex(particle)
    end)
    vampire:EmitSound("Hero_Nightstalker.Void")
  end
end