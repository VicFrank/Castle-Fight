skull_pile_raise_dead = class({})
skull_shrine_greater_raise_dead = class({})
necromancer_raise_dead = class({})
necromancer_greater_raise_dead = class({})
lich_ultimate_raise_dead = class({})

LinkLuaModifier("modifier_ultimate_raise_dead", "abilities/undead/raise_dead.lua", LUA_MODIFIER_MOTION_NONE)

local allSkeletons = {
  "skeletal_mage",
  "greater_skeletal_mage",
  "skeleton_archer",
  "greater_skeleton_archer",
  "skeleton_warrior",
  "greater_skeleton_warrior",
  "skeleton_hero",
  "skeleton_general",
}

local basicSkeletons = {
  "skeletal_mage",
  "skeleton_archer",
  "skeleton_warrior",
}

local greaterSkeletons = {
  "greater_skeletal_mage",
  "greater_skeleton_archer",
  "greater_skeleton_warrior",
  "skeleton_hero",
  "skeleton_general",
}

local noGeneralSkeletons = {
  "skeletal_mage",
  "greater_skeletal_mage",
  "skeleton_archer",
  "greater_skeleton_archer",
  "skeleton_warrior",
  "greater_skeleton_warrior",
  "skeleton_hero",
}

function skull_pile_raise_dead:OnSpellStart()
  local range = self:GetSpecialValueFor("range")
  RaiseDead(self:GetCaster(), basicSkeletons, FIND_UNITS_EVERYWHERE)
end

function skull_shrine_greater_raise_dead:OnSpellStart()
  RaiseDead(self:GetCaster(), allSkeletons, FIND_UNITS_EVERYWHERE)
end

function necromancer_raise_dead:OnSpellStart()
  RaiseDead(self:GetCaster(), basicSkeletons, 900)
end

function necromancer_greater_raise_dead:OnSpellStart()
  RaiseDead(self:GetCaster(), noGeneralSkeletons, 900)
end

function lich_ultimate_raise_dead:OnSpellStart()
  for i=1,2 do
    local skeleton = RaiseDead(self:GetCaster(), greaterSkeletons, 900)
    if skeleton then
      skeleton:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ultimate_raise_dead", {})
    end
  end
end


function RaiseDead(caster, skeletonTable, range)
  local corpses = Corpses:FindVisibleInRadius(caster:GetTeam(), caster:GetAbsOrigin(), range)
  
  if #corpses == 0 then return end

  local corpse = GetRandomTableElement(corpses)

  local unitname = GetRandomTableElement(skeletonTable)

  local position = corpse:GetAbsOrigin()
  local playerID = caster.playerID or caster:GetPlayerOwnerID()
  local team = caster:GetTeam()

  local skeleton = CreateLaneUnit(unitname, position, team, playerID)

  skeleton:AddNewModifier(caster, nil, "modifier_kill", {duration = 45})
  skeleton:SetNoCorpse()

  return skeleton
end

modifier_ultimate_raise_dead = class({})

function modifier_ultimate_raise_dead:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.armor_bonus = self.ability:GetSpecialValueFor("armor_bonus")
  self.damage_bonus = self.ability:GetSpecialValueFor("damage_bonus")
end

function modifier_ultimate_raise_dead:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
  }
  return funcs
end

function modifier_ultimate_raise_dead:GetModifierPhysicalArmorBonus()
  return self.armor_bonus
end

function modifier_ultimate_raise_dead:GetModifierBaseAttack_BonusDamage()
  return self.damage_bonus
end
