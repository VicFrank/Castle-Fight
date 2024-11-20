bloodthirster_faerie_fire = class({})

LinkLuaModifier("modifier_bloodthirster_faerie_fire", "abilities/elf/faerie_fire", LUA_MODIFIER_MOTION_NONE)

function bloodthirster_faerie_fire:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("Hero_Slardar.Amplify_Damage")

  local duration = ability:GetSpecialValueFor("duration")

  corrosive_haze_modifier = target:AddNewModifier(caster, ability, "modifier_bloodthirster_faerie_fire", {duration = duration})

  Timers:CreateTimer(0.01, function()
    local particleName = "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf"
    particle_haze_fx = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, target)
    ParticleManager:SetParticleControl(particle_haze_fx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_haze_fx, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_haze_fx, 2, target:GetAbsOrigin())

    ParticleManager:SetParticleControlEnt(particle_haze_fx, 1, target, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle_haze_fx, 2, target, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    corrosive_haze_modifier:AddParticle(particle_haze_fx, false, true, -1, false, true)
  end)
end

modifier_bloodthirster_faerie_fire = class({})

function modifier_bloodthirster_faerie_fire:GetAbilityTextureName()
  return "slardar_amplify_damage"
end

function modifier_bloodthirster_faerie_fire:IsDebuff()
  return true
end

function modifier_bloodthirster_faerie_fire:IsPurgable()
  return true
end

function modifier_bloodthirster_faerie_fire:OnCreated()
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_bloodthirster_faerie_fire:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_bloodthirster_faerie_fire:GetModifierProvidesFOWVision()
  return 1
end

function modifier_bloodthirster_faerie_fire:CheckState()
  local state = {
    [MODIFIER_STATE_INVISIBLE] = false,
  }

  return state
end

function modifier_bloodthirster_faerie_fire:GetModifierPhysicalArmorBonus()
  return -self.armor
end