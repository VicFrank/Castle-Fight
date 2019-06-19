function UpdateRoundScores() {  
  var data = CustomNetTables.GetTableValue("round_score", "score");
  if (data) {
    $("#GoodGuysScore").text = data.left_score;
    $("#BadGuysScore").text = data.right_score;
  }
}

function OnRoundScoreChanged(table_name, key, data) {
  UpdateRoundScores();
}

(function () {
  CustomNetTables.SubscribeNetTableListener("round_score", OnRoundScoreChanged);
  UpdateRoundScores();
})();