furbolg_mana_burn = class({})
LinkLuaModifier("modifier_furbolg_mana_burn", "abilities/nature/mana_burn.lua", LUA_MODIFIER_MOTION_NONE)

function furbolg_mana_burn:GetIntrinsicModifierName() return modifier_furbolg_mana_burn end

modifier_furbolg_mana_burn = class({})

function modifier_furbolg_mana_burn:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_furbolg_mana_burn:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  local caster = self:GetCaster()
  local ability = self:GetAbility()

  local chance = self:GetAbility():GetSpecialValueFor("chance")

  if attacker == self:GetParent() and not IsCustomBuilding(target) and target:GetMana() > 0 then
    if chance >= RandomInt(1,100) then
      local mana_burn = ability:GetSpecialValueFor("mana_burn")

      target:EmitSound("Hero_NyxAssassin.ManaBurn.Cast")

      local particleName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf"
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT, caster)
      ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
      ParticleManager:ReleaseParticleIndex(particle)

      local FX = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn_start.vpcf", PATTACH_POINT_FOLLOW, caster)
      ParticleManager:SetParticleControlEnt(FX, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true)
      ParticleManager:ReleaseParticleIndex(FX)

      local manaToBurn = math.min(mana_burn, target:GetMana())
      target:ReduceMana(manaToBurn)

      ApplyDamage({
        victim = target,
        damage = manaToBurn,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })
    end
  end
end
