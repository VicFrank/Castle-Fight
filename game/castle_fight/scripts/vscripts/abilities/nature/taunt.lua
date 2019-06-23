mountain_giant_taunt = class({})

LinkLuaModifier("modifier_mountain_giant_taunt", "abilities/nature/taunt.lua", LUA_MODIFIER_MOTION_NONE)

function mountain_giant_taunt:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local radius = ability:GetSpecialValueFor("radius")
  local duration = ability:GetSpecialValueFor("duration")

  local enemies = FindEnemiesInRadius(caster, radius)

  caster:StartGesture(ACT_TINY_GROWL)

  local particle = ParticleManager:CreateParticle("particles/econ/items/axe/axe_helm_shoutmask/axe_beserkers_call_owner_shoutmask.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 2, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:IsRealHero() then
      enemy:AddNewModifier(caster, ability, "modifier_mountain_giant_taunt", {duration = duration})
    end
  end
end

mountain_giant_taunt = class({})

function mountain_giant_taunt:IsDebuff() return true end

function mountain_giant_taunt:OnCreated()
  self:GetParent().tauntTarget = self:GetCaster()
end