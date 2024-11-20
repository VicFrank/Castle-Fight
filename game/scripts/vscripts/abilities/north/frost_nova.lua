ice_queen_frost_nova = class({})

LinkLuaModifier("modifier_ice_queen_frost_nova", "abilities/north/frost_nova.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ice_queen_frost_nova_fx", "abilities/north/frost_nova.lua", LUA_MODIFIER_MOTION_NONE)

function ice_queen_frost_nova:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local damage = ability:GetSpecialValueFor("aoe_damage")
  local duration = ability:GetSpecialValueFor("duration")
  local radius = ability:GetSpecialValueFor("radius")

  caster:EmitSound("Ability.FrostNova")

  local particle_nova = "particles/units/heroes/hero_lich/lich_frost_nova.vpcf"

  local particle_nova_fx = ParticleManager:CreateParticle(particle_nova, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControl(particle_nova_fx, 0, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle_nova_fx, 1, Vector(radius, radius, radius))
  ParticleManager:SetParticleControl(particle_nova_fx, 2, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle_nova_fx)

  local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:IsRealHero() then
      ApplyDamage({
        victim = enemy,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })

      target:AddNewModifier(caster, ability, "modifier_ice_queen_frost_nova", {duration = duration})
    end
  end

  -- The target takes double damage
  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = ability
  })
end

----------------------------------------------------------------------------------------------------

modifier_ice_queen_frost_nova = class({})

function modifier_ice_queen_frost_nova:IsDebuff()
  return true
end

function modifier_ice_queen_frost_nova:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
  return decFuns
end

function modifier_ice_queen_frost_nova:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.move_slow = self.ability:GetSpecialValueFor("slow")
  self.attack_slow = self.ability:GetSpecialValueFor("slow")

  if IsServer() then
    self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ice_queen_frost_nova_fx", {duration = self:GetDuration()})
  end
end


function modifier_ice_queen_frost_nova:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end

function modifier_ice_queen_frost_nova:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow
end

function modifier_ice_queen_frost_nova:GetStatusEffectName()
  return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_ice_queen_frost_nova:StatusEffectPriority()
  return FX_PRIORITY_CHILLED
end

function modifier_ice_queen_frost_nova:OnDestroy()
  if IsServer() then
    self.parent:RemoveModifierByName("modifier_ice_queen_frost_nova_fx")
  end
end

----------------------------------------------------------------------------------------------------

modifier_ice_queen_frost_nova_fx = class ({})

function modifier_ice_queen_frost_nova_fx:DeclareFunctions()
  return {}
end

function modifier_ice_queen_frost_nova_fx:GetEffectName()
  return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_ice_queen_frost_nova_fx:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ice_queen_frost_nova_fx:IsHidden()
  return true
end

function modifier_ice_queen_frost_nova_fx:IsDebuff()
  return false
end

function modifier_ice_queen_frost_nova_fx:IsPurgable()
  return false
end