lightning_attack = class({})

LinkLuaModifier("modifier_lightning_attack", "abilities/elemental/lightning_attack.lua", LUA_MODIFIER_MOTION_NONE)

function lightning_attack:GetIntrinsicModifierName() return "modifier_lightning_attack" end

function lightning_attack:OnProjectileHit(target, location)
  if target and not IsCustomBuilding(target) then
    local damage = self:GetSpecialValueFor("damage")

    ApplyDamage({
      victim = target,
      attacker = self:GetCaster(),
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self,
    })
  end
end

-----------------------------

modifier_lightning_attack = class({})

function modifier_lightning_attack:IsHidden() return true end

function modifier_lightning_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage = self.ability:GetSpecialValueFor("damage")
  self.num_targets = self.ability:GetSpecialValueFor("num_targets")
  self.max_range = self.ability:GetSpecialValueFor("max_range")
end

function modifier_lightning_attack:OnRefresh()
  self.damage = self.ability:GetSpecialValueFor("damage")
  self.num_targets = self.ability:GetSpecialValueFor("num_targets")
  self.max_range = self.ability:GetSpecialValueFor("max_range")
end

function modifier_lightning_attack:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_lightning_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent then
    local enemies = FindEnemiesInRadius(attacker, self.max_range)
    local targets = {}

    print(#enemies, self.max_range)

    -- always insert the target first
    table.insert(targets, target)

    local centerDir = (attacker:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()

    for _,enemy in pairs(enemies) do
      if (enemy:GetEntityIndex() ~= target:GetEntityIndex()) and not IsCustomBuilding(enemy) then
        local targetDir = (attacker:GetAbsOrigin() - enemy:GetAbsOrigin()):Normalized()

        local angle = math.acos(centerDir:Dot(targetDir))
        angle = (angle * 180) / math.pi

        if angle < 180 then
          table.insert(targets, enemy)
        end        

        if TableCount(targets) > self.num_targets then break end
      end
    end

    if TableCount(targets) > 0 then
      attacker:EmitSound("Ability.PlasmaFieldImpact")
    end

    for _,enemy in pairs(targets) do
      local particleName = "particles/units/heroes/hero_razor/razor_base_attack.vpcf"

      local nfx = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, self.parent)
      ParticleManager:SetParticleControlEnt(nfx, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(nfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(nfx, 2, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(nfx, 9, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)

      ParticleManager:ReleaseParticleIndex(nfx)

      local damage = self.damage
      if IsCustomBuilding(target) then
        damage = damage * 0.4
      end

      ApplyDamage({
        victim = enemy,
        attacker = self.parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability,
      })
    end

  end
end
