
function OnPlayerLumberChanged(table_name, key, data) {
   UpdateLumber()
}

function UpdateLumber() {
  var playerID = Players.GetLocalPlayer();
  var data = CustomNetTables.GetTableValue("lumber", playerID)
   $('#LumberText').text = data.value;
}

function UpdateGold() {
  var playerID = Players.GetLocalPlayer()
  var gold = Players.GetGold(playerID)
  $('#GoldText').text = gold
  $.Schedule(0.1, UpdateGold);
}

(function () {
  UpdateGold();
  UpdateLumber();
  CustomNetTables.SubscribeNetTableListener("lumber", OnPlayerLumberChanged);
})();