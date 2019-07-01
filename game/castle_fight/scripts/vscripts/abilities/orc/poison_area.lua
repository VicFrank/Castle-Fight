poison_area = class({})

LinkLuaModifier("modifier_poison_area_aura", "abilities/orc/poison_area.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_poison_area_debuff", "abilities/orc/poison_area.lua", LUA_MODIFIER_MOTION_NONE)

function poison_area:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local duration = ability:GetSpecialValueFor("duration")

  CreateModifierThinker(caster, ability, "modifier_poison_area_aura",
    {duration = duration}, target:GetAbsOrigin(), caster:GetTeam(), false)
end

modifier_poison_area_aura = class({})

function modifier_poison_area_aura:IsAura()
  return true
end

function modifier_poison_area_aura:OnCreated(keys)
  if IsServer() then
    self.caster = self:GetCaster()
    self.thinker = self:GetParent()
    self.ability = self:GetAbility()

    self.thinker:EmitSound("Hero_Alchemist.AcidSpray")

    self.radius = self.ability:GetSpecialValueFor("radius")

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", PATTACH_POINT_FOLLOW, self.thinker)
    ParticleManager:SetParticleControl(self.particle, 0, (Vector(0, 0, 0)))
    ParticleManager:SetParticleControl(self.particle, 1, (Vector(self.radius, 1, 1)))
    ParticleManager:SetParticleControl(self.particle, 15, (Vector(25, 150, 25)))
    ParticleManager:SetParticleControl(self.particle, 16, (Vector(0, 0, 0)))
  end
end

function modifier_poison_area_aura:GetAuraRadius()
  return self.radius
end

function modifier_poison_area_aura:GetAuraSearchTeam()
  return self.ability:GetAbilityTargetTeam()
end

function modifier_poison_area_aura:GetAuraSearchType()
  return self.ability:GetAbilityTargetType()
end

function modifier_poison_area_aura:GetAuraSearchFlags()
  return self.ability:GetAbilityTargetFlags()
end

function modifier_poison_area_aura:GetModifierAura()
  return "modifier_poison_area_debuff"
end

function modifier_poison_area_aura:OnDestroy(keys)
  if IsServer() then
    local thinker = self:GetParent()
    thinker:StopSound("Hero_Alchemist.AcidSpray")
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
end


modifier_poison_area_debuff = class({})

function modifier_poison_area_debuff:IsDebuff()
  return true
end

function modifier_poison_area_debuff:IsPurgable()
  return true
end

function modifier_poison_area_debuff:OnCreated()
  self.caster = self:GetCaster()
  local ability = self:GetAbility()

  self.armor_reduction = ability:GetSpecialValueFor("armor_reduction")
  self.attack_slow = ability:GetSpecialValueFor("attack_slow")
  self.move_slow = ability:GetSpecialValueFor("move_slow")
  self.dps = ability:GetSpecialValueFor("dps")
  
  if IsServer() then
    self.tick_rate = 0.2
    self:StartIntervalThink(self.tick_rate)
  end
end

function modifier_poison_area_debuff:OnIntervalThink()
  if IsServer() then
    self.caster = self.caster or self:GetCaster()
    self.ability = self.ability or self:GetAbility()

    local unit = self:GetParent()

    local damage = self.dps * self.tick_rate
    local damage_table = {
      victim = unit,
      attacker = self.caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self.ability,
    }
    ApplyDamage(damage_table)

    EmitSoundOn("Hero_Alchemist.AcidSpray.Damage", unit)
  end
end

function modifier_poison_area_debuff:GetTexture()
  return "alchemist_acid_spray"
end

function modifier_poison_area_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
end

function modifier_poison_area_debuff:GetModifierPhysicalArmorBonus()
  return -self.armor_reduction
end

function modifier_poison_area_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end

function modifier_poison_area_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow
end