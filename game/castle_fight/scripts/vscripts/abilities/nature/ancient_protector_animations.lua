ancient_protector_animations = class({})

LinkLuaModifier("modifier_ancient_protector_animations", "abilities/nature/ancient_protector_animations", LUA_MODIFIER_MOTION_NONE)

function ancient_protector_animations:GetIntrinsicModifierName()
  return "modifier_ancient_protector_animations"
end

modifier_ancient_protector_animations = class({})

function modifier_ancient_protector_animations:IsHidden() return true end

function modifier_ancient_protector_animations:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_ancient_protector_animations:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ancient_protector_animations:GetOverrideAnimation()
  return ACT_DOTA_CUSTOM_TOWER_IDLE
end

function modifier_ancient_protector_animations:OnCreated()
  if not IsServer() then return end

  self.rotating = false
  self.target = nil

  local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(pfx)

  -- self:SetStackCount(self:GetCaster():GetTeamNumber())
end

function sign(value)
  if value < 0 then return -1 end
  if value > 0 then return 1 end
  return 0
end

TOWER_TARGET_TRACKING_INTERVAL = 1/30 --Somewhere in building helper, it's told server fps is 30

function modifier_ancient_protector_animations:ShouldEndTracking()
  if not self.target:IsAlive then
    self.target = nil
    print("Reached desired rotation, target died - end tracking")
    return
  end
  return TOWER_TARGET_TRACKING_INTERVAL
end

function modifier_ancient_protector_animations:TrackTarget()
  if not IsServer() then return end
  if not self.target then return end

  -- Keep tracking as long as we should and can, to try to finish movement so it looks natural
  if not IsValidEntity(self.target) then
    self.target = nil
    print("Target invalidated, couldn't finish tracking")
    return
  end

  local rotationSpeed = 360 / (1 / TOWER_TARGET_TRACKING_INTERVAL) -- Do a full flip per 1 second
  local angleTolerance = 0.25

  local parent = self:GetParent()

  local desiredForwardVector = self.target:GetAbsOrigin() - parent:GetAbsOrigin()
  local myForwardVector = parent:GetForwardVector()
  local desiredYaw = VectorToAngles(desiredForwardVector).y
  local myYaw = VectorToAngles(myForwardVector).y

  -- Find shortest path
  if math.abs(myYaw - (desiredYaw - 360)) < desiredYaw then
    desiredYaw = desiredYaw - 360
  elseif math.abs(myYaw - (desiredYaw + 360)) < desiredYaw then
    desiredYaw = desiredYaw + 360
  end

  print("Desired yaw is "..desiredYaw)
  print("My yaw is "..myYaw)
  print("Delta yaw is "..math.abs(myYaw - desiredYaw))

  if math.abs(myYaw - desiredYaw) <= angleTolerance then
    print("Delta fits tolerance, skip rotation update")
    return self:ShouldEndTracking()
  end

  local direction = (desiredYaw > myYaw) and 1 or -1
  local newYaw = myYaw + rotationSpeed * direction
  if sign(newYaw - desiredYaw) == direction then
    parent:SetAngles(0, desiredYaw, 0)
    return self:ShouldEndTracking()
  else
    parent:SetAngles(0, newYaw, 0)
    return TOWER_TARGET_TRACKING_INTERVAL
  end
end

function modifier_ancient_protector_animations:OnAttackStart(keys)
  if not IsServer() then return end

  if keys.attacker == self:GetParent() then
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_ATTACK, self:GetParent():GetAttacksPerSecond())

    -- If no track target, setup target and start tracking
    -- Else only update target
    if not self.target then
      self.target = keys.target
      print("Begin tracking")
      local nextUpdateTimer = self:TrackTarget()
      if nextUpdateTimer then
        Timers:CreateTimer(nextUpdateTimer, function ()
          return self:TrackTarget()
        end)
      end
    else
      self.target = keys.target
    end
  end
end

function modifier_ancient_protector_animations:OnDeath(keys)
  if not IsServer() then return end

  if keys.unit == self:GetParent() then
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_DIE, 0.75)
  end
end