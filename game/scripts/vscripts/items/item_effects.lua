-- Handle what happens when a player purchases an item
LinkLuaModifier("modifier_bassline_aura", "items/modifiers/bassline_modifier.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drums_aura", "items/modifiers/drums_modifier.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_double_damage_aura", "items/modifiers/double_damage_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_quad_damage_aura", "items/modifiers/quad_damage_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rune_of_repair_aura", "items/modifiers/rune_of_repair_modifier.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blast_staff", "items/modifiers/blast_staff_modifier.lua", LUA_MODIFIER_MOTION_NONE)

function BlastStaff(keys)
  local caster = keys.caster
  local item = keys.ability

  local ability = caster:AddAbility("blast_staff_ability")
  ability:SetLevel(1)
  caster:AddNewModifier(caster, ability, "modifier_blast_staff", {})
end

function RuneOfRepair(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:AddNewModifier(caster, item, "modifier_rune_of_repair_aura", {})

  item:RemoveSelf()
end

function ScrollOfStone(keys)
  local caster = keys.caster
  local item = keys.ability
  item:RemoveSelf()

  local ability = caster:AddAbility("scroll_of_stone")
  ability:SetLevel(1)
end

function OrbOfLightning(keys)
  local caster = keys.caster
  local item = keys.ability
  item:RemoveSelf()

  local ability = caster:AddAbility("orb_of_lightning")
  ability:SetLevel(1)
end

function Bassline(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:AddNewModifier(caster, item, "modifier_bassline_aura", {})

  item:RemoveSelf()
end

function Drums(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:AddNewModifier(caster, item, "modifier_drums_aura", {})

  item:RemoveSelf()
end

function DoubleDamage(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:AddNewModifier(caster, item, "modifier_double_damage_aura", {duration = 30})

  item:RemoveSelf()
end

function QuadDamage(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:AddNewModifier(caster, item, "modifier_quad_damage_aura", {duration = 30})

  item:RemoveSelf()
end

function Cheese(keys)
  local caster = keys.caster
  local item = keys.ability
  caster:ModifyCheese(1)
  item:RemoveSelf()
end
