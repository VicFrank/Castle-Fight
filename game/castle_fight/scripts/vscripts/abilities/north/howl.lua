wendigo_howl = class({})

LinkLuaModifier("modifier_wendigo_howl", "abilities/north/howl.lua", LUA_MODIFIER_MOTION_NONE)

function wendigo_howl:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local duration = ability:GetSpecialValueFor("duration")
  local radius = ability:GetSpecialValueFor("radius")

  caster:EmitSound("Hero_Lycan.Howl")

  local particleName = "particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf"

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  local enemies = FindEnemiesInRadius(caster, radius)

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:IsRealHero() then
      enemy:AddNewModifier(caster, ability, "modifier_wendigo_howl", {duration = duration})
    end
  end
end

modifier_wendigo_howl = class({})

function modifier_wendigo_howl:IsDebuff() return true end
function modifier_wendigo_howl:IsPurgable() return true end

function modifier_wendigo_howl:OnCreated()
  self.armor = ability:GetSpecialValueFor("armor")
  self.damage_decrease = ability:GetSpecialValueFor("damage_decrease")
end

function modifier_wendigo_howl:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
      MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
    }
  return decFuns
end

function modifier_wendigo_howl:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_wendigo_howl:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage_decrease
end

function modifier_wendigo_howl:GetEffectName()
  return "particles/units/heroes/hero_lycan/lycan_howl_buff.vpcf"
end