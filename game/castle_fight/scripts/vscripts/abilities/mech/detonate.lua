goblin_shredder_detonate = class({})

LinkLuaModifier("modifier_goblin_shredder_detonate", "abilities/mech/detonate.lua", LUA_MODIFIER_MOTION_NONE)

function goblin_shredder_detonate:GetIntrinsicModifierName()
  return "modifier_goblin_shredder_detonate"
end

modifier_goblin_shredder_detonate = class({})

function modifier_goblin_shredder_detonate:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_EVENT_ON_DEATH
    }
  return decFuns
end

function modifier_goblin_shredder_detonate:OnCreated()
  self.base_damage = self:GetAbility():GetSpecialValueFor("base_damage")
  self.max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")
  self.radius = self:GetAbility():GetSpecialValueFor("radius")

  self:SetStackCount(1)
end

-- Currently this is set in inducted rage so it will work even when the ability is blocked
-- function modifier_goblin_shredder_detonate:OnBuildingTarget()
--   if not IsServer() then return end

--   self:IncrementStackCount()

--   if self:GetStackCount() > self.max_stacks then
--     self:SetStackCount(self.max_stacks)
--   end

--   return false
-- end

function modifier_goblin_shredder_detonate:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    -- explode
    -- 50, 100, 200, 400
    -- 1,  2  , 4,   8
    local multiplier = math.pow(2, self:GetStackCount() - 1)
    local damage = self.base_damage * multiplier
    local enemies = FindEnemiesInRadius(self:GetParent(), self.radius)

    for _,enemy in pairs(enemies) do
      if not IsCustomBuilding(enemy) then
        local damageTable = {
          victim = enemy,
          attacker = self:GetParent(),
          damage = damage / 2,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self:GetAbility()
        }

        ApplyDamage(damageTable)
      end
    end

    enemies = FindEnemiesInRadius(self:GetParent(), self.radius / 2)

    for _,enemy in pairs(enemies) do
      if not IsCustomBuilding(enemy) then
        local damageTable = {
          victim = enemy,
          attacker = self:GetParent(),
          damage = damage / 2,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self:GetAbility()
        }

        ApplyDamage(damageTable)
      end
    end
  end
end