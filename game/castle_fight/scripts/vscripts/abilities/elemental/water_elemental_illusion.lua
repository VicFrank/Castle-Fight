water_elemental_illusion = class({})

LinkLuaModifier("modifier_water_elemental_illusion", "abilities/elemental/water_elemental_illusion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_manta_invulnerable", "abilities/elemental/water_elemental_illusion.lua", LUA_MODIFIER_MOTION_NONE)

function water_elemental_illusion:GetIntrinsicModifierName() return "modifier_water_elemental_illusion" end

modifier_water_elemental_illusion = class({})

function modifier_water_elemental_illusion:IsHidden() return true end

function modifier_water_elemental_illusion:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.copy_chance = self.ability:GetSpecialValueFor("copy_chance")
end

function modifier_water_elemental_illusion:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_water_elemental_illusion:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent and not attacker:HasModifier("modifier_illusion") then
    if RollPercentage(self.copy_chance) then
      attacker:EmitSound("DOTA_Item.Manta.Activate")
      attacker:AddNewModifier(self.parent, self.ability, "modifier_manta_invulnerable", {duration = 0.4})
    end
  end
end

modifier_manta_invulnerable = class({})

function modifier_manta_invulnerable:IsHidden() return true end
function modifier_manta_invulnerable:IsPurgable() return false end

function modifier_manta_invulnerable:GetEffectName()
  return "particles/items2_fx/manta_phase.vpcf"
end

function modifier_manta_invulnerable:OnDestroy()
  if not IsServer() or not self:GetParent():IsAlive() or not self:GetAbility() then return end

  self:GetParent():Stop()

  local currentIllusion = self:GetAbility().currentIllusion

  if IsValidAlive(currentIllusion) then
    currentIllusion:ForceKill(false)
  end
    
  self.outgoing_damage = self:GetAbility():GetSpecialValueFor("illusion_damage_out_pct")
  self.incoming_damage = self:GetAbility():GetSpecialValueFor("illusion_damage_in_pct")
  self.illusion_duration = self:GetAbility():GetSpecialValueFor("illusion_duration")

  self.distance_multiplier = 108

  local unitname = self:GetParent():GetUnitName()
  local location = self:GetParent():GetAbsOrigin()
  local team = self:GetParent():GetTeam()
  local playerID = self:GetParent():CustomGetPlayerOwnerID()

  local illusion = CreateLaneUnit(unitname, location, team, playerID)

  illusion:SetHealth(self:GetParent():GetHealth())
  illusion:SetMana(self:GetParent():GetMana())

  illusion:AddNewModifier(
    self:GetParent(),
    self:GetAbility(),
    "modifier_illusion", 
    {
      duration = self.duration,
      outgoing_damage = -self.outgoing_damage,
      incoming_damage = self.incoming_damage,
    }
  )
  illusion:AddNewModifier(
    self:GetParent(),
    self:GetAbility(),
    "modifier_kill",
    {duration = self.illusion_duration}
  )

  FindClearSpaceForUnit(self:GetParent(), location + RandomVector(self.distance_multiplier), true)
  FindClearSpaceForUnit(illusion, location + RandomVector(self.distance_multiplier), true)

  self:GetAbility().currentIllusion = illusion
end

function modifier_manta_invulnerable:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION]  = true
  }
end