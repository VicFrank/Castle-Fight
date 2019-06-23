function GameMode:SetupShopForTeam(team)
  local shopItems = {
    "item_blast_staff",
    "item_rune_of_repair",
    "item_scroll_of_stone",
    "item_orb_of_lightning",
    "item_bassline",
    "item_drums",
    "item_double_damage",
    "item_quad_damage",
    "item_custom_cheese",
  }

  for i=1,#shopItems do
    local itemname = shopItems[i]
    local item = CreateItem(itemname, nil, nil)

    local goldCost = tonumber(item:GetAbilityKeyValues()['ItemCost']) or 0
    local lumberCost = tonumber(item:GetAbilityKeyValues()['LumberCost']) or 0
    local initialStock = tonumber(item:GetAbilityKeyValues()['InitialStock']) or 0
    local restockTime = tonumber(item:GetAbilityKeyValues()['RestockTime']) or 0

    item:RemoveSelf()

    local shopKey = GetShopItemKey(itemname, team)

    CustomNetTables:SetTableValue("custom_shop",
    shopKey,
    {
      team = team,
      itemname = itemname,
      gold_cost = goldCost,
      lumber_cost = lumberCost,
      stock = initialStock,
      restock_time = restockTime,
      purchase_time = nil,
    })
  end
end

function GetShopItemKey(itemname, team)
  return itemname .. team
end

function OnAttemptPurchase(eventSourceIndex, args)
  local playerID = args.PlayerID
  local itemname = args.itemname

  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local team = hero:GetTeam()
  local shopKey = GetShopItemKey(itemname, team)

  local itemData = CustomNetTables:GetTableValue("custom_shop", shopKey)

  local gold_cost = itemData.gold_cost
  local lumber_cost = itemData.lumber_cost

  if GameRules:IsGamePaused() then
    SendErrorMessage(playerID, "#error_game_paused")
    return false
  end

  -- Make sure we have enough resources to buy this item
  if hero:GetGold() < gold_cost then
    SendErrorMessage(playerID, "#error_not_enough_gold")
    return false
  end

  if hero:GetLumber() < lumber_cost then
    SendErrorMessage(playerID, "#error_not_enough_lumber")
    return false
  end

  -- Make sure the item is in stock
  local stock = itemData.stock

  if stock <= 0 then
    SendErrorMessage(playerID, "#error_out_of_stock")
    return false
  end

  -- Make the payment
  hero:ModifyGold(-gold_cost, false, 0)
  hero:ModifyLumber(-lumber_cost)

  -- Successful purchase
  -- Update Stock info
  local purchase_time = GameRules:GetGameTime()
  local restock_time = itemData.restock_time
  local currentRound = GameRules.roundCount

  CustomNetTables:SetTableValue("custom_shop",
    shopKey,
    {
      team = team,
      itemname = itemname,
      gold_cost = gold_cost,
      lumber_cost = lumber_cost,
      stock = stock - 1,
      restock_time = restock_time,
      purchase_time = purchase_time,
    })

  -- Restock after restock_time has passed
  if (restock_time > 0) then
    Timers:CreateTimer(restock_time, function()
      -- Only restock if it's still the same round
      if currentRound == GameRules.roundCount then
        local currentItemData = CustomNetTables:GetTableValue("custom_shop", shopKey)

        CustomNetTables:SetTableValue("custom_shop",
        shopKey,
        {
          team = currentItemData.team,
          itemname = currentItemData.itemname,
          gold_cost = currentItemData.gold_cost,
          lumber_cost = currentItemData.lumber_cost,
          stock = currentItemData.stock + 1,
          restock_time = currentItemData.restock_time,
          purchase_time = nil,
        })
      end
    end)
  end

  -- Play success sound
  EmitSoundOnClient("General.Buy", hero:GetPlayerOwner())

  -- Give the hero the item
  hero:AddItemByName(itemname)
end