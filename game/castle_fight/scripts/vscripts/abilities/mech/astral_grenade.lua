LinkLuaModifier("modifier_astral_grenade", "abilities/mech/astral_grenade.lua", LUA_MODIFIER_MOTION_NONE)

flamegunner_astral_grenade = class({})

function flamegunner_astral_grenade:OnSpellStart()
  local ability = self
  local caster = self:GetCaster()
  local position = self:GetCursorPosition()

  local damage = self:GetSpecialValueFor("damage")
  local mana_burn = self:GetSpecialValueFor("mana_burn")
  local radius = self:GetSpecialValueFor("radius")
  local slow_duration = self:GetSpecialValueFor("slow_duration")

  local particle = ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, position)
  ParticleManager:ReleaseParticleIndex(particle)

  local enemies = FindEnemiesInRadius(caster, radius, position)

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) then
      enemy:AddNewModifier(caster, ability, "modifier_astral_grenade", {duration = slow_duration})

      ApplyDamage({
        victim = enemy,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })

      local particleName = "particles/generic_gameplay/generic_manaburn.vpcf"
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, enemy)
      ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(particle)

      local manaToBurn = math.min(mana_burn, enemy:GetMana())

      enemy:ReduceMana(manaToBurn)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, enemy, manaToBurn, nil)

      ApplyDamage({
        victim = enemy,
        damage = manaToBurn,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })
    end
  end
end

modifier_astral_grenade = class({})

function modifier_astral_grenade:OnCreated()
  if not self:GetAbility() then return end
  self.move_slow = self:GetAbility():GetSpecialValueFor("move_slow")
end
function modifier_astral_grenade:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
end
function modifier_astral_grenade:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end