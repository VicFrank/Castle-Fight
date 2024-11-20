bright_aura_of_grace = class({})
LinkLuaModifier("modifier_bright_aura_of_grace_aura", "abilities/elf/bright_aura_of_grace.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bright_aura_of_grace_aura_buff", "abilities/elf/bright_aura_of_grace.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bright_aura_of_grace_resurrect_debuff", "abilities/elf/bright_aura_of_grace.lua", LUA_MODIFIER_MOTION_NONE)

function bright_aura_of_grace:GetIntrinsicModifierName()
  return "modifier_bright_aura_of_grace_aura"
end

modifier_bright_aura_of_grace_aura = class({})

function modifier_bright_aura_of_grace_aura:IsAura()
  return true
end

function modifier_bright_aura_of_grace_aura:IsHidden()
  return false
end

function modifier_bright_aura_of_grace_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_bright_aura_of_grace_aura:IsPurgable()
  return false
end

function modifier_bright_aura_of_grace_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = 99999
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_bright_aura_of_grace_aura:GetModifierAura()
  return "modifier_bright_aura_of_grace_aura_buff"
end

function modifier_bright_aura_of_grace_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_bright_aura_of_grace_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:IsLegendary() or target:HasModifier("modifier_bright_aura_of_grace_resurrect_debuff")
end

function modifier_bright_aura_of_grace_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_bright_aura_of_grace_aura:GetAuraDuration()
  return 0.5
end

modifier_bright_aura_of_grace_aura_buff = class({})

function modifier_bright_aura_of_grace_aura_buff:IsPurgable()
  return false
end

function modifier_bright_aura_of_grace_aura_buff:GetTexture()
  return "omniknight_guardian_angel"
end

function modifier_bright_aura_of_grace_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_bright_aura_of_grace_aura_buff:OnDeath(params)
  if not IsServer() then return end

  local ability = self:GetAbility()
  if not ability:IsCooldownReady() then return end

  local parent = self:GetParent()
  local attacker = params.attacker

  if params.unit == parent then
    local chance = ability:GetSpecialValueFor("chance")
    local cooldown = ability:GetSpecialValueFor("cooldown")

    if chance >= RandomInt(1, 100) then
      local unitName = parent:GetUnitName()
      local position = parent:GetAbsOrigin()
      local team = parent:GetTeam()
      local playerID = parent.playerID
      local fv = parent:GetForwardVector()
      ability:StartCooldown(cooldown)

      -- revive after 2 seconds
      Timers:CreateTimer(2, function()
        local resurrected = CreateLaneUnit(unitName, position, team, playerID)

        resurrected:SetForwardVector(fv)
        FindClearSpaceForUnit(resurrected, position, true)

        resurrected:AddNewModifier(attacker, ability, "modifier_bright_aura_of_grace_resurrect_debuff", {})

        resurrected:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN_FOLLOW, resurrected)
        Timers:CreateTimer(1.5, function()
          ParticleManager:DestroyParticle(particle, false)
        end)
      end)
    end
  end
end



modifier_bright_aura_of_grace_resurrect_debuff = class({})

function modifier_bright_aura_of_grace_resurrect_debuff:IsPurgable()
  return false
end

function modifier_bright_aura_of_grace_resurrect_debuff:DeclareFunctions()
  local funcs = {
  }
  return funcs
end

function modifier_bright_aura_of_grace_aura_buff:GetTexture()
  return "omniknight_guardian_angel"
end