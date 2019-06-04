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
})();