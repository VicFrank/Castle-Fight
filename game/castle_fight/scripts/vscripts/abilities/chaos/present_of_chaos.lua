present_of_chaos = class({})

LinkLuaModifier("modifier_present_of_chaos", "abilities/chaos/present_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)

function present_of_chaos:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:IsLegendary() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  -- One of the following happens
  -- The unit explodes (no bounty)
  -- The unit dies (you gain bounty)
  -- The unit transforms into a mutation that fights for you
  -- The unit is hexed
  -- The unit receives 500 damage
  -- The unit gets 400 bonus health and +25 damage and is fully healed
  -- The unit is stunned for 6 seconds and recieves 200 spell damage
  -- Nothing happens

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  local options = {
    "EXPLODE",
    "DEATH",
    "MUTATE",
    "HEX",
    "DAMAGE",
    "BUFF",
    "STUN",
    "NOTHING",
  }

  local option = GetRandomTableElement(options)

  local particle = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  if option == "EXPLODE" then
    ParticleManager:ReleaseParticleIndex(
    ParticleManager:CreateParticle(
        "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target 
      )
    )
    target:ForceKill(false)
  elseif option == "DEATH" then
    PlayPACrit(caster, target)
    target:Kill(ability, caster)
  elseif option == "MUTATE" then
    CreateLaneUnit("mutation", target:GetAbsOrigin(), caster:GetTeam(), caster:GetPlayerOwnerID())
    target:CustomRemoveSelf()
  elseif option == "HEX" then
    target:AddNewModifier(caster, ability, "modifier_hexxed", {duration = 45})
  elseif option == "DAMAGE" then
    ApplyDamage({
      victim = target,
      damage = 500,
      damage_type = DAMAGE_TYPE_PURE,
      attacker = caster,
      ability = ability
    })
  elseif option == "BUFF" then
    target:Heal(target:GetMaxHealth(), ability)
    target:AddNewModifier(caster, ability, "modifier_present_of_chaos", {})
  elseif option == "STUN" then
    target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 6})
    ApplyDamage({
      victim = target,
      damage = 200,
      damage_type = DAMAGE_TYPE_MAGICAL,
      attacker = caster,
      ability = ability
    })
  elseif option == "NOTHING" then
    -- nothing happens
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

modifier_present_of_chaos = class({})

function modifier_present_of_chaos:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_bonus = 25
  self.health_bonus = 400
end

function modifier_present_of_chaos:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
  return funcs
end

function modifier_present_of_chaos:GetModifierExtraHealthBonus()
  return self.health_bonus
end

function modifier_present_of_chaos:GetModifierPreAttack_BonusDamage()
  return self.damage_bonus
end