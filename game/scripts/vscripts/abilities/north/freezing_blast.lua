freezing_blast = class({})

LinkLuaModifier("modifier_freezing_blast", "abilities/north/freezing_blast.lua", LUA_MODIFIER_MOTION_NONE)

function freezing_blast:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local particleName = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf"
  
  local filter = function(target) return target:HasFlyMovementCapability() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  caster:EmitSound("Hero_Winter_Wyvern.SplinterBlast.Cast")

  local projectile = {
    Target = target,
    Source = caster,
    Ability = ability,
    EffectName = particleName,
    iMoveSpeed = 1600,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
  }

  ProjectileManager:CreateTrackingProjectile(projectile)
end

function freezing_blast:OnProjectileHit(target, location)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  if target then
    target:EmitSound("Hero_Winter_Wyvern.SplinterBlast.Target")

    for _,modifier in pairs(target:FindAllModifiers()) do
      if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
        return
      end
    end
  
    target:AddNewModifier(caster, self, "modifier_freezing_blast", {duration = duration})

    local damage = self:GetSpecialValueFor("damage")

    ApplyDamage({
      victim = target,
      attacker = caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      ability = self,
    })
  end
end

modifier_freezing_blast = class({})

function modifier_freezing_blast:IsPurgeException() return true end
function modifier_freezing_blast:IsStunDebuff() return true end

function modifier_freezing_blast:CheckState()
  local state = {[MODIFIER_STATE_STUNNED] = true}

  return state
end

function modifier_freezing_blast:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_freezing_blast:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_freezing_blast:DeclareFunctions()
  local decFuncs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}

  return decFuncs
end

function modifier_freezing_blast:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end