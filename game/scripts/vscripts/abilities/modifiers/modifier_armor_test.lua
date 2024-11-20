modifier_armor_test = class({})

function modifier_armor_test:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_armor_test:GetModifierPhysicalArmorBonus()
  return -16
end
