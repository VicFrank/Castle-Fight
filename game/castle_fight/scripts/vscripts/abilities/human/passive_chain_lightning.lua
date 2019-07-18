LinkLuaModifier("modifier_passive_chain_lightning", "abilities/human/passive_chain_lightning.lua", LUA_MODIFIER_MOTION_NONE)

passive_chain_lightning = class({})
function passive_chain_lightning:GetIntrinsicModifierName() return "modifier_passive_chain_lightning" end
sorceress_chain_lightning = class({})
function sorceress_chain_lightning:GetIntrinsicModifierName() return "modifier_passive_chain_lightning" end
energy_tower_energy_burst = class({})
function energy_tower_energy_burst:GetIntrinsicModifierName() return "modifier_passive_chain_lightning" end

modifier_passive_chain_lightning = class({})

function modifier_passive_chain_lightning:IsHidden() return true end

function modifier_passive_chain_lightning:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.trigger_chance = self.ability:GetSpecialValueFor("trigger_chance")
  self.initial_damage = self.ability:GetSpecialValueFor("initial_damage")
  self.max_targets = self.ability:GetSpecialValueFor("max_targets")
  self.jump_damage_reduction = self.ability:GetSpecialValueFor("jump_damage_reduction")
  self.jump_range = self.ability:GetSpecialValueFor("jump_range")
  self.jump_delay = self.ability:GetSpecialValueFor("jump_delay")
end

function modifier_passive_chain_lightning:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_passive_chain_lightning:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    if self.trigger_chance >= RandomInt(1,100) then
      if IsCustomBuilding(target) then return end

      OnLightningProc(self, target)
    end
  end
end

function OnLightningProc(modifier, target)
  modifier.caster:EmitSound("Item.Maelstrom.Chain_Lightning")

  local hit = {}
  hit[target] = true

  local lastBounce = modifier.caster
  local nextBounce = target
  local bounces = 1
  local damage = modifier.initial_damage

  Timers:CreateTimer(function()
    if not nextBounce or bounces >= modifier.max_targets then return end

    -- Apply the lightning
    nextBounce:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")

    local particleName = "particles/items_fx/chain_lightning.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, nextBounce)
    ParticleManager:SetParticleControlEnt(particle, 0, lastBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", lastBounce:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, nextBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", nextBounce:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(particle)

    ApplyDamage({
      attacker = modifier.caster, 
      victim = nextBounce,
      ability = modifier.ability,
      damage = damage, 
      damage_type = DAMAGE_TYPE_MAGICAL
    })

    damage = damage - (damage * modifier.jump_damage_reduction)

    -- Find the next bounce target
    lastBounce = nextBounce
    nextBounce = nil

    local nearbyEnemies = FindEnemiesInRadius(modifier.caster, modifier.jump_range, lastBounce:GetAbsOrigin())
    for _,enemy in pairs(nearbyEnemies) do
      if not hit[enemy] and not enemy:IsMagicImmune() and not IsCustomBuilding(enemy) then
        nextBounce = enemy
      end
    end

    if nextBounce then
      hit[nextBounce] = true
    end

    bounces = bounces + 1

    return modifier.jump_delay
  end)
end