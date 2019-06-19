function OnShopButtonPressed() {
  Game.EmitSound("ui_chat_slide_out")
  $("#Items").ToggleClass("ShopVisible");
}

var items = [
  "item_scroll_of_stone",
  "item_orb_of_lightning",
  "item_blast_staff",
  "item_rune_of_repair",
  "item_bassline",
  "item_drums",
  "item_double_damage",
  "item_quad_damage",
  "item_custom_cheese",
];

var localPlayerID = Players.GetLocalPlayer();
var localPlayerTeam = Players.GetTeam(localPlayerID)

var restockTimes = {};

function UpdateItemInfo(data) {
  // $.Msg(data);

  var itemname = data.itemname;
  var gold_cost = data.gold_cost;
  var lumber_cost = data.lumber_cost;
  var stock = data.stock;
  var restock_time = data.restock_time;
  var purchase_time = data.purchase_time;

  var itemButtonPanel = $("#" + itemname);

  // var goldCostLabel = itemButtonPanel.FindChildrenWithClassTraverse("GoldCost")[0];
  // var lumberCostLabel = itemButtonPanel.FindChildrenWithClassTraverse("LumberCost")[0];
  var stockLabel = itemButtonPanel.FindChildrenWithClassTraverse("Stock")[0];
  stockLabel.text = stock;

  // goldCostLabel.text = gold_cost;
  // if (lumber_cost > 0)
  //   lumberCostLabel.text = lumber_cost;

  restockTimes[itemname] = {restock_time: restock_time, purchase_time: purchase_time};

  if (stock > 0) {
    itemButtonPanel.SetHasClass("cooldown_ready", true);
    itemButtonPanel.SetHasClass("in_cooldown", false);
  }
  else {
    itemButtonPanel.SetHasClass("cooldown_ready", false);
    itemButtonPanel.SetHasClass("in_cooldown", true);

    if (restock_time < 0) {
      var cooldownPanel = itemButtonPanel.GetChild(1);
      var cooldownOverlay = cooldownPanel.GetChild(0);

      cooldownOverlay.style.width = "100%";    
    }
  }
}

function RefreshShopInfo() {
  items.forEach(function(itemname) {
    var key = itemname + localPlayerTeam;
    var shopData = CustomNetTables.GetTableValue("custom_shop", key);
    if (shopData)
      UpdateItemInfo(shopData);
  });
}

function UpdateItemCooldowns() {
  Object.keys(restockTimes).forEach(function(itemname) {
    var restock_time = restockTimes[itemname].restock_time;
    var purchase_time = restockTimes[itemname].purchase_time;

    if (purchase_time + restock_time > Game.GetGameTime()) {
      var itemButtonPanel = $("#" + itemname);

      var cooldownLength = restock_time;
      var cooldownRemaining = (purchase_time + restock_time) - Game.GetGameTime();
      var cooldownPercent = Math.ceil(100 * cooldownRemaining / cooldownLength);

      var cooldownPanel = itemButtonPanel.GetChild(1);
      var cooldownOverlay = cooldownPanel.GetChild(0);

      cooldownOverlay.style.width = cooldownPercent+"%";      
    }
  });
}

function AutoUpdateItems()
{
  UpdateItemCooldowns();
  $.Schedule(0.1, AutoUpdateItems);
}

function OnShopUpdated(table_name, key, data) {
  if (data.team == localPlayerTeam) {
    UpdateItemInfo(data)
  }  
}

function AttemptPurchase(itemname) {
  if (Game.IsGamePaused()) return;
  
  GameEvents.SendCustomGameEventToServer("attempt_purchase", {itemname: itemname})

  // See if we can buy the item on the client-side
  var data = CustomNetTables.GetTableValue("lumber", localPlayerID);
  var lumber = 0;
  if (data && data.value) lumber = data.value;

  var gold = Players.GetGold(localPlayerID);

  var key = itemname + localPlayerTeam;
  var itemData = CustomNetTables.GetTableValue("custom_shop", key);
  if (itemData) {
    var gold_cost = data.gold_cost;
    var lumber_cost = data.lumber_cost;
    var stock = data.stock;

    // Check if we should start the cooldown (assuming this purchase is verified)
    if (stock == 1 && lumber > lumber_cost && gold > gold_cost) {
      restockTimes[itemname] = {purchase_time: Game.GetGameTime()};

      var itemButtonPanel = $("#" + itemname);
      itemButtonPanel.SetHasClass("cooldown_ready", false);
      itemButtonPanel.SetHasClass("in_cooldown", true);  
    }
  }  
}

(function () {
  AutoUpdateItems();
  RefreshShopInfo(); 

  CustomNetTables.SubscribeNetTableListener("custom_shop", OnShopUpdated);
})();