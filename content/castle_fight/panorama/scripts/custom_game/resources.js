// // let's try to insert lumber / cheese costs into the ui
var HUD = $.GetContextPanel().GetParent().GetParent().GetParent();
var newUI = HUD.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block");

var inventoryContainer = newUI.FindChildTraverse("inventory").FindChildTraverse("inventory_items").FindChildTraverse("inventory_list_container");

var inventoryTop = inventoryContainer.FindChildTraverse("inventory_list");
var inventoryBot = inventoryContainer.FindChildTraverse("inventory_list2");

var GeneratedItemPanels = [];

function SetCustomItemCosts(itemSlot, lumberCost, cheeseCost){
  var subContainer;
  if (i < 3) subContainer = inventoryTop;
  else subContainer = inventoryBot;

  var slotContainer = subContainer.FindChildTraverse("inventory_slot_" + i);
  var button = slotContainer.FindChildTraverse("ButtonAndLevel").FindChildTraverse("ButtonWithLevelUpTab").FindChildTraverse("ButtonWell").FindChildTraverse("ButtonSize");

  var LumberCostLabel = $.CreatePanel("Label", button, "LumberCost");
  LumberCostLabel.text = lumberCost;
  LumberCostLabel.style.fontSize = "14px";
  LumberCostLabel.style.verticalAlign = "bottom";
  LumberCostLabel.style.horizontalAlign = "right";
  LumberCostLabel.style.fontWeight = "bold";
  LumberCostLabel.style.color = "#22a543";
  LumberCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";

  GeneratedItemPanels.push(LumberCostLabel);

  if (cheeseCost > 0) {
    var CheeseCostLabel = $.CreatePanel("Label", button, "CheeseCost");
    CheeseCostLabel.text = cheeseCost;
    CheeseCostLabel.style.fontSize = "16px";
    CheeseCostLabel.style.verticalAlign = "top";
    CheeseCostLabel.style.horizontalAlign = "right";
    CheeseCostLabel.style.marginRight = "2px";
    CheeseCostLabel.style.fontWeight = "bold";
    CheeseCostLabel.style.color = "#7f22a5";
    CheeseCostLabel.style.textShadow = "0px 0px 3px 3.0 #000000";

    GeneratedItemPanels.push(CheeseCostLabel);
  }
}

function ClearCustomItemCosts() {
   GeneratedItemPanels.forEach(function(panel) {
     panel.text = '';
     // I don't think this actually works, but making the text '' seems to.
     panel.RemoveAndDeleteChildren();
   });

   GeneratedItemPanels = [];
}

function UpdateItemsUI() {
  ClearCustomItemCosts();

  for(i=0;i<6;i++){
    var queryUnit = Players.GetLocalPlayerPortraitUnit();
    var item = Entities.GetItemInSlot(queryUnit, i);    

    var itemname = Abilities.GetAbilityName(item);

    var itemCostData = CustomNetTables.GetTableValue("item_costs", itemname);
    if (!itemCostData) continue;

    var lumberCost = itemCostData.lumberCost;
    var isLegendary = itemCostData.isLegendary;

    var cheeseCost = 0;
    if (isLegendary) cheeseCost = 1;

    SetCustomItemCosts(i, lumberCost, cheeseCost)
  }
}

function OnPlayerLumberChanged(table_name, key, data) {
  UpdateLumber();
}

function UpdateLumber() {
  var playerID = Players.GetLocalPlayer();
  var data = CustomNetTables.GetTableValue("lumber", playerID);
  if (data && data.value) $('#LumberText').text = data.value;
}

function UpdateGold() {
  var playerID = Players.GetLocalPlayer();
  var gold = Players.GetGold(playerID);
  $('#GoldText').text = gold;
  $.Schedule(0.1, UpdateGold);
}

function OnPlayerCheeseChanged(table_name, key, data) {
  if(key == Players.GetLocalPlayer())
    $('#CheeseText').text = data.value;
}

function UpdateCheese() {
  var playerID = Players.GetLocalPlayer();
  var data = CustomNetTables.GetTableValue("cheese", playerID);
  if (data && data.value) $('#CheeseText').text = data.value;
}

(function () {
  UpdateGold();
  UpdateLumber();
  UpdateCheese();
  CustomNetTables.SubscribeNetTableListener("lumber", OnPlayerLumberChanged);
  CustomNetTables.SubscribeNetTableListener("cheese", OnPlayerCheeseChanged);

  UpdateItemsUI();
  GameEvents.Subscribe("dota_player_update_selected_unit", UpdateItemsUI);
  GameEvents.Subscribe("dota_player_update_query_unit", UpdateItemsUI);
  GameEvents.Subscribe("dota_inventory_changed", UpdateItemsUI);
})();