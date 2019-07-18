LinkLuaModifier("modifier_incinerate", "abilities/corrupted/incinerate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_incinerate_debuff", "abilities/corrupted/incinerate.lua", LUA_MODIFIER_MOTION_NONE)

void_walker_incinerate = class({})
function void_walker_incinerate:GetIntrinsicModifierName() return "modifier_incinerate" end

modifier_incinerate = class({})

function modifier_incinerate:IsHidden() return true end

function modifier_incinerate:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
  self.damage_per_hit = self:GetAbility():GetSpecialValueFor("damage_per_hit")
end

function modifier_incinerate:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_incinerate:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    local debuffName = "modifier_incinerate_debuff"

    if target:HasModifier(debuffName) then
      local stackCount = target:GetModifierStackCount(debuffName, self.target)
      -- target:SetModifierStackCount(debuffName, self.target, stackCount + 1)
      target:SetModifierStackCount(debuffName, self.target, 1)

      local damageTable = {
        victim = target,
        attacker = attacker,
        damage = self.damage_per_hit,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self:GetAbility()
      }

      ApplyDamage(damageTable)
    else
      target:AddNewModifier(self.caster, self.ability, debuffName, {})
      target:SetModifierStackCount(debuffName, self.target, 1)
    end
  end
end

modifier_incinerate_debuff = class({})

function modifier_incinerate_debuff:IsDebuff()
  return true
end

function modifier_incinerate_debuff:GetTexture()
  return "bane_brain_sap"
end 

function modifier_incinerate_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_EVENT_ON_DEATH
    }
  return decFuns
end

function modifier_incinerate_debuff:OnCreated()
  self.explode_damage = self:GetAbility():GetSpecialValueFor("explode_damage")
  self.full_aoe = self:GetAbility():GetSpecialValueFor("full_aoe")
  self.half_aoe = self:GetAbility():GetSpecialValueFor("half_aoe")
  self.team = self:GetCaster():GetTeam()

  if not IsServer() then return end

  local playerID = self:GetCaster().playerID or self:GetCaster():GetPlayerOwnerID()
  if playerID < 0 then playerID = 0 end
  self.playerHero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
end

function modifier_incinerate_debuff:OnDeath(keys)
  if not IsServer() then return nil end

  if keys.unit == self:GetParent() then
    -- explode
    local damage = self.explode_damage
    local enemies = FindEnemiesInRadiusFromTeam(self.team, self.half_aoe, self:GetParent():GetAbsOrigin())

    for _,enemy in pairs(enemies) do
      if not IsCustomBuilding(enemy) then
        local damageTable = {
          victim = enemy,
          attacker = self.playerHero,
          damage = damage / 2,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self:GetAbility()
        }

        ApplyDamage(damageTable)
      end
    end

    enemies = FindEnemiesInRadiusFromTeam(self.team, self.full_aoe, self:GetParent():GetAbsOrigin())

    for _,enemy in pairs(enemies) do
      if not IsCustomBuilding(enemy) then
        local damageTable = {
          victim = enemy,
          attacker = self.playerHero,
          damage = damage / 2,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self:GetAbility()
        }

        ApplyDamage(damageTable)
      end
    end
  end
end