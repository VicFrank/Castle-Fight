  avenging_spirit_heal_on_kill = class({})

  LinkLuaModifier("modifier_heal_on_kill", "abilities/night_elves/heal_on_kill.lua", LUA_MODIFIER_MOTION_NONE)

  function avenging_spirit_heal_on_kill:GetIntrinsicModifierName()
    return "modifier_heal_on_kill"
  end

  modifier_heal_on_kill = class({})

  function modifier_heal_on_kill:DeclareFunctions()
    local funcs = {
      MODIFIER_EVENT_ON_DEATH,
    }
    return funcs
  end

  function modifier_heal_on_kill:OnDeath(params)
    if not IsServer() then return end

    if params.attacker == self:GetParent() then
      local target = params.unit
      if target then
        local heal_pct = self:GetAbility():GetSpecialValueFor("heal_pct")

        local heal = target:GetMaxHealth() * heal_pct * 0.01

        if self:GetParent():IsAlive() then
          self:GetParent():Heal(heal, self:GetParent())
          SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal, nil)
        end
      end
    end
  end