LinkLuaModifier("modifier_earthquake_slow", "abilities/naga/earthquake.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_earthquake_fx", "abilities/naga/earthquake.lua", LUA_MODIFIER_MOTION_NONE)

earthquake = class({})

function earthquake:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local sound = "Hero_Kunkka.Tidebringer.Attack"
  local particleName = "particles/units/heroes/hero_slardar/slardar_crush.vpcf"

  local damage = ability:GetSpecialValueFor("damage")
  local slow_duration = ability:GetSpecialValueFor("slow_duration")
  local radius = ability:GetSpecialValueFor("radius")

  -- Choose a random enemy unit
  local filter = function(target) return not target:HasFlyMovementCapability() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)
  if not target then return end

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  target:EmitSound(sound)

  local earthquakeTargets = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

  for _,earthquakeTarget in pairs(earthquakeTargets) do
    if not earthquakeTarget:HasFlyMovementCapability() then
      ApplyDamage({
        victim = earthquakeTarget,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })

      earthquakeTarget:AddNewModifier(caster, ability, "modifier_earthquake_slow", {duration = slow_duration})
    end
  end
end

----------------------------------------------------------------------------------------------------

modifier_earthquake_slow = class({})

function modifier_earthquake_slow:IsDebuff() return true end

function modifier_earthquake_slow:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.slow_pct = self.ability:GetSpecialValueFor("slow_pct")

  -- Status effect and visaul effect doesn't combine for some reason
  -- Moving effects to separate modifiers helps
  -- But it requires some additional control, to make them behave as a signle modifier
  -- Thus, one modifier becomes parent to another and makes it replicate all changes
  if IsServer() then
    self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_earthquake_fx", {duration = self:GetDuration()})
  end
end

function modifier_earthquake_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
  return funcs
end

function modifier_earthquake_slow:GetModifierMoveSpeedBonus_Percentage()
  return -self.slow_pct
end
function modifier_earthquake_slow:GetModifierAttackSpeedBonus_Constant()
  return -self.slow_pct
end

function modifier_earthquake_slow:GetStatusEffectName()
  return "particles/status_fx/status_effect_naga_riptide.vpcf"
end

function modifier_earthquake_slow:OnDestroy()
  if IsServer() then
    self.parent:RemoveModifierByName("modifier_earthquake_fx")
  end
end

----------------------------------------------------------------------------------------------------

modifier_earthquake_fx = class({})

function modifier_earthquake_fx:DeclareFunctions()
  return {}
end

function modifier_earthquake_fx:IsHidden()
  return true
end

function modifier_earthquake_fx:IsDebuff()
  return false
end

function modifier_earthquake_fx:IsPurgable()
  return false
end

function modifier_earthquake_fx:GetEffectName()
  return "particles/units/heroes/hero_siren/naga_siren_riptide_debuff.vpcf"
end