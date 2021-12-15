mana_transfusion = class({})

LinkLuaModifier("modifier_mana_transfusion", "abilities/elemental/mana_transfusion.lua", LUA_MODIFIER_MOTION_NONE)

function mana_transfusion:OnSpellStart()
  local ability = self
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if ability.drain and not ability.drain:IsNull() then
    ability.drain:Destroy()
  end

  ability.drain = target:AddNewModifier(caster, ability, "modifier_mana_transfusion", {})
end

function mana_transfusion:OnChannelFinish()
  local ability = self
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if ability.drain and not ability.drain:IsNull() then
    ability.drain:Destroy()
  end
end

function mana_transfusion:OnOwnerDied()
  local ability = self
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if ability.drain and not ability.drain:IsNull() then
    ability.drain:Destroy()
  end
end

function mana_transfusion:GetChannelTime()
  return -1
end

function mana_transfusion:CastFilterResultTarget(target)
  if self:GetCaster() == target then
    return UF_FAIL_CUSTOM
  end

  if target:GetMaxMana() == 0 then
    return UF_FAIL_CUSTOM
  end

  if IsServer() then
    if not IsCustomBuilding(target) then
      return UF_FAIL_CUSTOM
    end
    if GetDistanceBetweenTwoUnits(self:GetCaster(), target) > 700 then
      return UF_FAIL_CUSTOM
    end
  end

  return UF_SUCCESS
end

function mana_transfusion:GetCustomCastErrorTarget(target)    
  if self:GetCaster() == target then
    return "#dota_hud_error_cant_cast_on_self"
  end

  if target:GetMaxMana() == 0 then
    return "#dota_hud_error_target_needs_mana"
  end

  if IsServer() then
    if not IsCustomBuilding(target) then
      return "#dota_hud_error_cant_cast_on_creep"
    end
    if GetDistanceBetweenTwoUnits(self:GetCaster(), target) > 700 then
      return "dota_hud_error_target_out_of_range"
    end
  end

  return ""
end

-----------------------------

modifier_mana_transfusion = class({})

function modifier_mana_transfusion:IsHidden() return true end

function modifier_mana_transfusion:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.mana_regen = self.ability:GetSpecialValueFor("mana_regen")
  self.non_elemental_reduction = self.ability:GetSpecialValueFor("non_elemental_reduction") / 100

  if not IsServer() then return end

  local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, self.parent)
  ParticleManager:SetParticleControlEnt(
    particle,
    0,
    self:GetParent(),
    PATTACH_POINT_FOLLOW,
    "attach_hitloc",
    Vector(0,0,0), -- unknown
    true -- unknown, true
  )
  ParticleManager:SetParticleControlEnt(
    particle,
    1,
    self:GetCaster(),
    PATTACH_POINT_FOLLOW,
    "attach_mouth",
    Vector(0,0,0), -- unknown
    true -- unknown, true
  )

  -- buff particle
  self:AddParticle(
    particle,
    false, -- bDestroyImmediately
    false, -- bStatusEffect
    -1, -- iPriority
    false, -- bHeroEffect
    false -- bOverheadEffect
  )

  if not self.parent:IsElementalBuilding() then
    self.mana_regen = self.mana_regen * self.non_elemental_reduction
  end
  
  self:StartIntervalThink(1)
end

function modifier_mana_transfusion:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_mana_transfusion:GetModifierConstantManaRegen()
  return self.mana_regen
end
