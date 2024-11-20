ancient_guardian_banish = class({})

LinkLuaModifier("modifier_ancient_guardian_banish", "abilities/nature/banish", LUA_MODIFIER_MOTION_NONE)

function ancient_guardian_banish:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:IsLegendary() and not target:HasModifier("modifier_ancient_guardian_banish") end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  local duration = self:GetSpecialValueFor("duration")

  target:EmitSound("Hero_Pugna.Decrepify")

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  target:AddNewModifier(caster, ability, "modifier_ancient_guardian_banish", {duration = duration})
end

modifier_ancient_guardian_banish = class({})

function modifier_ancient_guardian_banish:CheckState()
    local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
  return state
end

function modifier_ancient_guardian_banish:DeclareFunctions()
  funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
      }
  return funcs
end

function modifier_ancient_guardian_banish:GetModifierMoveSpeedBonus_Percentage()
  return -50
end

function modifier_ancient_guardian_banish:GetModifierIncomingDamage_Percentage()
  return 50
end

function modifier_ancient_guardian_banish:GetEffectName()
  return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_ancient_guardian_banish:GetStatusEffectName()
  return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_ancient_guardian_banish:StatusEffectPriority()
  return 15
end