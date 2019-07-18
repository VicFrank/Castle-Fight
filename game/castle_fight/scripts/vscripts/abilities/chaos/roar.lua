chaos_warrior_roar = class({})

LinkLuaModifier("modifier_chaos_warrior_roar", "abilities/chaos/roar.lua", LUA_MODIFIER_MOTION_NONE)

function chaos_warrior_roar:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local radius = ability:GetSpecialValueFor("radius")
  local duration = ability:GetSpecialValueFor("duration")

  local allies = FindAlliesInRadius(caster, radius)

  caster:EmitSound("Hero_Beastmaster.Primal_Roar")

  local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_primal_roar.vpcf", PATTACH_POINT, caster)
  ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(nfx, 1, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(nfx)

  for _,ally in pairs(allies) do
    ally:AddNewModifier(caster, ability, "modifier_chaos_warrior_roar", {duration = duration})
  end
end

modifier_chaos_warrior_roar = class({})

function modifier_chaos_warrior_roar:OnCreated()
  self.damage_increase = self:GetAbility():GetSpecialValueFor("damage_increase")
end

function modifier_chaos_warrior_roar:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_chaos_warrior_roar:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage_increase
end
