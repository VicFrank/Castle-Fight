onset_of_winter = class({})

LinkLuaModifier("modifier_north_chilling_attack_debuff", "abilities/north/chilling_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_attack_freeze", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_onset_of_winter_fx", "abilities/north/onset_of_winter.lua", LUA_MODIFIER_MOTION_NONE)

-- Sends out three frost orbs that fly in a random direction, attacking random
-- enemies for 60dps spell damage, stunning random air units, freezing random
-- ground units and chilling each unit near them.
function onset_of_winter:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  caster:EmitSound("Hero_Lich.ChainFrost")

  local speed = ability:GetSpecialValueFor("speed")
  local dps = ability:GetSpecialValueFor("dps")
  local radius = ability:GetSpecialValueFor("radius")

  local goal

  if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
    goal = GameRules.rightCastlePosition
  elseif caster:GetTeam() == DOTA_TEAM_BADGUYS then
    goal = GameRules.leftCastlePosition - Vector(300,128,0)
  end


  for i=1,3 do
    local direction = (goal - caster:GetAbsOrigin()):Normalized()
    direction = (direction + RandomVector(0.4)):Normalized()
    direction = Vector(direction.x, direction.y, 0)

    local projectile = {
      Ability       = self,
      EffectName      = "particles/custom/north/lich/lich_chain_frost_2.vpcf",
      vSpawnOrigin    = caster:GetAbsOrigin(),
      fDistance     = 15000,
      fStartRadius    = 150,
      fEndRadius      = 150,
      Source        = caster,
      bHasFrontalCone   = true,
      bReplaceExisting  = false,
      iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
      iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_NONE,
      iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      fExpireTime     = GameRules:GetGameTime() + 27.0,
      bDeleteOnHit    = false,
      vVelocity     = direction * speed,
      ExtraData     = {
        dps = dps,
        radius = radius,
      }
    }
    ProjectileManager:CreateLinearProjectile(projectile)
  end
end

function onset_of_winter:OnProjectileThink_ExtraData(location, ExtraData)
  if not IsServer() then return end
  local caster = self:GetCaster()
  local ability = self

  if caster:IsNull() or not caster then return end

  local dps = ExtraData.dps

  local enemies = FindEnemiesInRadius(caster, ExtraData.radius, location)

  for _,enemy in pairs(enemies) do
    enemy:AddNewModifier(caster, ability, "modifier_north_chilling_attack_debuff", {duration = 1})
    enemy:AddNewModifier(caster, ability, "modifier_onset_of_winter_fx", {duration = 1})
  end

  if #enemies == 0 then return end

  -- Damage a random enemy
  local target = GetRandomTableElement(enemies)
  local damage = dps * FrameTime()

  ApplyDamage({
    victim = target,
    attacker = caster,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability,
  })
end

function onset_of_winter:OnProjectileHit(target, location)
  if not IsServer() then return end
  local caster = self:GetCaster()
  local ability = self

  if caster:IsNull() or not caster then return end

  if not target then return end

  if target:HasFlyMovementCapability() then
    target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 3})
  else
    target:AddNewModifier(caster, ability, "modifier_frost_attack_freeze", {duration = 3})
  end
end

----------------------------------------------------------------------------------------------------

modifier_onset_of_winter_fx = class ({})

function modifier_onset_of_winter_fx:DeclareFunctions()
  return {}
end

function modifier_onset_of_winter_fx:GetEffectName()
  return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet.vpcf"
end

function modifier_onset_of_winter_fx:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_onset_of_winter_fx:IsHidden()
  return true
end

function modifier_onset_of_winter_fx:IsDebuff()
  return false
end

function modifier_onset_of_winter_fx:IsPurgable()
  return false
end