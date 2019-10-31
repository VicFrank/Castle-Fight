succubus_curse = class({})

LinkLuaModifier("modifier_succubus_curse", "abilities/chaos/succubus_curse.lua", LUA_MODIFIER_MOTION_NONE)

function succubus_curse:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("Hero_QueenOfPain.ShadowStrike")

  local caster_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_queenofpain/queen_shadow_strike_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(caster_pfx, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(caster_pfx, 1, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(caster_pfx, 3, Vector(900, 0, 0))
  ParticleManager:ReleaseParticleIndex(caster_pfx)

  local projectile =
  {
    Target        = target,
    Source        = caster,
    Ability       = self,
    EffectName      = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
    iMoveSpeed      = 900,
    vSourceLoc      = caster:GetAbsOrigin(),
    bDrawsOnMinimap   = false,
    bDodgeable      = true,
    bIsAttack       = false,
    bVisibleToEnemies   = true,
    bReplaceExisting  = false,
    flExpireTime    = GameRules:GetGameTime() + 20,
    bProvidesVision   = false,
  }

  ProjectileManager:CreateTrackingProjectile(projectile)
end

function succubus_curse:OnProjectileHit(target, location)
  local duration = self:GetSpecialValueFor("duration")
  target:AddNewModifier(self:GetCaster(), self, "modifier_succubus_curse", {duration = duration})
end

modifier_succubus_curse = class({})

function modifier_succubus_curse:OnCreated()
  self.miss_rate = self:GetAbility():GetSpecialValueFor("miss_rate")
end

function modifier_succubus_curse:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
  return funcs
end

function modifier_succubus_curse:GetModifierMiss_Percentage()
  return self.miss_rate
end

function modifier_succubus_curse:OnAttackFail(keys)
  local fail_type = keys.fail_type
  local target = keys.target
  local attacker = keys.attacker

  if attacker == self:GetParent() then
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MISS, attacker, 0, nil)
  end
end