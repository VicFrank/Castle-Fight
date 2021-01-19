mountain_giant_cosmetics = class({})

LinkLuaModifier("modifier_mountain_giant_cosmetics", "abilities/nature/mountain_giant_cosmetics", LUA_MODIFIER_MOTION_NONE)

function mountain_giant_cosmetics:GetIntrinsicModifierName()
  return "modifier_mountain_giant_cosmetics"
end

modifier_mountain_giant_cosmetics = class({})

function modifier_mountain_giant_cosmetics:IsHidden() return true end

function modifier_mountain_giant_cosmetics:OnCreated()
  if not IsServer() then return end

  -- self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_head.vmdl"})
  -- self.rarm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_right_arm.vmdl"})
  -- self.larm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_left_arm.vmdl"})
  -- self.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_body.vmdl"})
  -- lock to bone
  -- self.head:FollowEntity(self:GetCaster(), true)
  -- self.rarm:FollowEntity(self:GetCaster(), true)
  -- self.larm:FollowEntity(self:GetCaster(), true)
  -- self.body:FollowEntity(self:GetCaster(), true)
end