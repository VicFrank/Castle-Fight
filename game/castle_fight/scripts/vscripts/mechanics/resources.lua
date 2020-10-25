function CDOTA_BaseNPC:GetLumber()
  -- local nettable = CustomNetTables:GetTableValue("lumber", tostring(self:GetPlayerOwnerID()))
  -- return nettable.value
  if not self.lumber then
    self.lumber = 0
  end
  return self.lumber
end

function CDOTA_BaseNPC:SetLumber(lumber)
  local playerID = self:GetPlayerOwnerID()
  SetLumber(self:GetPlayerOwnerID(), lumber)
  UpdateNetTable(playerID)
end

function CDOTA_BaseNPC:ModifyLumber(value)
  self:SetLumber(math.max(0, self:GetLumber() + value))
end

function CDOTA_BaseNPC:GiveLumber(value)
  self:SetLumber(self:GetLumber() + value)
end

function SetLumber(playerID, lumber)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return end
  hero.lumber = lumber
  UpdateNetTable(playerID)
end

function GetLumber(playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return 0 end
  if not hero.lumber then
    hero.lumber = 0
  end
  return hero.lumber
end

-------------------------------------------

function CDOTA_BaseNPC:GetCheese()
  -- local nettable = CustomNetTables:GetTableValue("cheese", tostring(self:GetPlayerOwnerID()))
  -- return nettable.value
  if not self.cheese then
    self.cheese = 0
  end
  return self.cheese
end

function CDOTA_BaseNPC:SetCheese(cheese)
  local playerID = self:GetPlayerOwnerID()
  SetCheese(self:GetPlayerOwnerID(), cheese)
  UpdateNetTable(playerID)
end

function CDOTA_BaseNPC:ModifyCheese(value)
  self:SetCheese(self:GetCheese() + value)
end

function ModifyCheese(playerID, cheese)
  SetCheese(playerID, GetCheese(playerID) + cheese)
end

function SetCheese(playerID, cheese)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return end
  hero.cheese = cheese
  UpdateNetTable(playerID)
end

function GetCheese(playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return end
  if not hero.cheese then
    hero.cheese = 0
  end
  return hero.cheese
end

-------------------------------------------

function CDOTA_BaseNPC:GetCustomGold()
  local playerID = self:GetPlayerOwnerID()
  return GetCustomGold(playerID)
end

function CDOTA_BaseNPC:SetCustomGold(gold)
  SetCustomGold(self:GetPlayerOwnerID(), gold)
end

function CDOTA_BaseNPC:ModifyCustomGold(value)
  self:SetCustomGold(math.max(0, self:GetCustomGold() + value))
end

function GetCustomGold(playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return 0 end
  if not hero.gold then
    hero.gold = 0
  end
  return hero.gold
end

function SetCustomGold(playerID, gold)
  -- update their real gold, for spectators
  PlayerResource:SetGold(playerID, gold, false)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  if not hero then return end
  hero.gold = gold
  UpdateNetTable(playerID)
end

function ModifyCustomGold(playerID, value)
  SetCustomGold(playerID, math.max(0, GetCustomGold(playerID) + value))
end

function UpdateNetTable(playerID)
  CustomNetTables:SetTableValue("resources", tostring(playerID), {
    gold = GetCustomGold(playerID),
    lumber = GetLumber(playerID),
    cheese = GetCheese(playerID),
  })
end