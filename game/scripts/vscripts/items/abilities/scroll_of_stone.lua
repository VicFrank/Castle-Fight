scroll_of_stone = class({})

function scroll_of_stone:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function scroll_of_stone:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local position = self:GetCursorPosition()

  local heal = ability:GetSpecialValueFor("heal")
  local mana = ability:GetSpecialValueFor("mana")
  local duration = ability:GetSpecialValueFor("duration")
  local radius = ability:GetSpecialValueFor("radius")

  caster:EmitSound("DOTA_Item.Mekansm.Activate")

  local particleName = "particles/items2_fx/mekanism.vpcf"

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, position)
  ParticleManager:ReleaseParticleIndex(particle)

  local allies = FindAlliesInRadius(caster, radius, position)

  for _,ally in pairs(allies) do
    if not IsCustomBuilding(ally) and not ally:IsRealHero() then
      ally:Heal(heal, caster)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)

      ally:GiveMana(mana)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD , ally, mana, nil)

      ally:EmitSound("DOTA_Item.Mekansm.Target")

      local particleName = "particles/items2_fx/mekanism_recipient.vpcf"

      local mekansm_target_pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, ally)
      ParticleManager:SetParticleControl(mekansm_target_pfx, 0, caster:GetAbsOrigin())
      ParticleManager:SetParticleControl(mekansm_target_pfx, 1, ally:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(mekansm_target_pfx)

      ally:AddNewModifier(caster, ability, "modifier_scroll_of_stone", {duration = duration})
    end
  end

  caster:RemoveAbility("scroll_of_stone")
end

modifier_scroll_of_stone = class({})
LinkLuaModifier("modifier_scroll_of_stone", "items/abilities/scroll_of_stone.lua", LUA_MODIFIER_MOTION_NONE )     -- Heal buff

function modifier_scroll_of_stone:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_scroll_of_stone:OnCreated()
  self.armor = 6
end

function modifier_scroll_of_stone:GetModifierPhysicalArmorBonus()
  return self.armor
end