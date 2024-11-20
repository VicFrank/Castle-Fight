call_to_arms = class({})
LinkLuaModifier("modifier_call_to_arms_buff", "abilities/human/call_to_arms.lua", LUA_MODIFIER_MOTION_NONE)

function call_to_arms:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
  
    local team = caster:GetTeamNumber()
    local position = point or caster:GetAbsOrigin()
    local num_targets = ability:GetSpecialValueFor("targets")
  
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    local allies =  FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, flags, FIND_ANY_ORDER, false)
  
    local friendlyBuildings = {}
  
    for _,target in pairs(allies) do
      if IsCustomBuilding(target) 
      and (target:GetBuildingType() == "UnitTrainer" or target:GetBuildingType() == "SiegeTrainer") 
      and not target:IsLegendary() 
      and not target:HasModifier("modifier_call_to_arms_buff") then
        table.insert(friendlyBuildings, target)
      end
    end

    caster:EmitSound("Hero_Chen.HolyPersuasionCast")
  
    local targets = GetRandomTableElements(friendlyBuildings, num_targets)

    if not targets then return end
      
    for _,target in pairs(targets) do
        target:AddNewModifier(caster, self, "modifier_call_to_arms_buff", {})
    end
end

modifier_call_to_arms_buff = class({})

function modifier_call_to_arms_buff:OnCreated()
  if not self:GetAbility() then return end

  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_holy_persuasion_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_call_to_arms_buff:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_holy_persuasion_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:ReleaseParticleIndex(particle)
  end
end

function modifier_call_to_arms_buff:GetEffectName()
  return "particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_beam.vpcf"
end

function modifier_call_to_arms_buff:IsPurgable()
  return false
end

function modifier_call_to_arms_buff:GetTexture()
  return "chen_holy_persuasion"
end