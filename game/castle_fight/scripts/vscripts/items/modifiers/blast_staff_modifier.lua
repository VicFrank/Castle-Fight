modifier_blast_staff = class({})

function modifier_blast_staff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_blast_staff:GetTexture()
  return "item_rod_of_atos"
end

function modifier_blast_staff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.radius = 600

  self:StartIntervalThink(1)
end

function modifier_blast_staff:OnIntervalThink()
  if not IsServer() then return end
  -- if there's an enemy in range, fire a projectile
  local enemies = FindEnemiesInRadius(self.caster, self.radius)

  if #enemies == 0 then return end

  local enemy = GetRandomTableElement(enemies)

  local particleName = "particles/units/heroes/hero_puck/puck_base_attack.vpcf"

  local projectile = {
    Target = enemy,
    Source = self.caster,
    Ability = self.ability,
    EffectName = particleName,
    iMoveSpeed = 900,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
  }

  ProjectileManager:CreateTrackingProjectile(projectile)  
end