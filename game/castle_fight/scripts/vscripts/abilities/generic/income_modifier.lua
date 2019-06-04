income_modifier = class({})
income_modifier_enemy = class({})

function income_modifier:GetTexture()
  return "alchemist_goblins_greed"
end

function income_modifier:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function income_modifier:OnCreated()
  if not IsServer() then return end

  self.parent = self:GetParent()
  self.team = self.parent:GetTeam()

  self:SetStackCount(GameMode:GetIncomeForTeam(self.team))

  self:StartIntervalThink(0.5)
end

function income_modifier:OnIntervalThink()
  if not IsServer() then return end

  self:SetStackCount(GameMode:GetIncomeForTeam(self.team))
end

-----------------------------

function income_modifier_enemy:IsDebuff() return true end

function income_modifier_enemy:GetTexture()
  return "alchemist_goblins_greed"
end

function income_modifier_enemy:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function income_modifier_enemy:OnCreated()
  if not IsServer() then return end

  self.parent = self:GetParent()
  self.team = self.parent:GetTeam()

  -- swap teams
  if self.team == DOTA_TEAM_GOODGUYS then self.team = DOTA_TEAM_BADGUYS
  else self.team = DOTA_TEAM_GOODGUYS end

  self:SetStackCount(GameMode:GetIncomeForTeam(self.team))

  self:StartIntervalThink(0.5)
end

function income_modifier_enemy:OnIntervalThink()
  if not IsServer() then return end

  self:SetStackCount(GameMode:GetIncomeForTeam(self.team))
end