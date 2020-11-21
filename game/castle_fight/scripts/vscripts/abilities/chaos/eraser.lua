erase = class({})

function erase:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local enemies = FindUnitsInRadius(
    caster:GetTeam(),
    Vector(0,0,0),
    nil, 
    FIND_UNITS_EVERYWHERE, 
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
    FIND_ANY_ORDER, false)

  local notBuildings = {}  
  for _,enemy in pairs(enemies) do
    -- exclude buildings and summons
    if not IsCustomBuilding(enemy) and not enemy:HasModifier("modifier_kill") then
      table.insert(notBuildings, enemy)
    end
  end

  if #notBuildings == 0 then return end

  local enemy = GetRandomTableElement(notBuildings)
  local enemyName = enemy:GetUnitName()

  for _,enemy in pairs(enemies) do
    local skipUnit = false
    for _,modifier in pairs(enemy:FindAllModifiers()) do
      if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
        skipUnit = true
      end
    end

    if enemy:GetUnitName() == enemyName and not skipUnit then
      PlayPACrit(caster, enemy)
      enemy:Kill(ability, caster)
    end
  end

end

function PlayPACrit( hAttacker, hVictim )
  local bloodEffect = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
  local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
  ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
  ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
  local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
  ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
  ParticleManager:SetParticleControlEnt( nFXIndex, 10, hVictim, PATTACH_ABSORIGIN_FOLLOW, "", hVictim:GetAbsOrigin(), true )
  ParticleManager:ReleaseParticleIndex( nFXIndex )
end