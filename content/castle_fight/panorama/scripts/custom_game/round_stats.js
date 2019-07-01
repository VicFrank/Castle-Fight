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

function OnRoundEnded(data) {
  $.Msg(data);

  var cameraTarget = data.losingCastlePosition;

  GameUI.SetCameraTargetPosition(cameraTarget, 1)
}

(function () {
  CustomNetTables.SubscribeNetTableListener("round_score", OnRoundScoreChanged);
  UpdateRoundScores();

  GameEvents.Subscribe("round_ended", OnRoundEnded);
})();