fire_elemental_split = class({})

LinkLuaModifier("modifier_fire_elemental_split", "abilities/elemental/fire_elemental_split.lua", LUA_MODIFIER_MOTION_NONE)

function fire_elemental_split:GetIntrinsicModifierName() return "modifier_fire_elemental_split" end

modifier_fire_elemental_split = class({})

function modifier_fire_elemental_split:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  if not self.ability then return end

  self.num_attacks = self.ability:GetSpecialValueFor("num_attacks")

  self:SetStackCount(0)
end

function modifier_fire_elemental_split:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_fire_elemental_split:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker

  if IsValidAlive(attacker) and attacker == self.parent then
    self:IncrementStackCount()

    if self:GetStackCount() >= self.num_attacks then
      local copy = CreateLaneUnit(
        attacker:GetUnitName(),
        attacker:GetAbsOrigin(),
        attacker:GetTeam(),
        attacker:CustomGetPlayerOwnerID()
      )

      local particleName = "particles/generic_hero_status/hero_levelup.vpcf"
      local particle =  ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, copy)
      ParticleManager:ReleaseParticleIndex(particle)

      copy:EmitSound("Hero_Invoker.ForgeSpirit")
      copy:RemoveAbility("fire_elemental_split")
      copy:SetHealth(attacker:GetHealth())

      self:SetStackCount(0)
    end
  end
end
