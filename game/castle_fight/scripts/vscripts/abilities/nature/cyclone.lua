ancient_of_wind_cyclone = class({})

LinkLuaModifier("modifier_ancient_of_wind_cyclone_aura", "abilities/nature/cyclone.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_of_wind_cyclone_debuff", "abilities/nature/cyclone.lua", LUA_MODIFIER_MOTION_NONE)

function ancient_of_wind_cyclone:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local duration = ability:GetSpecialValueFor("duration")

  local dummy = CreateUnitByName("dummy_unit", target:GetAbsOrigin(), true, nil, nil, caster:GetTeam())
  dummy.playerID = caster:GetPlayerOwnerID()

  dummy:AddNewModifier(caster, ability, "modifier_ancient_of_wind_cyclone_aura", {})
  dummy:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

  local particle = ParticleManager:CreateParticle("particles/neutral_fx/tornado_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)

  dummy:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
  dummy:SetBaseMoveSpeed(100)

  -- Wander in random directions
  Timers:CreateTimer(function()
    if not dummy:IsAlive() then return end

    dummy:MoveToPosition(dummy:GetAbsOrigin() + RandomVector(500))

    return 1
  end)
end

modifier_ancient_of_wind_cyclone_aura = class({})

function modifier_ancient_of_wind_cyclone_aura:IsAura() return true end
function modifier_ancient_of_wind_cyclone_aura:GetAuraDuration() return 0.5 end
function modifier_ancient_of_wind_cyclone_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_ancient_of_wind_cyclone_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ancient_of_wind_cyclone_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_ancient_of_wind_cyclone_aura:GetModifierAura() return "modifier_ancient_of_wind_cyclone_debuff" end
function modifier_ancient_of_wind_cyclone_aura:IsAuraActiveOnDeath() return false end
function modifier_ancient_of_wind_cyclone_aura:GetAuraEntityReject(target) return target:IsRealHero() end

modifier_ancient_of_wind_cyclone_debuff = class({})

function modifier_ancient_of_wind_cyclone_debuff:IsDebuff() return true end
function modifier_ancient_of_wind_cyclone_debuff:IsHidden() return false end

function modifier_ancient_of_wind_cyclone_debuff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ancient_of_wind_cyclone_debuff:OnCreated()
  if not self:GetAbility() then return end
  self.dps = self:GetAbility():GetSpecialValueFor("dps")

  self.tick_rate = 0.2

  self:StartIntervalThink(self.tick_rate)
end

function modifier_ancient_of_wind_cyclone_debuff:OnIntervalThink()
  if not IsServer() then return end

  if IsCustomBuilding(self:GetParent()) then return end

  local damage = self.tick_rate * self.dps

  ApplyDamage({
    victim = self:GetParent(),
    attacker = self:GetCaster(),
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = self:GetAbility()
  })
end

function modifier_ancient_of_wind_cyclone_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
  return funcs
end

function modifier_ancient_of_wind_cyclone_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_ancient_of_wind_cyclone_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self:GetAbility():GetSpecialValueFor("attack_slow")
end