link = class({})
LinkLuaModifier("modifier_link_aura", "abilities/elemental/link.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_link_aura_buff", "abilities/elemental/link.lua", LUA_MODIFIER_MOTION_NONE)

function link:GetIntrinsicModifierName()
  return "modifier_link_aura"
end

modifier_link_aura = class({})

function modifier_link_aura:IsAura()
  return true
end

function modifier_link_aura:IsHidden()
  return false
end

function modifier_link_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_link_aura:IsPurgable()
  return false
end

function modifier_link_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = 99999
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_link_aura:GetModifierAura()
  return "modifier_link_aura_buff"
end

function modifier_link_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_link_aura:GetAuraEntityReject(target)
  return not target:IsElemental()
end

function modifier_link_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_link_aura:GetAuraDuration()
  return 0.5
end

modifier_link_aura_buff = class({})

function modifier_link_aura_buff:IsPurgable() return false end
function modifier_link_aura_buff:IsHidden() return true end

function modifier_link_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_link_aura_buff:OnDeath(params)
  if not IsServer() then return end

  local parent = self:GetParent()

  if params.unit == parent and not parent:HasModifier("modifier_illusion") then
    local ability = self:GetAbility()

    local max_heal = ability:GetSpecialValueFor("max_heal")
    local radius = ability:GetSpecialValueFor("radius")
    local heal_per_building = ability:GetSpecialValueFor("heal_per_building")

    -- heal nearby allied units 20 * number of elemental buildings
    local caster = ability:GetCaster()
    local playerID = caster:GetPlayerOwnerID()
    local buildings = BuildingHelper:GetBuildings(playerID)
    local numBuildings = TableCount(buildings)

    local healPool = math.min(numBuildings * heal_per_building, max_heal)

    local allies = FindAlliesInRadius(parent, radius)

    alliesToHeal = FilterTable(allies, function(ally)
      return not IsCustomBuilding(ally) and ally:GetHealthPercent() < 100
    end)

    local numAllies = TableCount(alliesToHeal)

    for _,ally in pairs(alliesToHeal) do
      local missingHealth = ally:GetMaxHealth() - ally:GetHealth()
      local amountToHeal = healPool / numAllies

      amountToHeal = math.min(amountToHeal, missingHealth)
      amountToHeal = math.min(amountToHeal, healPool)

      ally:Heal(amountToHeal, caster)

      healPool = healPool - amountToHeal

      if healPool <= 1 then
        return
      end
    end

    -- this isn't perfect, but I don't want to risk using a while loop
    if healPool > 0 then
      for _,ally in pairs(alliesToHeal) do
        local missingHealth = ally:GetMaxHealth() - ally:GetHealth()
        local amountToHeal = healPool / numAllies

        amountToHeal = math.min(amountToHeal, missingHealth)
        amountToHeal = math.min(amountToHeal, healPool)

        ally:Heal(amountToHeal, caster)

        healPool = healPool - amountToHeal

        if healPool <= 1 then
          return
        end
      end
    end
  end
end