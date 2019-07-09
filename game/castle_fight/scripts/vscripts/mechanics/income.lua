function GameMode:PayIncome()
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    if hero:IsAlive() then
      local playerID = hero:GetPlayerOwnerID()
      local income = GameMode:GetIncomeForPlayer(playerID)

      -- hero:ModifyGold(income, false, DOTA_ModifyGold_Unspecified)
      hero:ModifyCustomGold(income)
      SendOverheadEventMessage(hero, OVERHEAD_ALERT_GOLD, hero, income, hero)

      hero:AddNewModifier(hero, nil, "income_modifier", {duration=10})
    end
  end
end

function GameMode:GetIncomeIncreaseForBuilding(building, cost)
  local playerID = building:GetPlayerOwnerID()
  local buildingType = building:GetBuildingType()
  local multiplier

  if buildingType == "UnitTrainer" then
    multiplier = 0.020
  elseif buildingType == "SiegeTrainer" then
    multiplier = 0.018
  elseif buildingType == "Tower" then
    multiplier = 0.008
  elseif buildingType == "Support" then
    multiplier = 0.012
  elseif buildingType == "Killing" then
    multiplier = 0.009
  else
    print(building:GetUnitName() .. " does not have a BuildingType")
  end

  local increase = cost * multiplier

  return increase
end

-- Profit from Treasure Boxes give 1.2% income from its value
-- (350 at the moment). In addition, the treasury increases the total
-- profit by a certain% (the first Box is 25% , each subsequent 15% less).
-- In this way:

-- 1 TB: + 25% 
-- 2 TB: + 46% 
-- 3 TB: + 64% 
-- 4 TB: + 79% 
-- 5 TB: + 92%
function GameMode:CalculateTreasureBoxMultiplier(numBoxes)
  local baseRate = 0.25
  local reduction = 0.15

  local reducedRate = baseRate
  local sum = 0

  for i=1,numBoxes do
    sum = sum + reducedRate
    reducedRate = reducedRate - reducedRate * reduction
  end

  return sum
end

-- The system of taxes in Castle-Fight is progressive, the tax increases 
-- by 10% for every 25 gold. For the first 25 gold, the tax is not deducted,
-- 10% tax is deducted from the next 25 gold profits , 20% tax is deducted 
-- from income 50-75 , etc. before tax at 80% . After a profit value of 200, 
-- the tax becomes permanent and is set at 80% .

--   Example:
--     Your profit (with Treasure Boxes, but without taxes) is 75 gold. 
--     25 gold is given without tax; 
--     25 gold - 10% = 22.5 gold; 
--     25 gold - 20% = 20 gold; 
--     As a result: 67.5 gold
function GameMode:GetPostTaxIncome(income)
  -- I wrote this when I was tired, but it works
  local sum = 0
  local multiplier = 0

  while income > 0 do
    income = income - 25
    local increase = 25
    if income < 0 then
      increase = income + 25
    end
    sum = sum + increase - (increase * multiplier)
    multiplier = math.min(0.8, multiplier + .1)
  end

  return sum
end

function GameMode:GetIncomeForPlayer(playerID)
  local baseIncome = GameMode:GetIncome(playerID)
  local numBoxes = GameMode:GetNumBoxes(playerID)

  local treasureBoxMultiplier = GameMode:CalculateTreasureBoxMultiplier(numBoxes)
  local income = baseIncome + baseIncome * treasureBoxMultiplier

  return GameMode:GetPostTaxIncome(income)
end

--------------
-- Income here refers to base income, before box multipliers and tax
function GameMode:ResetIncome()
  GameRules.income = {}
  GameRules.numBoxes = {}

  for _,playerID in pairs(GameRules.playerIDs) do
    GameMode:SetIncome(playerID, STARTING_INCOME)
    GameMode:SetNumBoxes(playerID, 0)
  end
end

function GameMode:SetIncome(playerID, value)
  GameRules.income[playerID] = value
  CustomNetTables:SetTableValue("player_income", tostring(playerID),
    {
      income = value,
      numBoxes = GameMode:GetNumBoxes(playerID)
    })
end

function GameMode:GetIncome(playerID)
  if not GameRules.income[playerID] then
    GameRules.income[playerID] = 0
  end
  return GameRules.income[playerID]
end

function GameMode:ModifyIncome(playerID, value)
  GameMode:SetIncome(playerID, GameMode:GetIncome(playerID) + value)
end

--------------

function GameMode:SetNumBoxes(playerID, value)
  GameRules.numBoxes[playerID] = value
  CustomNetTables:SetTableValue("player_income", tostring(playerID),
    {
      income = GameMode:GetIncome(playerID),
      numBoxes = value
    })
end

function GameMode:GetNumBoxes(playerID)
  if not GameRules.numBoxes[playerID] then
    GameRules.numBoxes[playerID] = 0
  end
  return GameRules.numBoxes[playerID]
end

function GameMode:ModifyNumBoxes(playerID, value)
  GameMode:SetNumBoxes(playerID, GameMode:GetNumBoxes(playerID) + value)
end