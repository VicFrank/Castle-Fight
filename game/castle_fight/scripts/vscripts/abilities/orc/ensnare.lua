troll_ensnare = class({})

LinkLuaModifier("modifier_troll_ensnare", "abilities/orc/ensnare.lua", LUA_MODIFIER_MOTION_NONE)

function troll_ensnare:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("Hero_NagaSiren.Ensnare.Cast")

  local particleName = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf"

  local projectile = {
    Target = target,
    Source = caster,
    Ability = ability,
    EffectName = particleName,
    iMoveSpeed = 900,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
  }

  ProjectileManager:CreateTrackingProjectile(projectile)
end

function troll_ensnare:OnProjectileHit(target, locationn)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  if target then
    target:EmitSound("Hero_NagaSiren.Ensnare.Target")
    target:AddNewModifier(caster, self, "modifier_troll_ensnare", {duration = duration})
  end
end

modifier_troll_ensnare = class({})

function modifier_troll_ensnare:IsDebuff()
  return true
end

function modifier_troll_ensnare:CheckState()
  return { 
    [MODIFIER_STATE_ROOTED] = true,
  }
end

function modifier_troll_ensnare:OnCreated()
  if not IsServer() then return end
  self.parent = self:GetParent()

  self.parent:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

function modifier_troll_ensnare:OnDestroy()
  if not IsServer() then return end
  self.parent:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end

function modifier_troll_ensnare:GetEffectName()
  return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_troll_ensnare:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_troll_ensnare:DeclareFunctions()
  return { MODIFIER_PROPERTY_VISUAL_Z_DELTA }
end

function modifier_troll_ensnare:GetVisualZDelta()
  return 0
end