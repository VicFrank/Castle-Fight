function CDOTA_BaseNPC:GetLumber()
  local nettable = CustomNetTables:GetTableValue("lumber", tostring(self:GetPlayerOwnerID()))
  return nettable.value
end

function CDOTA_BaseNPC:SetLumber(lumber)
  CustomNetTables:SetTableValue("lumber",
    tostring(self:GetPlayerOwnerID()),
    {value = lumber})
end

function CDOTA_BaseNPC:ModifyLumber(value)
  self:SetLumber(math.max(0, self:GetLumber() + value))
end

function CDOTA_BaseNPC:GiveLumber(value)
  self:SetLumber(self:GetLumber() + value)
end

function SetLumber(playerID, lumber)
  CustomNetTables:SetTableValue("lumber", tostring(playerID), {value = lumber})
end

-------------------------------------------

function CDOTA_BaseNPC:GetCheese()
  local nettable = CustomNetTables:GetTableValue("cheese", tostring(self:GetPlayerOwnerID()))
  return nettable.value
end

function CDOTA_BaseNPC:SetCheese(cheese)
  CustomNetTables:SetTableValue("cheese",
    tostring(self:GetPlayerOwnerID()),
    {value = cheese})
end

function CDOTA_BaseNPC:ModifyCheese(value)
  self:SetCheese(math.max(0, self:GetCheese() + value))
end

function SetCheese(playerID, cheese)
  CustomNetTables:SetTableValue("cheese", tostring(playerID), {value = cheese})
end