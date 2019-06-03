function CDOTA_BaseNPC:GetLumber()
  if not self.lumber then
    print("Hero has not had lumber initialized, defaulting to 0")
    self.lumber = 0
  end
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
  self:SetLumber(self.lumber + value)
end