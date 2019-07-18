LinkLuaModifier("modifier_nether_drake_splash", "abilities/corrupted/nether_drake_splash_attack", LUA_MODIFIER_MOTION_NONE)

nether_drake_splash_attack = class({})

function nether_drake_splash_attack:GetIntrinsicModifierName()    
  return "modifier_nether_drake_splash"
end

-- function nether_drake_splash_attack:GetCastRange(location, target)
--    local caster = self:GetCaster()
--    return caster:Script_GetAttackRange()
-- end 

-- function nether_drake_splash_attack:OnSpellStart()
--   -- Ability properties
--   local caster = self:GetCaster()
--   local ability = self
--   local target = self:GetCursorTarget()
--   local particle_projectile = "particles/units/heroes/hero_viper/viper_base_attack.vpcf"
--   local sound_cast = "hero_viper.poisonAttack.Cast"

--   -- Ability specials
--   local projectile_speed = 900
--   local vision_radius = 100

--   -- Play attack sound
--   EmitSoundOn(sound_cast, caster)    

--   -- Launch projectile on target
--   local projectile = {
--     Target = target,
--     Source = caster,
--     Ability = ability,
--     EffectName = particle_projectile,
--     iMoveSpeed = projectile_speed,
--     bDodgeable = true, 
--     bVisibleToEnemies = true,
--     bReplaceExisting = false,
--     bProvidesVision = true,        
--     iVisionRadius = vision_radius,
--     iVisionTeamNumber = caster:GetTeamNumber()      
--   }

--   ProjectileManager:CreateTrackingProjectile(projectile)
-- end

-- function nether_drake_splash_attack:OnProjectileHit(target, location)
--   if IsServer() then
--     -- Ability properties
--     local caster = self:GetCaster()
--     local ability = self
--     local sound_hit = "hero_viper.poisonAttack.Impact"

--     -- Play hit sound
--     EmitSoundOn(sound_hit, target)

--     caster:PerformAttack(target, false, true, true, false, false, false, true)
--     SplashAttackUnit(caster, target:GetAbsOrigin())
--   end
-- end

modifier_nether_drake_splash = class({})

function modifier_nether_drake_splash:IsHidden() return true end
function modifier_nether_drake_splash:IsPurgable() return false end
function modifier_nether_drake_splash:IsDebuff() return false end

function modifier_nether_drake_splash:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_nether_drake_splash:GetModifierBaseAttack_BonusDamage()
  -- If the ability is null, do nothing
  if self:GetAbility():IsNull() then
    return nil
  end

  if self:GetParent():GetMana() < self:GetAbility():GetManaCost(1) then
    return nil
  end

  if not self:GetCaster():PassivesDisabled() then
    return self.bonus_damage
  end

  return nil
end

function modifier_nether_drake_splash:OnCreated()
  -- Ability properties
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()
  self.sound_cast = "hero_viper.poisonAttack.Cast"
  self.splash_attack_particle = "particles/units/heroes/hero_viper/viper_base_attack.vpcf"
  self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")

  if not IsServer() then return end

  self.normal_attack_particle = self.parent:GetRangedProjectileName()
  self.ability:ToggleAutoCast()
end

function modifier_nether_drake_splash:OnAttackStart(keys)
  if IsServer() then
    local attacker = keys.attacker
    local target = keys.target

    -- Only apply on caster's attacks
    if self.caster == attacker then
      -- Get variables
      self.auto_cast = self.ability:GetAutoCastState()
      self.current_mana = self.caster:GetMana()
      self.mana_cost = self.ability:GetManaCost(-1)

      local splash_attack = true

      -- If the caster is silenced, mark attack as non-frost arrow
      if self.caster:IsSilenced() then
        splash_attack = false
      end

      -- If the target is a building or is magic immune, mark attack as non-frost arrow
      if IsCustomBuilding(target) or target:IsMagicImmune() then
        splash_attack = false
      end

      -- If there isn't enough mana to cast a Frost Arrow, assign as a non-frost arrow
      if self.current_mana < self.mana_cost then
        splash_attack = false
      end

      print(splash_attack)

      if splash_attack then
        self.splash_attack = true
        print("Setting projectile for splash attack")
        self.caster:SetRangedProjectileName(self.splash_attack_particle)
      else
        -- Transform back to usual projectiles
        self.splash_attack = false
        self.caster:SetRangedProjectileName(self.normal_attack_particle)
      end
    end
  end
end

function modifier_nether_drake_splash:OnAttack(keys)
  if IsServer() then
    local attacker = keys.attacker
    local target = keys.target

    -- Only apply on caster's attacks
    if self.caster == keys.attacker then

      -- If it wasn't a frost arrow, do nothing
      if not self.splash_attack then
        return nil
      end

      -- Emit sound
      EmitSoundOn(self.sound_cast, self.caster)

      -- Spend mana
      self.caster:SpendMana(self.mana_cost, self.ability)
    end
  end
end

function modifier_nether_drake_splash:OnAttackLanded(keys)
  if IsServer() then
    local attacker = keys.attacker
    local target = keys.target

    if self.caster == attacker then
      SplashAttackUnit(attacker, target:GetAbsOrigin())
    end
  end
end