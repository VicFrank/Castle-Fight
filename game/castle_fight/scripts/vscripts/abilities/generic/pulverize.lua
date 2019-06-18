LinkLuaModifier("modifier_pulverize", "abilities/generic/pulverize.lua", LUA_MODIFIER_MOTION_NONE)

flesh_golem_pulverize = class({})
function flesh_golem_pulverize:GetIntrinsicModifierName() return "modifier_pulverize" end

modifier_pulverize = class({})

function modifier_pulverize:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
  self.close_range = self.ability:GetSpecialValueFor("close_range")
  self.close_damage = self.ability:GetSpecialValueFor("close_damage")
  self.far_range = self.ability:GetSpecialValueFor("far_range")
  self.far_damage = self.ability:GetSpecialValueFor("far_damage")
end

function modifier_pulverize:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_pulverize:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    if self.chance >= RandomInt(1,100) then
      self.caster:EmitSound("Hero_EarthShaker.Totem.Attack")

      local particleName = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock_v2.vpcf"
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:SetParticleControl(particle, 1, Vector(self.far_range, self.far_range, self.far_range))
      ParticleManager:ReleaseParticleIndex(particle)

      local enemies = FindEnemiesInRadius(target, self.far_range)

      for _,enemy in pairs(enemies) do
        local distance = (attacker:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
        local damage 

        if distance <= self.close_range then
          damage = self.close_damage
        else
          damage = self.far_damage
        end

        ApplyDamage({
          victim = enemy,
          attacker = attacker,
          damage = damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          ability = self.ability,
        })
      end
    end
  end
end

