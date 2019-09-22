LinkLuaModifier("modifier_random_armor", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)
-- -10 armor, 30% evasion, 20% of 2x crits, 30% vampirism, some fire shit caused spell damage to random unit in 400 radius
LinkLuaModifier("modifier_present_of_chaos_armor", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_present_of_chaos_evasion", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_present_of_chaos_crit", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_present_of_chaos_lifesteal", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_present_of_chaos_corruption", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)

blood_fiend_present_of_chaos = class({})
function blood_fiend_present_of_chaos:GetIntrinsicModifierName() return "modifier_random_armor" end

modifier_random_armor = class({})

function modifier_random_armor:IsHidden() return true end

function modifier_random_armor:OnCreated()
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not IsServer() then return end

  -- local attackTypes = {
  --   "normal",
  --   "pierce",
  --   "magic",
  --   "chaos",
  --   "siege",
  -- }

  local armorTypes = {
    "unarmored",
    "light",
    "medium",
    "heavy",
    "fortified",
    "divine",
    "hero",
  }

  local modifiers = {
    "modifier_present_of_chaos_corruption",
    "modifier_present_of_chaos_evasion",
    "modifier_present_of_chaos_crit",
    "modifier_present_of_chaos_lifesteal",
  }

  -- local attack_type = GetRandomTableElement(attackTypes)
  -- ApplyModifier(parent, "modifier_attack_"..attack_type)

  local armor_type = GetRandomTableElement(armorTypes)
  ApplyModifier(parent, "modifier_armor_"..armor_type)
  if armor_type == "divine" then
    parent:SetBaseMagicalResistanceValue(40)
  end

  local modifier = GetRandomTableElement(modifiers)
  parent:AddNewModifier(parent, ability, modifier, {})
end

modifier_present_of_chaos_corruption = class({})

function modifier_present_of_chaos_corruption:IsPurgable() return false end

function modifier_present_of_chaos_corruption:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_present_of_chaos_corruption:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self:GetParent() then
    target:AddNewModifier(attacker, self:GetAbility(), "modifier_present_of_chaos_armor", {duration = 3})
  end
end

modifier_present_of_chaos_armor = class({})

function modifier_present_of_chaos_armor:IsPurgable() return true end

function modifier_present_of_chaos_armor:DeclareFunctions()
  return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_present_of_chaos_armor:GetModifierPhysicalArmorBonus()
  return -10
end

modifier_present_of_chaos_evasion = class({})

function modifier_present_of_chaos_evasion:IsPurgable() return false end

function modifier_present_of_chaos_evasion:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
end

function modifier_present_of_chaos_evasion:GetModifierEvasion_Constant()
  return 30
end

function modifier_present_of_chaos_evasion:OnAttackFail(keys)
  local fail_type = keys.fail_type
  local target = keys.target
  local attacker = keys.attacker

  if target == self:GetParent() then
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MISS, attacker, 0, nil)
  end
end

modifier_present_of_chaos_crit = class({})

function modifier_present_of_chaos_crit:IsPurgable() return false end

function modifier_present_of_chaos_crit:DeclareFunctions()
  return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_present_of_chaos_crit:GetModifierPreAttack_CriticalStrike(params)
    if RollPercentage(20) then
      return 200
    else
      return nil
    end
end

modifier_present_of_chaos_lifesteal = class({})

function modifier_present_of_chaos_lifesteal:IsPurgable() return false end

function modifier_present_of_chaos_lifesteal:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_present_of_chaos_lifesteal:OnAttackLanded(params)
  if not IsServer() then return end
  
  local parent = self:GetParent()
  local target = params.target
  local attacker = params.attacker
  local ability = self:GetAbility()
  local damage = params.damage

  if attacker == parent then
    local lifesteal = 30
    attacker:Heal(damage * lifesteal * 0.01, attacker)

    local particleName = "particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:SetParticleControlEnt(particle, 0, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
  end
end