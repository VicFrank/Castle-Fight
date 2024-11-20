catapult_burning_ammo = class({})

LinkLuaModifier("modifier_catapult_burning_ammo", "abilities/orc/burning_ammo.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_catapult_burning_ammo_thinker", "abilities/orc/burning_ammo.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_catapult_burning_ammo_debuff", "abilities/orc/burning_ammo.lua", LUA_MODIFIER_MOTION_NONE)

function catapult_burning_ammo:GetIntrinsicModifierName()
  return "modifier_catapult_burning_ammo"
end

modifier_catapult_burning_ammo = class({})

function modifier_catapult_burning_ammo:IsPurgable()
  return false
end

function modifier_catapult_burning_ammo:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_catapult_burning_ammo:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_catapult_burning_ammo:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    CreateModifierThinker(self.caster, self.ability, "modifier_catapult_burning_ammo_thinker",
      {duration = duration}, target:GetAbsOrigin(), self.caster:GetTeam(), false)
  end
end

modifier_catapult_burning_ammo_thinker = class({})

function modifier_catapult_burning_ammo_thinker:OnCreated(keys)
  if IsServer() then
    self.caster = self:GetCaster()
    self.thinker = self:GetParent()
    self.ability = self:GetAbility()

    self.radius = self.ability:GetSpecialValueFor("radius")
    self.duration = self.ability:GetSpecialValueFor("duration")
    self.dps = self.ability:GetSpecialValueFor("dps")

    local nFXIndex = ParticleManager:CreateParticle( "particles/neutral_fx/black_dragon_fireball.vpcf", PATTACH_WORLDORIGIN, nil );
    ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() );
    ParticleManager:SetParticleControl( nFXIndex, 1, self:GetParent():GetOrigin() );
    ParticleManager:SetParticleControl( nFXIndex, 2, Vector( self.duration, 0, 0 ) );
    ParticleManager:ReleaseParticleIndex( nFXIndex );

    EmitSoundOn( "OgreMagi.Ignite.Target", self:GetParent() )

    self:SetDuration( self.duration, true )

    self.tick_rate = 0.2
    self:StartIntervalThink(self.tick_rate)
  end
end

function modifier_catapult_burning_ammo_thinker:OnIntervalThink()
  if IsServer() then
    local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), self:GetParent(), self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
    for _,enemy in pairs( enemies ) do
      if enemy ~= nil and not enemy:HasFlyMovementCapability() then
        enemy:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_catapult_burning_ammo_debuff", { duration = 1 } )
        
        local damage_table = {
          victim = enemy,
          attacker = self.caster,
          damage = self.dps * self.tick_rate,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self.ability,
        }
        ApplyDamage(damage_table)
      end
    end
  end
end

modifier_catapult_burning_ammo_debuff = class({})

function modifier_catapult_burning_ammo_debuff:IsDebuff() return true end
