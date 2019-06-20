avenging_spirit_revenge = class({})

LinkLuaModifier("modifier_revenge", "abilities/night_elves/revenge.lua", LUA_MODIFIER_MOTION_NONE)

function avenging_spirit_revenge:GetIntrinsicModifierName()
  return "modifier_revenge"
end

modifier_revenge = class({})

function modifier_revenge:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_revenge:OnDeath(params)
  if not IsServer() then return end

  if params.unit == self:GetParent() then
    local attacker = params.attacker
    if attacker then
      local damage = self:GetAbility():GetSpecialValueFor("damage")

      ApplyDamage({
        victim = attacker,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = self:GetParent(),
        ability = self:GetAbility()
      })
    end
  end
end