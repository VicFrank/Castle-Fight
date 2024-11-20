LinkLuaModifier("modifier_critical_strike_custom", "abilities/generic/critical_strike.lua", LUA_MODIFIER_MOTION_NONE)

heavy_gunner_critical_strike = class({})
function heavy_gunner_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
marksman_critical_strike = class({})
function marksman_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
murloc_critical_strike = class({})
function murloc_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
royal_guard_critical_strike = class({})
function royal_guard_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
lobster_critical_strike = class({})
function lobster_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
bear_critical_strike = class({})
function bear_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
grunt_critical_strike = class({})
function grunt_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
tribal_blessing_critical_strike = class({})
function tribal_blessing_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
wolf_critical_strike = class({})
function wolf_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
blademaster_critical_strike = class({})
function blademaster_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
chaos_warrior_critical_strike = class({})
function chaos_warrior_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
tentacle_critical_strike = class({})
function tentacle_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
corrupted_treant_critical_strike = class({})
function corrupted_treant_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end
skeleton_critical_strike = class({})
function skeleton_critical_strike:GetIntrinsicModifierName() return "modifier_critical_strike_custom" end

modifier_critical_strike_custom = class({})

function modifier_critical_strike_custom:IsHidden() return true end

function modifier_critical_strike_custom:OnCreated()
  if not IsServer() then return end

  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()
  
  self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
  self.crit_damage = self.ability:GetSpecialValueFor("crit_damage")
end

function modifier_critical_strike_custom:OnRefresh()
  if not IsServer() then return end
  
  self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
  self.crit_damage = self.ability:GetSpecialValueFor("crit_damage")
end

function modifier_critical_strike_custom:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
  }
  return funcs
end

function modifier_critical_strike_custom:GetModifierPreAttack_CriticalStrike(params)
  if not IsServer() then return end

  local target = params.target

  if IsCustomBuilding(target) then return end

  if self.crit_chance >= RandomInt(1,100) then
    -- self:GetParent():EmitSound("Hero_PhantomAssassin.CoupDeGrace")

    -- local particleName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
    -- local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, self:GetParent())
    -- ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    -- ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    -- ParticleManager:ReleaseParticleIndex(particle)

    return self.crit_damage
  else
    return nil
  end
end