hells_fist = class({})

function hells_fist:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local team = caster:GetTeamNumber()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  local enemies = FindUnitsInRadius(team, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

  local buildings = {}

  for _,enemy in pairs(enemies) do
    if IsCustomBuilding(enemy) and enemy:GetUnitName() ~= "castle" and not enemy:IsLegendary() then
      table.insert(buildings, enemy)
    end
  end

  if #buildings == 0 then return end
  local target = GetRandomTableElement(buildings)

  caster:EmitSound("Hero_Lion.FingerOfDeath")
  target:EmitSound("Hero_Lion.FingerOfDeathImpact")

  caster:AddNewModifier(caster, ability, "modifier_provide_vision", {duration = 0.1})

  local particle_finger = "particles/econ/items/lion/lion_ti8/lion_spell_finger_ti8_straighten_lvl2.vpcf"
  local particle_finger_fx = ParticleManager:CreateParticle(particle_finger, PATTACH_OVERHEAD_FOLLOW, caster)

  -- ParticleManager:SetParticleControlEnt(particle_finger_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(particle_finger_fx, 0, caster:GetAbsOrigin() + Vector(0,0,1000))
  ParticleManager:SetParticleControl(particle_finger_fx, 1, target:GetAbsOrigin() + Vector(0,0,150))
  ParticleManager:SetParticleControl(particle_finger_fx, 2, target:GetAbsOrigin() + Vector(0,0,150))
  ParticleManager:ReleaseParticleIndex(particle_finger_fx)  

  local explosion_range = 100

  local particleName = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, target)
  ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 2, Vector(explosion_range, 1, 1))
  ParticleManager:ReleaseParticleIndex(particle)

  target:AddEffects(EF_NODRAW)
  ForceKill(target)
end