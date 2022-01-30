// Navigating through the ai to get panels to insert lumber costs into
var HUD = $.GetContextPanel().GetParent().GetParent().GetParent();
var newUI = HUD.FindChildTraverse("HUDElements")
  .FindChildTraverse("lower_hud")
  .FindChildTraverse("center_with_stats")
  .FindChildTraverse("center_block");

var inventoryContainer = newUI
  .FindChildTraverse("inventory")
  .FindChildTraverse("inventory_items")
  .FindChildTraverse("inventory_list_container");

var inventoryTop = inventoryContainer.FindChildTraverse("inventory_list");
var inventoryBot = inventoryContainer.FindChildTraverse("inventory_list2");

function test() {
  GameUI.PingMinimapAtLocation([1, 0, 128]);
}

function SetCustomItemCosts(itemSlot, lumberCost, cheeseCost, goldCost) {
  var subContainer;
  if (itemSlot < 3) subContainer = inventoryTop;
  else subContainer = inventoryBot;

  var slotContainer = subContainer.FindChildTraverse("inventory_slot_" + itemSlot);
  var button = slotContainer
    .FindChildTraverse("ButtonAndLevel")
    .FindChildTraverse("ButtonWithLevelUpTab")
    .FindChildTraverse("ButtonWell")
    .FindChildTraverse("ButtonSize");

  if (lumberCost == 0) lumberCost = "";
  if (cheeseCost == 0) cheeseCost = "";
  if (goldCost == 0) goldCost = "";

  if (button.FindChildTraverse("LumberCost")) {
    button.FindChildTraverse("LumberCost").text = lumberCost;
  } else {
    var LumberCostLabel = $.CreatePanel("Label", button, "LumberCost");
    LumberCostLabel.text = lumberCost;
    LumberCostLabel.style.fontSize = "14px";
    LumberCostLabel.style.verticalAlign = "bottom";
    LumberCostLabel.style.horizontalAlign = "right";
    LumberCostLabel.style.fontWeight = "bold";
    LumberCostLabel.style.color = "#22a543";
    LumberCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }

  if (button.FindChildTraverse("CustomGoldCost")) {
    button.FindChildTraverse("CustomGoldCost").text = goldCost;
  } else {
    var goldCostLabel = $.CreatePanel("Label", button, "CustomGoldCost");
    goldCostLabel.text = goldCost;
    goldCostLabel.style.fontSize = "14px";
    goldCostLabel.style.verticalAlign = "bottom";
    goldCostLabel.style.horizontalAlign = "left";
    goldCostLabel.style.fontWeight = "bold";
    goldCostLabel.style.color = "#FFFF99";
    goldCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }

  if (button.FindChildTraverse("CheeseCost")) {
    button.FindChildTraverse("CheeseCost").text = cheeseCost;
  } else {
    var CheeseCostLabel = $.CreatePanel("Label", button, "CheeseCost");
    CheeseCostLabel.text = cheeseCost;
    CheeseCostLabel.style.fontSize = "16px";
    CheeseCostLabel.style.verticalAlign = "top";
    CheeseCostLabel.style.horizontalAlign = "right";
    CheeseCostLabel.style.marginRight = "2px";
    CheeseCostLabel.style.fontWeight = "bold";
    CheeseCostLabel.style.color = "#7f22a5";
    CheeseCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }
}

function UpdateItemsUI() {
  var i;
  for (i = 0; i < 6; i++) {
    var queryUnit = Players.GetLocalPlayerPortraitUnit();
    var item = Entities.GetItemInSlot(queryUnit, i);

    var itemname = Abilities.GetAbilityName(item);

    var itemCostData = CustomNetTables.GetTableValue("ability_costs", itemname);
    if (!itemCostData) {
      SetCustomItemCosts(i, "", "", "");
      continue;
    }

    var lumberCost = itemCostData.lumberCost;
    var goldCost = itemCostData.goldCost;
    var isLegendary = itemCostData.isLegendary;

    var cheeseCost = 0;
    if (isLegendary) cheeseCost = 1;

    SetCustomItemCosts(i, lumberCost, cheeseCost, goldCost);
  }
}

var AbilitiesContainer = newUI
  .FindChildTraverse("AbilitiesAndStatBranch")
  .FindChildTraverse("abilities");

function SetCustomAbilityCosts(abilityNumber, lumberCost, cheeseCost, goldCost) {
  var AbilityPanel = AbilitiesContainer.FindChildTraverse("Ability" + abilityNumber);
  if (!AbilityPanel) return;
  var AbilityButton = AbilityPanel.FindChildTraverse("ButtonAndLevel")
    .FindChildTraverse("ButtonWithLevelUpTab")
    .FindChildTraverse("ButtonWell")
    .FindChildTraverse("ButtonSize");

  if (lumberCost == 0) lumberCost = "";
  if (cheeseCost == 0) cheeseCost = "";
  if (goldCost == 0) goldCost = "";

  if (AbilityButton.FindChildTraverse("LumberCost")) {
    AbilityButton.FindChildTraverse("LumberCost").text = lumberCost;
  } else {
    var lumberCostLabel = $.CreatePanel("Label", AbilityButton, "LumberCost");
    lumberCostLabel.text = lumberCost;
    lumberCostLabel.style.fontSize = "14px";
    lumberCostLabel.style.verticalAlign = "bottom";
    lumberCostLabel.style.horizontalAlign = "right";
    lumberCostLabel.style.fontWeight = "bold";
    lumberCostLabel.style.color = "#22a543";
    lumberCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }

  if (AbilityButton.FindChildTraverse("CustomGoldCost")) {
    AbilityButton.FindChildTraverse("CustomGoldCost").text = goldCost;
  } else {
    var goldCostLabel = $.CreatePanel("Label", AbilityButton, "CustomGoldCost");
    goldCostLabel.text = goldCost;
    goldCostLabel.style.fontSize = "14px";
    goldCostLabel.style.verticalAlign = "bottom";
    goldCostLabel.style.horizontalAlign = "left";
    goldCostLabel.style.fontWeight = "bold";
    goldCostLabel.style.color = "#FFFF99";
    goldCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }

  if (AbilityButton.FindChildTraverse("CheeseCost")) {
    AbilityButton.FindChildTraverse("CheeseCost").text = cheeseCost;
  } else {
    var cheeseCostLabel = $.CreatePanel("Label", AbilityButton, "CheeseCost");
    cheeseCostLabel.text = cheeseCost;
    cheeseCostLabel.style.fontSize = "16px";
    cheeseCostLabel.style.verticalAlign = "top";
    cheeseCostLabel.style.horizontalAlign = "right";
    cheeseCostLabel.style.marginRight = "8px";
    cheeseCostLabel.style.fontWeight = "bold";
    cheeseCostLabel.style.color = "#7f22a5";
    cheeseCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";
  }
}

function DelayedUpdateAbilityUI() {
  $.Schedule(1, UpdateAbilityUI);
}

function UpdateAbilityUI() {
  var queryUnit = Players.GetLocalPlayerPortraitUnit();

  for (var i = 0; i < Entities.GetAbilityCount(queryUnit); ++i) {
    var ability = Entities.GetAbility(queryUnit, i);
    if (ability == -1) continue;

    if (!Abilities.IsDisplayedAbility(ability)) continue;

    var abilityname = Abilities.GetAbilityName(ability);

    var abilityCostData = CustomNetTables.GetTableValue("ability_costs", abilityname);
    if (!abilityCostData) {
      SetCustomAbilityCosts(i, "", "", "");
      continue;
    }

    var lumberCost = abilityCostData.lumberCost;
    var goldCost = abilityCostData.goldCost;
    var isLegendary = abilityCostData.isLegendary;

    var cheeseCost = 0;
    if (isLegendary) cheeseCost = 1;

    SetCustomAbilityCosts(i, lumberCost, cheeseCost, goldCost);
  }
}

var IsSpectator = !Players.IsValidPlayerID(Players.GetLocalPlayer());

var LocalPlayerID = Players.GetLocalPlayer();
var LocalPlayerTeam = Players.GetTeam(LocalPlayerID);

var DefaultPlayerID = 0;
if (!IsSpectator) DefaultPlayerID = LocalPlayerID;

function GetPlayerIDToShow() {
  var queryUnit = Players.GetLocalPlayerPortraitUnit();
  var queryUnitTeam = Entities.GetTeamNumber(queryUnit);
  var queryUnitPlayerOwnerID = Entities.GetPlayerOwnerID(queryUnit);
  if (queryUnitPlayerOwnerID >= 0 && queryUnitTeam === LocalPlayerTeam)
    return queryUnitPlayerOwnerID;
  else if (IsSpectator && queryUnitPlayerOwnerID >= 0) return queryUnitPlayerOwnerID;
  else return DefaultPlayerID;
}

function UpdateResources() {
  var playerID = GetPlayerIDToShow();
  var data = CustomNetTables.GetTableValue("resources", playerID);

  if (data) {
    $("#GoldText").text = Math.floor(data.gold);
    $("#CheeseText").text = Math.floor(data.cheese);
    $("#LumberText").text = Math.floor(data.lumber);
  }
}

function OnResourcesChange(table_name, key, data) {
  // if(key == Players.GetLocalPlayer()) {
  //   $('#GoldText').text = Math.floor(data.gold);
  //   $('#LumberText').text = data.lumber;
  //   $('#CheeseText').text = data.cheese;
  // }
  UpdateResources();
}

// function UpdateGold() {
//   var playerID = GetPlayerIDToShow();
//   var gold = Players.GetGold(playerID);
//   $('#GoldText').text = gold;
//   $.Schedule(0.1, UpdateGold);
// }

// this logic is also in income.lua
function CalculateTreasureBoxMultiplier(numBoxes) {
  var baseRate = 0.25;
  var reduction = 0.15;

  var reducedRate = baseRate;
  var sum = 0;

  var i;
  for (i = 0; i < numBoxes; i++) {
    sum = sum + reducedRate;
    reducedRate = reducedRate - reducedRate * reduction;
  }

  return sum;
}

function GetPostTaxIncome(income) {
  var sum = 0;
  var multiplier = 0;

  while (income > 0) {
    income = income - 25;
    var increase = 25;
    if (income < 0) increase = income + 25;
    sum = sum + increase - increase * multiplier;
    multiplier = Math.min(0.8, multiplier + 0.1);
  }

  return sum;
}

function GenerateGoldTooltip() {
  var playerID = GetPlayerIDToShow();
  var incomeData = CustomNetTables.GetTableValue("player_income", playerID);

  var line1 = $.Localize("#gold_tip");

  if (!incomeData) {
    return line1;
  }

  var baseInterest = 5;
  var buildingInterest = incomeData.income - 5;
  var numBoxes = incomeData.numBoxes;
  var treasureChestMultiplier = CalculateTreasureBoxMultiplier(numBoxes);
  var income = incomeData.income + incomeData.income * treasureChestMultiplier;
  var totalInterest = GetPostTaxIncome(income);
  var taxes = income - totalInterest;

  var line2 =
    $.Localize("#base_interest") +
    ": <font color='#FFBF00'>" +
    Math.floor(baseInterest) +
    "</font>";
  var line3 =
    $.Localize("#interest_from_buildings") +
    ": <font color='#FFBF00'>" +
    Math.floor(buildingInterest) +
    "</font>";
  var line4 =
    $.Localize("#treasure_chest_multiplier") +
    ": <font color='#00C400'>" +
    Math.floor(treasureChestMultiplier * 100) +
    "%</font>";
  var line5 = $.Localize("#taxes") + ": <font color='#C40000'>" + Math.floor(taxes) + "</font>";
  var line6 =
    $.Localize("#total_interest") +
    ": <font color='#FFBF00'>" +
    Math.floor(totalInterest) +
    "</font>";

  return (
    line1 + "<br><br>" + line2 + "<br>" + line3 + "<br>" + line4 + "<br>" + line5 + "<br>" + line6
  );
}

// Set up the text for the gold panel
$("#GoldLabelPanel").SetPanelEvent("onmouseover", function () {
  $.DispatchEvent("DOTAShowTextTooltip", $("#GoldLabelPanel"), GenerateGoldTooltip());
});

(function () {
  UpdateResources();
  CustomNetTables.SubscribeNetTableListener("resources", OnResourcesChange);

  UpdateItemsUI();
  GameEvents.Subscribe("dota_player_update_selected_unit", UpdateItemsUI);
  GameEvents.Subscribe("dota_player_update_query_unit", UpdateItemsUI);
  GameEvents.Subscribe("dota_inventory_changed", UpdateItemsUI);

  GameEvents.Subscribe("dota_player_update_query_unit", UpdateResources);
  GameEvents.Subscribe("dota_player_update_selected_unit", UpdateResources);

  DelayedUpdateAbilityUI();
  UpdateAbilityUI();
  GameEvents.Subscribe("dota_player_update_selected_unit", UpdateAbilityUI);
  GameEvents.Subscribe("dota_player_update_query_unit", UpdateAbilityUI);
  GameEvents.Subscribe("round_started", UpdateAbilityUI);
})();
