ancient_protector_animations = class({})

LinkLuaModifier("modifier_ancient_protector_animations", "abilities/nature/ancient_protector_animations", LUA_MODIFIER_MOTION_NONE)

function ancient_protector_animations:GetIntrinsicModifierName()
  return "modifier_ancient_protector_animations"
end

modifier_ancient_protector_animations = class({})

function modifier_ancient_protector_animations:IsHidden() return true end

function modifier_ancient_protector_animations:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_ancient_protector_animations:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ancient_protector_animations:GetOverrideAnimation()
  return ACT_DOTA_CUSTOM_TOWER_IDLE
end

function modifier_ancient_protector_animations:OnCreated()
  if not IsServer() then return end

  local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(pfx)

  self:SetStackCount(self:GetCaster():GetTeamNumber())
end

function modifier_ancient_protector_animations:OnAttackStart(keys)
  if not IsServer() then return end

  if keys.attacker == self:GetParent() then
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_ATTACK, self:GetParent():GetAttacksPerSecond())
  end
end

function modifier_ancient_protector_animations:OnDeath(keys)
  if not IsServer() then return end

  if keys.unit == self:GetParent() then
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_DIE, 0.75)
  end
end