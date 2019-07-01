onset_of_winter = class({})

LinkLuaModifier("modifier_north_chilling_attack_debuff", "abilities/north/chilling_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_attack_freeze", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)

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
    direction = (direction + RandomVector(1)):Normalized()
    
    local projectile = {
      Ability       = self,
      EffectName      = "particles/custom/north/lich/lich_chain_frost_2.vpcf",
      vSpawnOrigin    = caster:GetAbsOrigin(),
      fDistance     = 9999,
      fStartRadius    = 100,
      fEndRadius      = 100,
      Source        = caster,
      bHasFrontalCone   = true,
      bReplaceExisting  = false,
      iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
      iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_NONE,
      iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      fExpireTime     = GameRules:GetGameTime() + 10.0,
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

  local dps = ExtraData.dps

  local enemies = FindEnemiesInRadius(caster, ExtraData.radius, location)

  for _,enemy in pairs(enemies) do
    enemy:AddNewModifier(caster, ability, "modifier_north_chilling_attack_debuff", {duration = 0.1})
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

  if not target then return end

  if target:HasFlyMovementCapability() then
    target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 3})
  else
    target:AddNewModifier(caster, ability, "modifier_frost_attack_freeze", {duration = 3})
  end
end