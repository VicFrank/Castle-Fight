LinkLuaModifier("modifier_plague_attack", "abilities/undead/plague_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_plague_attack_debuff", "abilities/undead/plague_attack.lua", LUA_MODIFIER_MOTION_NONE)

zombie_plague_attack = class({})
function zombie_plague_attack:GetIntrinsicModifierName() return "modifier_plague_attack" end

modifier_plague_attack = class({})

function modifier_plague_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_plague_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_plague_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    local debuffName = "modifier_plague_attack_debuff"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_plague_attack_debuff = class({})

function modifier_plague_attack_debuff:IsDebuff()
  return true
end

function modifier_plague_attack_debuff:GetTexture()
  return "undying_soul_rip"
end 

function modifier_plague_attack_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
  return decFuns
end

function modifier_plague_attack_debuff:OnCreated()
  if not IsServer() then return end
  
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  local playerID = self.caster.playerID or self.caster:GetPlayerOwnerID()
  if playerID < 0 then playerID = 0 end
  self.playerHero = PlayerResource:GetPlayer(playerID):GetAssignedHero()

  self.move_speed_slow = -self.ability:GetSpecialValueFor("move_speed_slow_pct")
  self.dps = self.ability:GetSpecialValueFor("dps")

  self:StartIntervalThink(1)
  self:DamageTick()
end

function modifier_plague_attack_debuff:DamageTick()
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

function modifier_plague_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed_slow
end

function modifier_plague_attack_debuff:OnIntervalThink()
  self:DamageTick()
end

function modifier_plague_attack_debuff:GetEffectName()
  return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

function modifier_plague_attack_debuff:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end