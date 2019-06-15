defender_defend = class({})
LinkLuaModifier("modifier_defender_defend", "abilities/human/defender_defend.lua", LUA_MODIFIER_MOTION_NONE)

function defender_defend:GetIntrinsicModifierName()
  return "modifier_defender_defend"
end

modifier_defender_defend = class({})

function modifier_defender_defend:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.ranged_repel_chance = self.ability:GetSpecialValueFor("ranged_repel_chance")
  self.ranged_damage_reduction = self.ability:GetSpecialValueFor("ranged_damage_reduction")
  self.spell_damage_reduction = self.ability:GetSpecialValueFor("spell_damage_reduction")
end

function modifier_defender_defend:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
  }
  return funcs
end

function modifier_defender_defend:GetModifierPhysical_ConstantBlock(keys)
  if not IsServer() then return end

  local parent = keys.target
  local attacker = keys.attacker
  local damage = keys.damage

  local sound = "Hero_Mars.Shield.Block"
  local soundSmall = "Hero_Mars.Shield.BlockSmall"
  local particleName = "particles/units/heroes/hero_mars/mars_shield_of_mars.vpcf"
  local particleNameSmall = "particles/units/heroes/hero_mars/mars_shield_of_mars_small.vpcf"

  local distance = (attacker:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()

  if distance > 250 then
    -- if it was a ranged attack, chance to repel it completely
    if self.ranged_repel_chance > RandomInt(1,100) then
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:ReleaseParticleIndex(particle)

      self.parent:EmitSound(sound)

      return damage
    else
      local particle = ParticleManager:CreateParticle(particleNameSmall, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:ReleaseParticleIndex(particle)

      self.parent:EmitSound(soundSmall)

      return damage * self.ranged_damage_reduction * .01
    end
  end

  return 0
end

function modifier_defender_defend:GetModifierMagicalResistanceBonus()
  return self.spell_damage_reduction
end