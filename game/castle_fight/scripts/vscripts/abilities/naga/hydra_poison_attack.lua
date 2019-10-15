LinkLuaModifier("modifier_hydra_poison_attack", "abilities/naga/hydra_poison_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hydra_poison_attack_debuff", "abilities/naga/hydra_poison_attack.lua", LUA_MODIFIER_MOTION_NONE)

hydra_poison_attack = class({})
function hydra_poison_attack:GetIntrinsicModifierName() return "modifier_hydra_poison_attack" end

modifier_hydra_poison_attack = class({})

function modifier_hydra_poison_attack:IsHidden() return true end

function modifier_hydra_poison_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_hydra_poison_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_hydra_poison_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    local debuffName = "modifier_hydra_poison_attack_debuff"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_hydra_poison_attack_debuff = class({})

function modifier_hydra_poison_attack_debuff:IsDebuff()
  return true
end

function modifier_hydra_poison_attack_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
  return decFuns
end

function modifier_hydra_poison_attack_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.attack_slow = self.ability:GetSpecialValueFor("attack_slow")
  self.move_speed_slow = self.ability:GetSpecialValueFor("move_speed_slow")
  self.dps = self.ability:GetSpecialValueFor("dps")

  if not IsServer() then return end
  
  self.playerHero = self:GetCaster():GetPlayerHero()

  self:StartIntervalThink(1)
  self:DamageTick()
end

function modifier_hydra_poison_attack_debuff:DamageTick()
  if IsServer() then
    local final_damage = ApplyDamage({
      attacker = self.playerHero,
      victim = self.parent,
      ability = self.ability,
      damage = self.dps,
      damage_type = DAMAGE_TYPE_MAGICAL,
      damage_flags = DOTA_DAMAGE_FLAG_HPLOSS
    })
    
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self.parent, final_damage, nil)
  end
end

function modifier_hydra_poison_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_speed_slow
end

function modifier_hydra_poison_attack_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow;
end

function modifier_hydra_poison_attack_debuff:OnIntervalThink()
  self:DamageTick()
end

function modifier_hydra_poison_attack_debuff:GetEffectName()
  return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

function modifier_hydra_poison_attack_debuff:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end