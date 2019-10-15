LinkLuaModifier("modifier_frost_attack", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_attack_freeze", "abilities/north/frost_attack.lua", LUA_MODIFIER_MOTION_NONE)

hrimthrusa_frost_attack = class({})
function hrimthrusa_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end
ice_troll_frost_attack = class({})
function ice_troll_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end
ice_queen_frost_attack = class({})
function ice_queen_frost_attack:GetIntrinsicModifierName() return "modifier_frost_attack" end

modifier_frost_attack = class({})

function modifier_frost_attack:IsHidden() return true end

function modifier_frost_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
  self.chance = self.ability:GetSpecialValueFor("chance")
end

function modifier_frost_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_frost_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not target:HasFlyMovementCapability() and 
    not IsCustomBuilding(target) and self.chance >= RandomInt(1, 100) then
    local debuffName = "modifier_frost_attack_freeze"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_frost_attack_freeze = class({})

function modifier_frost_attack_freeze:IsDebuff()
  return true
end

function modifier_frost_attack_freeze:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_frost_attack_freeze:OnCreated( kv )
  if IsServer() then
    self:GetParent():EmitSound("Hero_Crystal.Frostbite")

    self.caster = self:GetCaster()

    self.dps = self:GetAbility():GetSpecialValueFor("dps")

    self.playerHero = self:GetCaster():GetPlayerHero()

    self:StartIntervalThink(1)
  end
end

function modifier_frost_attack_freeze:OnIntervalThink()
  if IsServer() then
    ApplyDamage({
      attacker = self.playerHero, 
      victim = self:GetParent(), 
      ability = self:GetAbility(),
      damage = self.dps,
      damage_type = DAMAGE_TYPE_MAGICAL
    })
  end
end

function modifier_frost_attack_freeze:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_frost_attack_freeze:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end