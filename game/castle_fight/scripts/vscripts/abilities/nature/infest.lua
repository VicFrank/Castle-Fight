brood_mother_infest = class({})
LinkLuaModifier("modifier_brood_mother_infest", "abilities/nature/infest", LUA_MODIFIER_MOTION_NONE)

function brood_mother_infest:OnSpellStart()
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

function brood_mother_infest:OnProjectileHit(target, locationn)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")
  local damage = self:GetSpecialValueFor("damage")

  if target then
    target:EmitSound("Hero_Broodmother.SpawnSpiderlingsCast")
    target:AddNewModifier(caster, self, "modifier_brood_mother_infest", {duration = duration})

    ApplyDamage({
      victim = target,
      attacker = caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self,
    })
  end
end

modifier_brood_mother_infest = class({})

function modifier_brood_mother_infest:IsDebuff() return true end

function modifier_brood_mother_infest:GetEffectName()
  return "particles/units/heroes/hero_broodmother/broodmother_spiderlings_debuff.vpcf"
end

function modifier_brood_mother_infest:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_brood_mother_infest:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    for i=1,2 do
      local unitName = "forest_spider"
      local position = self:GetParent():GetAbsOrigin()
      local team = self:GetCaster():GetTeam()
      local playerID = self:GetParent().playerID
      CreateLaneUnit(unitName, position, team, playerID)
    end
  end
end

function modifier_brood_mother_infest:OnCreated()
  if not IsServer() then return end
  
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.playerHero = self:GetCaster():GetPlayerHero()

  self.dps = self.ability:GetSpecialValueFor("dps")

  self:StartIntervalThink(1)
end

function modifier_brood_mother_infest:OnIntervalThink()
  if not IsServer() then return end

  local final_damage = ApplyDamage({
    attacker = self.playerHero,
    victim = self.parent,
    ability = self.ability,
    damage = self.dps,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_HPLOSS
  })
  
  SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self.parent, final_damage, nil)
end