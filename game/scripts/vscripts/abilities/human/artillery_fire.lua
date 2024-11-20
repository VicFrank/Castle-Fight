artillery_fire = class({})
LinkLuaModifier("modifier_artillery_fire", "abilities/human/artillery_fire.lua", LUA_MODIFIER_MOTION_NONE)

function artillery_fire:GetIntrinsicModifierName()
  return "modifier_artillery_fire"  
end

modifier_artillery_fire = class({})

function modifier_artillery_fire:IsHidden() return true end

function modifier_artillery_fire:OnCreated()
  if not IsServer() then return end

  self.ability = self:GetAbility()
  self.caster = self.ability:GetCaster()

  local team = self.caster:GetTeam()

  -- If this is just a buildinghelper ghost
  if team == DOTA_TEAM_NEUTRALS then return end

  self.fire_delay = self.ability:GetCooldown(1)

  if team == DOTA_TEAM_GOODGUYS then
    self.minBounds = GameRules.rightBaseMinBounds
    self.maxBounds = GameRules.rightBaseMaxBounds
  else
    self.minBounds = GameRules.leftBaseMinBounds
    self.maxBounds = GameRules.leftBaseMaxBounds
  end

  if IsServer() then
    -- Wait to finish building
    Timers:CreateTimer(1, function()
      if not self.caster:IsAlive() then return end
      if self.caster:IsSilenced() or self.caster:PassivesDisabled() then return .1 end

      FireCannon(self.ability, self)
      self:StartIntervalThink(self.fire_delay)
    end)
  end
end

function modifier_artillery_fire:OnIntervalThink()
  if not IsServer() then return end
  if not IsValidAlive(self.caster) then return end
    
  FireCannon(self.ability, self)
end

function FireCannon(ability, modifier)
  ability:StartCooldown(modifier.fire_delay)

  local caster = modifier.caster
  local casterTeam = caster:GetTeam()
  local target = RandomPositionBetweenBounds(modifier.minBounds, modifier.maxBounds)
  local sound_attack = "Hero_Techies.Attack"
  local sound_impact = "Hero_Techies.ProjectileImpact"
  local speed = 900
  local particle = "particles/units/heroes/hero_techies/techies_base_attack.vpcf"
  local attackPoint = .3

  caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 3)

  Timers:CreateTimer(attackPoint, function()
    local projectile = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(projectile, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")))
    ParticleManager:SetParticleControl(projectile, 1, target)
    ParticleManager:SetParticleControl(projectile, 2, Vector(speed, 0, 0))
    ParticleManager:SetParticleControl(projectile, 3, target)

    EmitSoundOn(sound_attack, caster)

    local distanceToTarget = (caster:GetAbsOrigin() - target):Length2D()
    local time = distanceToTarget / speed

    Timers:CreateTimer(time, function()
      ParticleManager:DestroyParticle(projectile, false)

      EmitSoundOn(sound_impact, caster)

      -- AddFOWViewer(casterTeam, target, 160, 3, false)

      if not caster:IsNull() then
        SplashAttackGround(caster, target)
      end
    end)
  end)
end