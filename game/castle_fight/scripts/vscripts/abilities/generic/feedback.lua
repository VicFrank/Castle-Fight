LinkLuaModifier("modifier_feedback_custom", "abilities/generic/feedback.lua", LUA_MODIFIER_MOTION_NONE)

murloc_feedback = class({})
function murloc_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
elunes_lantern_feedback = class({})
function elunes_lantern_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
faerie_dragon_feedback = class({})
function faerie_dragon_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
assassin_feedback = class({})
function assassin_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
blademaster_feedback = class({})
function blademaster_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end

modifier_feedback_custom = class({})

function modifier_feedback_custom:IsHidden() return true end

function modifier_feedback_custom:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.mana_burn = self.ability:GetSpecialValueFor("mana_burn")
  self.mana_to_damage = self.ability:GetSpecialValueFor("mana_to_damage")
end

function modifier_feedback_custom:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_feedback_custom:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if target:GetMaxMana() == 0 or target:IsMagicImmune() or IsCustomBuilding(target) then
    return
  end

  if attacker == self.caster then
    -- do mana burn here
      target:EmitSound("Hero_Antimage.ManaBreak")

      local particleName = "particles/generic_gameplay/generic_manaburn.vpcf"
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
      ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(particle)

      local manaToBurn = math.min(self.mana_burn, target:GetMana())

      target:ReduceMana(manaToBurn)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, target, manaToBurn, nil)

      local damageTable = {
        victim = target,
        damage = manaToBurn * self.mana_to_damage * 0.01,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = attacker,
        ability = self.ability
      }

      ApplyDamage(damageTable)
  end
end

