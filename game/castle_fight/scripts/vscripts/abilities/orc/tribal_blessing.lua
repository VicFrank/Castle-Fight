tribal_blessing = class({})

LinkLuaModifier("modifier_tribal_blessing", "abilities/orc/tribal_blessing.lua", LUA_MODIFIER_MOTION_NONE)

function tribal_blessing:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local max_stacks = ability:GetSpecialValueFor("max_stacks")
  local modifierName = "modifier_tribal_blessing"

  local allies = FindAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local target
  for _,ally in pairs(allies) do
    if not ally:IsRealHero() and not IsCustomBuilding(ally) then
      if not ally:HasModifier(modifierName) then
        target = ally
      elseif ally:HasModifier(modifierName) and ally:GetModifierStackCount(modifierName, ally) < max_stacks then
        target = ally
      end
    end
  end

  if not target then return end

  caster:EmitSound("Hero_Dazzle.Shallow_Grave")

  local modifier = target:AddNewModifier(target, ability, modifierName, {})

  local stackCount = target:GetModifierStackCount(modifierName, target)
  modifier:SetStackCount(math.min(stackCount + 1, max_stacks))

  local abilities = {
    "tribal_blessing_critical_strike",
    "tribal_blessing_evasion",
    "tribal_blessing_demolish",
  }

  local abilityToAdd = GetRandomTableElement(abilities)

  if target:HasAbility(abilityToAdd) then
    for _,abilityName in ipairs(abilities) do
      if not target:HasAbility(abilityName) then
        abilityToAdd = abilityName
        break
      end
    end
  end

  if abilityToAdd then
    local addedAbility = target:AddAbility(abilityToAdd)
    addedAbility:SetLevel(1)
  end
end

modifier_tribal_blessing = class({})

function modifier_tribal_blessing:OnCreated()
  self.damage_increase = self:GetAbility():GetSpecialValueFor("damage_increase")
  self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
  self.armor = self:GetAbility():GetSpecialValueFor("armor")

  if not IsServer() then return end

  local particleNameA = "particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff_base_b.vpcf"
  local particleNameB = "particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff_base.vpcf"
  self.particleA = ParticleManager:CreateParticle(particleNameA, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
  self.particleB = ParticleManager:CreateParticle(particleNameB, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_tribal_blessing:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_tribal_blessing:GetModifierPhysicalArmorBonus()
  return self:GetStackCount() * self.armor
end

function modifier_tribal_blessing:GetModifierAttackSpeedBonus_Constant()
  return self:GetStackCount() * self.attack_speed
end

function modifier_tribal_blessing:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount() * self.damage_increase
end

-- function modifier_tribal_blessing:GetEffectName()
--   return "particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff_base.vpcf"
-- end

function modifier_tribal_blessing:OnDestroy()
  if not IsServer() then return end
  ParticleManager:DestroyParticle(self.particleA, false)
  ParticleManager:DestroyParticle(self.particleB, false)
  ParticleManager:ReleaseParticleIndex(self.particleA)
  ParticleManager:ReleaseParticleIndex(self.particleB)
end

function modifier_tribal_blessing:GetTexture()
  return "ogre_magi_bloodlust"
end

function modifier_tribal_blessing:IsPurgable()
  return true
end