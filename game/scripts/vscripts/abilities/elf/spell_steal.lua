blademaster_spell_steal = class({})

function blademaster_spell_steal:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local modifiers = target:FindAllModifiers()

  local targetIsFriendly = target:GetTeam() == caster:GetTeam()

  -- Get the modifier to remove
  local modifier

  for _,buff in pairs(modifiers) do
    -- if it's an ally, get a debuff
    -- only works on lua modifiers
    if buff.IsDebuff and buff.IsPurgable then
      if targetIsFriendly then
        if buff:IsDebuff() and buff:IsPurgable() then
          modifier = buff
          break
        end
      -- if it's an enemy, get a buff
      elseif not buff:IsDebuff() and buff:IsPurgable() then
        modifier = buff
        break
      end
    end
  end

  -- Choose the unit to recieve the buff at random
  local unitToBuff

  local radius = ability:GetSpecialValueFor("radius")
  local unitFilter = function(unit) return not target:IsLegendary() and not IsCustomBuilding(unit) end

  if targetIsFriendly then
    -- give the debuff to an enemy
    local enemies = FindEnemiesInRadius(caster, radius)
    enemies = FilterTable(enemies, unitFilter)
    unitToBuff = GetRandomTableElement(enemies)
  else
    -- give the buff to an ally
    local allies = FindAlliesInRadius(caster, radius)
    allies = FilterTable(allies, unitFilter)
    unitToBuff = GetRandomTableElement(allies)
  end

  -- if we've found a modifier to give, and a unit to give it to, transfer it
  if unitToBuff and modifier then
    modifier:Transfer(target, unitToBuff)
  else
    print("Spell Steal failed")
  end
end