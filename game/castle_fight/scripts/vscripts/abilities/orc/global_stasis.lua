global_stasis = class({})

LinkLuaModifier("modifier_global_stasis", "abilities/orc/global_stasis.lua", LUA_MODIFIER_MOTION_NONE)

function global_stasis:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local duration = ability:GetSpecialValueFor("duration")

  local team = caster:GetTeamNumber()
  local position = point or caster:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_NONE
  local enemies = FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)

  caster:EmitSound("Hero_Techies.StasisTrap.Stun")

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) then
      enemy:AddNewModifier(caster, ability, "modifier_global_stasis", {duration = duration})
    end
  end
end

modifier_global_stasis = modifier_global_stasis or class({})

function modifier_global_stasis:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true
  }
end

function modifier_global_stasis:IsPurgable() return true end
function modifier_global_stasis:IsDebuff() return true end

function modifier_global_stasis:GetStatusEffectName()
  return "particles/status_fx/status_effect_techies_stasis.vpcf"
end
