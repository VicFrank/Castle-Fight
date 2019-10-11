assassin_backstab = class({})
LinkLuaModifier("modifier_assassin_backstab", "abilities/night_elves/backstab", LUA_MODIFIER_MOTION_NONE)

function assassin_backstab:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  caster:EmitSound("Hero_BountyHunter.WindWalk")

  local particle_smoke = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf"
  local particle_invis_start = "particles/generic_hero_status/status_invisibility_start.vpcf"
  
  local particle_smoke_fx = ParticleManager:CreateParticle(particle_smoke, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle_smoke_fx, 0, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle_smoke_fx)

  local particle_invis_start_fx = ParticleManager:CreateParticle(particle_invis_start, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle_invis_start_fx, 0, caster:GetAbsOrigin())

  caster:AddNewModifier(caster, ability, "modifier_assassin_backstab", {})
end

modifier_assassin_backstab = class({})

function modifier_assassin_backstab:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage = self.ability:GetSpecialValueFor("damage")
end

function modifier_assassin_backstab:CheckState()
  local state = {
    [MODIFIER_STATE_INVISIBLE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true
  }
  return state
end

function modifier_assassin_backstab:GetPriority()
  return MODIFIER_PRIORITY_NORMAL
end

function modifier_assassin_backstab:DeclareFunctions()
  local decFuncs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }

  return decFuncs
end

function modifier_assassin_backstab:GetModifierInvisibilityLevel()
  return 1
end

function modifier_assassin_backstab:GetModifierMoveSpeedBonus_Percentage()
  return 40
end

function modifier_assassin_backstab:OnAttackLanded(keys)
  if IsServer() then
    -- key properties
    local attacker = keys.attacker
    local target = keys.target

    -- Only apply on the caster attacking
    if self.caster == attacker then

      if not IsCustomBuilding(target) then
        self.caster:EmitSound("Hero_BountyHunter.Jinada")

        -- Deal bonus damage
        local damageTable = {
          victim = target,
          damage = self.damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          attacker = self.caster,
          ability = self.ability
        }

        ApplyDamage(damageTable)

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, self.damage, nil)
      end

      -- Remove invisibility
      self:Destroy()
    end
  end
end

function modifier_assassin_backstab:IsPurgable()
  return false
end