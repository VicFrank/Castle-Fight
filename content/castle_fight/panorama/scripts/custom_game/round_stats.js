function UpdateRoundScores() {  
  var scoreData = CustomNetTables.GetTableValue("round_score", "score");
  if (scoreData) {
    $("#GoodGuysScore").text = scoreData.left_score;
    $("#BadGuysScore").text = scoreData.right_score;

    $("#WestScore").text = scoreData.left_score;
    $("#EastScore").text = scoreData.right_score;
  }
}

var GoodGuyRowPosition = 1;
var BadGuyRowPosition = 5;

var localPlayerID = Players.GetLocalPlayer();
var rowPositions = {};

function OnRoundScoreChanged(table_name, key, data) {
  UpdateRoundScores();

  if (key !== "score") {
    var playerID = parseInt(key);
    var steamid = Game.GetPlayerInfo(playerID).player_steamid;

    var hero = Players.GetPlayerHeroEntityIndex(playerID);
    var heroName = $.Localize(Entities.GetUnitName(hero));

    var unitsKilled = data.unitsKilled;
    var buildingsBuilt = data.buildingsBuilt;
    var numUnitsTrained = data.numUnitsTrained;
    var rescueStrikeDamage = data.rescueStrikeDamage;
    var rescueStrikeKills  = data.rescueStrikeKills;
    var income = Math.floor(data.income);

    if (!rowPositions[playerID]) {
      var team = Players.GetTeam(playerID);

      if (team == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
        rowPositions[playerID] = GoodGuyRowPosition;
        GoodGuyRowPosition++;
      } else if (team == DOTATeam_t.DOTA_TEAM_BADGUYS) {
        rowPositions[playerID] = BadGuyRowPosition;
        BadGuyRowPosition++;
      }
    }

    var rowNumber = rowPositions[playerID];

    var ScoreboardRow = $("#ScoreboardRow" + rowNumber);

    if (playerID == localPlayerID) {
      ScoreboardRow.AddClass("LocalPlayer");
    }

    // DOTAAvatarImage
    ScoreboardRow.GetChild(0).RemoveClass("Invisible");
    ScoreboardRow.GetChild(0).steamid = steamid;
    // Username/Hero
    ScoreboardRow.GetChild(1).RemoveClass("Invisible");
    // DOTAUserName
    ScoreboardRow.GetChild(1).GetChild(0).steamid = steamid;
    // Hero Name
    ScoreboardRow.GetChild(1).GetChild(1).text = heroName;
    // Income
    ScoreboardRow.GetChild(2).text = income;
    // Units Trained
    ScoreboardRow.GetChild(3).text = numUnitsTrained;
    // Units Killed
    ScoreboardRow.GetChild(4).text = unitsKilled;
    // Buildings Built
    ScoreboardRow.GetChild(5).text = buildingsBuilt;
    // Rescue Strike Damage
    ScoreboardRow.GetChild(6).text = rescueStrikeDamage;
  }
}

function OnRoundEnded(data) {
  $.Msg("OnRoundEnded");

  var cameraTarget = data.losingCastlePosition;
  GameUI.SetCameraTargetPosition(cameraTarget, 1);

  $("#ScoreboardHolder").AddClass("ScoreboardVisible");

  var RoundWinnerPanel = $("#RoundWinner");

  if (data.winningTeam == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
    RoundWinnerPanel.text = "Western Forces Victory!";
    RoundWinnerPanel.AddClass("WestColor");
  } else {
    RoundWinnerPanel.text = "Eastern Forces Victory!";
    RoundWinnerPanel.AddClass("EastColor");
  }
}

function UpdateScoreboardVisibility() {
  // Hide the scoreboard when hero select starts
  var data = CustomNetTables.GetTableValue("hero_select", "status");
  if (data && data.ongoing) {
    $("#ScoreboardHolder").RemoveClass("ScoreboardVisible");
  }
}

function OnHeroSelectStatusChanged(table_name, key, data) {
  UpdateScoreboardVisibility();
}

(function () {
  CustomNetTables.SubscribeNetTableListener("round_score", OnRoundScoreChanged);
  UpdateRoundScores();

  GameEvents.Subscribe("round_ended", OnRoundEnded);
  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
})();