LinkLuaModifier("modifier_earthquake_slow", "abilities/naga/earthquake.lua", LUA_MODIFIER_MOTION_NONE)

earthquake = class({})

function earthquake:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local sound = "Hero_EarthShaker.IdleSlam"
  local particleName = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock.vpcf"

  local damage = ability:GetSpecialValueFor("damage")
  local slow_duration = ability:GetSpecialValueFor("slow_duration")
  local radius = ability:GetSpecialValueFor("radius")

  -- Choose a random enemy unit
  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  target:EmitSound(sound)

  local earthquakeTargets = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

  for _,earthquakeTarget in pairs(earthquakeTargets) do
    local damageTable = {
        victim = earthquakeTarget,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      }

      ApplyDamage(damageTable)

    earthquakeTarget:AddNewModifier(caster, ability, "modifier_earthquake_slow", {duration = slow_duration})
  end
end

modifier_earthquake_slow = class({})

function modifier_earthquake_slow:IsDebuff() return true end

function modifier_earthquake_slow:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.slow_pct = self.ability:GetSpecialValueFor("slow_pct")
end

function modifier_earthquake_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
  return funcs
end

function modifier_earthquake_slow:GetModifierMoveSpeedBonus_Percentage()
  return -self.slow_pct
end