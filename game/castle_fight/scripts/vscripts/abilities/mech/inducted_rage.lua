goblin_shredder_inducted_rage = class({})

LinkLuaModifier("modifier_goblin_shredder_inducted_rage", "abilities/mech/inducted_rage.lua", LUA_MODIFIER_MOTION_NONE)

function goblin_shredder_inducted_rage:GetIntrinsicModifierName()
  return "modifier_goblin_shredder_inducted_rage"
end

modifier_goblin_shredder_inducted_rage = class({})

function modifier_goblin_shredder_inducted_rage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_goblin_shredder_inducted_rage:OnCreated()
  self.block_chance = self:GetAbility():GetSpecialValueFor("block_chance")
  self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
  self.max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")

  self:SetStackCount(1)
end

function modifier_goblin_shredder_inducted_rage:OnBuildingTarget()
  if not IsServer() then return end

  self:IncrementStackCount()

  if self:GetStackCount() > self.max_stacks then
    self:SetStackCount(self.max_stacks)
  end

  if RollPercentage(self.block_chance) then
    return true
  end

  return false
end

function modifier_goblin_shredder_inducted_rage:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed * self:GetStackCount()
end
