LinkLuaModifier("modifier_infernal_detonate", "abilities/corrupted/detonate.lua", LUA_MODIFIER_MOTION_NONE)

infernal_detonate = class({})
function infernal_detonate:GetIntrinsicModifierName() return "modifier_infernal_detonate" end
lunatic_goblin_detonate = class({})
function lunatic_goblin_detonate:GetIntrinsicModifierName() return "modifier_infernal_detonate" end

modifier_infernal_detonate = class({})

function modifier_infernal_detonate:IsDebuff() return false end
function modifier_infernal_detonate:IsPurgable() return false end
function modifier_infernal_detonate:IsHidden() return true end

function modifier_infernal_detonate:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_EVENT_ON_DEATH
    }
  return decFuns
end

function modifier_infernal_detonate:OnCreated()
  self.damage = self:GetAbility():GetSpecialValueFor("damage")
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_infernal_detonate:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    -- explode
    local damage = self.damage
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