function CDOTA_BaseNPC:GetLumber()
  if not self.lumber then self.lumber = 0 end
  return self.lumber
end

function CDOTA_BaseNPC:SetLumber(lumber)
  self.lumber = lumber
  CustomNetTables:SetTableValue(
    "lumber",
    tostring(self:GetPlayerOwnerID()),
    {value = self.lumber})
end

function CDOTA_BaseNPC:ModifyLumber(value)
  self:SetLumber(math.max(0, self.lumber + value))
end

function CDOTA_BaseNPC:GiveLumber(value)
  if not self.lumber then self.lumber = 0 end
  self:SetLumber(self.lumber + value)
end

function CDOTA_BaseNPC:SetCheese(cheese)
  self.cheese = cheese
  CustomNetTables:SetTableValue(
    "cheese",
    tostring(self:GetPlayerOwnerID()),
    {value = self.cheese})
end