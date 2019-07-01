LinkLuaModifier("modifier_spider_poison", "abilities/nature/poison.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spider_poison_debuff", "abilities/nature/poison.lua", LUA_MODIFIER_MOTION_NONE)

spider_poison = class({})
function spider_poison:GetIntrinsicModifierName() return "modifier_spider_poison" end

modifier_spider_poison = class({})

function modifier_spider_poison:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_spider_poison:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_spider_poison:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    local debuffName = "modifier_spider_poison_debuff"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_spider_poison_debuff = class({})

function modifier_spider_poison_debuff:IsDebuff()
  return true
end

function modifier_spider_poison_debuff:GetTexture()
  return "broodmother_poison_sting"
end 

function modifier_spider_poison_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
  return decFuns
end

function modifier_spider_poison_debuff:OnCreated()  
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.move_speed_slow = self.ability:GetSpecialValueFor("slow")
  self.dps = self.ability:GetSpecialValueFor("dps")

  if not IsServer() then return end

  local playerID = self.caster.playerID or self.caster:GetPlayerOwnerID()
  if playerID < 0 then playerID = 0 end
  self.playerHero = PlayerResource:GetPlayer(playerID):GetAssignedHero()


  self:StartIntervalThink(1)
  self:DamageTick()
end

function modifier_spider_poison_debuff:DamageTick()
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

function modifier_spider_poison_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_speed_slow
end

function modifier_spider_poison_debuff:OnIntervalThink()
  self:DamageTick()
end

function modifier_spider_poison_debuff:GetEffectName()
  return "particles/units/heroes/hero_broodmother/broodmother_poison_debuff.vpcf"
end

function modifier_spider_poison_debuff:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end