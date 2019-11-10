LinkLuaModifier("modifier_chilling_attack", "abilities/undead/chilling_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chilling_attack_debuff", "abilities/undead/chilling_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chilling_attack_fx", "abilities/undead/chilling_attack.lua", LUA_MODIFIER_MOTION_NONE)

frost_wyrm_chilling_attack = class({})
function frost_wyrm_chilling_attack:GetIntrinsicModifierName() return "modifier_chilling_attack" end

modifier_chilling_attack = class({})

function modifier_chilling_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
  self.radius = self.ability:GetSpecialValueFor("radius")
end

function modifier_chilling_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
  }
  return funcs
end

function modifier_chilling_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    local debuffName = "modifier_chilling_attack_debuff"

    local enemies = FindEnemiesInRadius(attacker, self.radius, target:GetAbsOrigin())
    for _,enemy in pairs(enemies) do
      enemy:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
    end
  end
end

function modifier_chilling_attack:GetAttackSound()
  return "Hero_DragonKnight.ElderDragonShoot3.Attack"
end

----------------------------------------------------------------------------------------------------

modifier_chilling_attack_debuff = class({})

function modifier_chilling_attack_debuff:IsDebuff()
  return true
end

function modifier_chilling_attack_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
  return decFuns
end

function modifier_chilling_attack_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.move_slow = self.ability:GetSpecialValueFor("move_slow")
  self.attack_slow = self.ability:GetSpecialValueFor("attack_slow")

  if not IsServer() then return end
  self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_chilling_attack_fx", {duration = self:GetDuration()})
end


function modifier_chilling_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end

function modifier_chilling_attack_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow
end

function modifier_chilling_attack_debuff:GetEffectName()
  return "particles/units/heroes/hero_abaddon/abaddon_frost_slow.vpcf"
end

function modifier_chilling_attack_debuff:OnDestroy()
  if IsServer() then
    self.parent:RemoveModifierByName("modifier_chilling_attack_fx")
  end
end
----------------------------------------------------------------------------------------------------

modifier_chilling_attack_fx = class ({})

function modifier_chilling_attack_fx:DeclareFunctions()
  return {}
end

function modifier_chilling_attack_fx:GetStatusEffectName()
  return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_chilling_attack_fx:StatusEffectPriority()
  return FX_PRIORITY_CHILLED
end

function modifier_chilling_attack_fx:IsHidden()
  return true
end

function modifier_chilling_attack_fx:IsDebuff()
  return false
end

function modifier_chilling_attack_fx:IsPurgable()
  return false
end