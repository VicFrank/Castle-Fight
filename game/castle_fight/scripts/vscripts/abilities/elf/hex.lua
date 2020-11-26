city_of_magic_hex = class({})

LinkLuaModifier("modifier_city_of_magic_hex", "abilities/elf/hex", LUA_MODIFIER_MOTION_NONE)

function city_of_magic_hex:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:IsLegendary() and not target:HasModifier("modifier_city_of_magic_hex") end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  caster:EmitSound("Hero_ShadowShaman.Hex.Target")

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  local duration = ability:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_city_of_magic_hex", {duration = duration})
end

modifier_city_of_magic_hex = class({})

function modifier_city_of_magic_hex:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE
  }
end

function modifier_city_of_magic_hex:GetModifierModelChange()
  return "models/props_gameplay/chicken.vmdl"
end

function modifier_city_of_magic_hex:GetModifierModelScale()
  return -50
end

function modifier_city_of_magic_hex:GetModifierMoveSpeedOverride()
  return 100
end

function modifier_city_of_magic_hex:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_HEXED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end