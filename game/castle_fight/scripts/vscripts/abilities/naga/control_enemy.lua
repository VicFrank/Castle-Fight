control_enemy = class({})

function control_enemy:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local particleName = "particles/units/heroes/hero_chen/chen_holy_persuasion_a.vpcf"

  local enemies = FindAllVisibleEnemies(caster:GetTeam())
  local target = FindFirstUnit(enemies, function(target) 
    return not target:IsLegendary()
  end)

  if not target then return end

  caster:EmitSound("Hero_Chen.HolyPersuasionCast")

  -- swap target for new unit under our control
  local hero = caster:GetOwner()
  local playerID = hero:GetPlayerOwnerID()

  local position = target:GetAbsOrigin()
  local relative_health = target:GetHealthPercent() * 0.01
  local fv = target:GetForwardVector()
  local unitName = target:GetUnitName()
  local playerID = hero:GetPlayerOwnerID()
  local team = hero:GetTeam()
  local new_unit = CreateLaneUnit(unitName, position, team, playerID)
  new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
  new_unit:SetMana(target:GetMana())
  new_unit:SetForwardVector(fv)
  FindClearSpaceForUnit(new_unit, position, true)

  target:RemoveSelf()

  new_unit:EmitSound("Hero_Chen.HolyPersuasionEnemy")

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, new_unit)
  ParticleManager:SetParticleControl(particle, 1, new_unit:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)
end