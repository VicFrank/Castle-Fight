elemental_enchantment = class({})

LinkLuaModifier("modifier_elemental_forge_weapons", "abilities/elemental/elemental_enchantment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_rock_shield", "abilities/elemental/elemental_enchantment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elemental_haste", "abilities/elemental/elemental_enchantment.lua", LUA_MODIFIER_MOTION_NONE)

function elemental_enchantment:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local heal = ability:GetSpecialValueFor("heal")

  local abilityNames = {
    "forge_weapons",
    "rock_shield",
    "haste",
    "rejuvenation",
  }

  local abilityToAdd = GetRandomTableElement(abilityNames)

  local allies = FindAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local target

  -- Rejuvenation can hit any unit that's missing health
  if abilityToAdd == "rejuvenation" then
    for _,ally in pairs(allies) do
      if ally:GetHealthPercent() < 100 and not IsCustomBuilding(ally) then
        target = ally
        break
      end
    end

    if not target then return end

    local particleName = "particles/units/heroes/hero_chen/chen_hand_of_god.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)

    target:EmitSound("Hero_Chen.HandOfGodHealCreep")

    target:Heal(heal, target)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil) 
  else
    -- Other abilities can only buff a unit that hasn't been buffed yet
    for _,ally in pairs(allies) do
      if not ally:IsRealHero() and not IsCustomBuilding(ally) and ally:GetUnitName() ~= "lunatic_goblin" then
        local hasAbility = false

        if ally:FindAbilityByName(abilityToAdd) then
          hasAbility = true
        end

        if not hasAbility then
          target = ally
          break
        end
      end
    end

    if not target then return end

    local particleName = "particles/units/heroes/hero_chen/chen_hand_of_god.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)

    target:EmitSound("Hero_Chen.HandOfGodHealCreep")

    if abilityToAdd then
      local addedAbility = target:AddAbility(abilityToAdd)
      addedAbility:SetLevel(1)
    end
  end
end

forge_weapons = class({})

function forge_weapons:GetIntrinsicModifierName() return "modifier_elemental_forge_weapons" end

modifier_elemental_forge_weapons = class({})

function modifier_elemental_forge_weapons:IsHidden() return true end

function modifier_elemental_forge_weapons:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.splash_radius = 250
  self.splash_damage = 50
end

function modifier_elemental_forge_weapons:OnRefresh()
  self:OnCreated()
end

function modifier_elemental_forge_weapons:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_elemental_forge_weapons:OnAttackLanded(params)
  if not IsServer() then return end

  local attacker = params.attacker
  local target = params.target
  local damage = params.damage

  if attacker == self.parent then
    if self:GetParent():PassivesDisabled() then
      return 0
    end

    if target ~= nil and target:GetTeamNumber() ~= self.parent:GetTeamNumber() then
      -- for now, I'm going to say this can hit both air/ground
      -- will maybe change in the future

      local enemies = FindEnemiesInRadius(attacker, self.splash_radius, target:GetAbsOrigin())

      for _,enemy in pairs(enemies) do
        if enemy:GetEntityIndex() ~= target:GetEntityIndex() then
          ApplyDamage({
            victim = enemy,
            attacker = attacker,
            damage = damage * self.splash_damage / 100,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self.ability,
          })
        end
      end
    end
  end
end

rock_shield = class({})

function rock_shield:GetIntrinsicModifierName() return "modifier_elemental_rock_shield" end

modifier_elemental_rock_shield = class({})

function modifier_elemental_rock_shield:IsHidden() return true end

function modifier_elemental_rock_shield:OnCreated()
  self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_elemental_rock_shield:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_elemental_rock_shield:GetModifierPhysicalArmorBonus()
  return 15
end

haste = class({})

function haste:GetIntrinsicModifierName() return "modifier_elemental_haste" end

modifier_elemental_haste = class({})

function modifier_elemental_haste:IsHidden() return true end

function modifier_elemental_haste:OnCreated()
  self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
  self.move_speed = self:GetAbility():GetSpecialValueFor("move_speed")
end

function modifier_elemental_haste:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_elemental_haste:GetModifierAttackSpeedBonus_Constant(keys)
  return 75
end

function modifier_elemental_haste:GetModifierMoveSpeedBonus_Percentage(keys)
  return 25
end