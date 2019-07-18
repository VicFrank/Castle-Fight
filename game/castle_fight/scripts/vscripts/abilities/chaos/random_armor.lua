LinkLuaModifier("modifier_random_armor", "abilities/chaos/random_armor.lua", LUA_MODIFIER_MOTION_NONE)

blood_fiend_present_of_chaos = class({})
function blood_fiend_present_of_chaos:GetIntrinsicModifierName() return "modifier_random_armor" end

modifier_random_armor = class({})

function modifier_random_armor:IsHidden() return true end

function modifier_random_armor:OnCreated()
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not IsServer() then return end

  -- local attackTypes = {
  --   "normal",
  --   "pierce",
  --   "magic",
  --   "chaos",
  --   "siege",
  -- }

  local armorTypes = {
    "unarmored",
    "light",
    "medium",
    "heavy",
    "fortified",
    "divine",
    "hero",
  }

  -- local attack_type = GetRandomTableElement(attackTypes)
  -- ApplyModifier(parent, "modifier_attack_"..attack_type)

  local armor_type = GetRandomTableElement(armorTypes)
  ApplyModifier(parent, "modifier_armor_"..armor_type)
  if armor_type == "divine" then
    parent:SetBaseMagicalResistanceValue(40)
  end
end