spider_web = class({})

LinkLuaModifier("modifier_spider_web", "abilities/nature/web.lua", LUA_MODIFIER_MOTION_NONE)

function spider_web:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("Hero_Broodmother.SpawnSpiderlingsCast")

  local particleName = "particles/units/heroes/hero_broodmother/broodmother_web_cast.vpcf"

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

function spider_web:OnProjectileHit(target, locationn)
  local caster = self:GetCaster()
  local duration = ability:GetSpecialValueFor("duration")

  if target then
    target:EmitSound("Hero_Broodmother.SpawnSpiderlingsCast")
    target:AddNewModifier(caster, ability, "modifier_spider_web", {duration = duration})
  end
end

modifier_spider_web = class({})

function modifier_spider_web:IsDebuff()
  return true
end

function modifier_spider_web:CheckState()
  return { 
    [MODIFIER_STATE_ROOTED] = true,
  }
end

function modifier_spider_web:OnCreated()
  self.parent = self:GetParent()

  self.parent:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

function modifier_spider_web:OnDestroy()
  self.parent:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end

function modifier_spider_web:GetEffectName()
  return "particles/econ/courier/courier_trail_hw_2012/courier_trail_hw_2012_webs.vpcf"
end

function modifier_spider_web:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spider_web:DeclareFunctions()
  return { MODIFIER_PROPERTY_VISUAL_Z_DELTA }
end

function modifier_spider_web:GetVisualZDelta()
  return 0
end