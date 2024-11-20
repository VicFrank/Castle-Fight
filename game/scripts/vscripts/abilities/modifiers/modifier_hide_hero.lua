modifier_hide_hero = class({})

function modifier_hide_hero:IsHidden() return true end

function modifier_hide_hero:OnCreated()
  if not IsServer() then return end

  self.parent = self:GetParent()
  self.parent:AddNoDraw()
end

function modifier_hide_hero:OnDestroy()
  if not IsServer() then return end
  
  if not self.parent:IsNull() and self.parent then
    self.parent:RemoveNoDraw()
  end
end

function modifier_hide_hero:CheckState()
  return { 
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true, 
    [MODIFIER_STATE_INVULNERABLE] = true, 
    [MODIFIER_STATE_NO_HEALTH_BAR] = true, 
    [MODIFIER_STATE_UNSELECTABLE] = true, 
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true, 
    [MODIFIER_STATE_UNSELECTABLE] = true, 
  }
end