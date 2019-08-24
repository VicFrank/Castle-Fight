function UpdateRoundScores() {  
  var scoreData = CustomNetTables.GetTableValue("round_score", "score");
  var numRounds = CustomNetTables.GetTableValue("settings", "num_rounds")["numRounds"];
  if (scoreData) {
    $("#GoodGuysScore").text = scoreData.left_score;
    $("#BadGuysScore").text = scoreData.right_score;

    $("#WestScore").text = scoreData.left_score;
    $("#EastScore").text = scoreData.right_score;

    $("#NumRoundsWest").text = "/" + numRounds;
    $("#NumRoundsEast").text = "/" + numRounds;
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
    } else {
      ScoreboardRow.RemoveClass("LocalPlayer");
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
    if (data.maxIncome) ScoreboardRow.GetChild(2).AddClass("HighScore");
    else ScoreboardRow.GetChild(2).RemoveClass("HighScore");
    // Units Trained
    ScoreboardRow.GetChild(3).text = numUnitsTrained;
    if (data.maxUnitsTrained) ScoreboardRow.GetChild(3).AddClass("HighScore");
    else ScoreboardRow.GetChild(3).RemoveClass("HighScore");
    // Units Killed
    ScoreboardRow.GetChild(4).text = unitsKilled;
    if (data.maxUnitsKilled) ScoreboardRow.GetChild(4).AddClass("HighScore");
    else ScoreboardRow.GetChild(4).RemoveClass("HighScore");
    // Buildings Built
    ScoreboardRow.GetChild(5).text = buildingsBuilt;
    if (data.maxBuildingsBuilt) ScoreboardRow.GetChild(5).AddClass("HighScore");
    else ScoreboardRow.GetChild(5).RemoveClass("HighScore");
    // Rescue Strike Damage
    ScoreboardRow.GetChild(6).text = rescueStrikeDamage;
    if (data.maxRescueStrikeDamage) ScoreboardRow.GetChild(6).AddClass("HighScore");
    else ScoreboardRow.GetChild(6).RemoveClass("HighScore");
  }
}

function OnRoundEnded(data) {
  $.Msg("OnRoundEnded");

  var cameraTarget = data.losingCastlePosition;
  GameUI.SetCameraTargetPosition(cameraTarget, 1);

  $("#ScoreboardHolder").AddClass("ScoreboardVisible");

  var RoundWinnerPanel = $("#RoundWinner");
  var roundNumber = data.roundNumber - 1; // get the round number of the last round

  if (data.winningTeam == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
    RoundWinnerPanel.text = $.Localize("round") + " " + roundNumber + ": " + $.Localize("western_forces") + " " + $.Localize("#victory") + "!";
    RoundWinnerPanel.AddClass("WestColor");
  } else if (data.winningTeam == DOTATeam_t.DOTA_TEAM_BADGUYS) {
    RoundWinnerPanel.text = $.Localize("round") + " " + roundNumber + ": " + $.Localize("eastern_forces") + " " + $.Localize("#victory") + "!";
    RoundWinnerPanel.AddClass("EastColor");
  } else {
    RoundWinnerPanel.text = $.Localize("round") + " " + roundNumber + ": " + $.Localize("#draw") + "!";
    RoundWinnerPanel.AddClass("NeutralColor");
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

function OnNumUnitsChanged(data) {
  var numUnits = data.numUnits;
  $("#NumUnits").text = "Units: " + numUnits;
}

function OnRoundTimerChanged(data) {
  var time = data.time.timer_minute_10 + "" +
    data.time.timer_minute_01 + ":" +
    data.time.timer_second_10 + "" +
    data.time.timer_second_01;
  $("#RoundTime").text = time;
}

(function () {
  CustomNetTables.SubscribeNetTableListener("round_score", OnRoundScoreChanged);
  UpdateRoundScores();

  GameEvents.Subscribe("round_ended", OnRoundEnded);
  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);

  GameEvents.Subscribe("num_units_changed", OnNumUnitsChanged);
  GameEvents.Subscribe("round_timer", OnRoundTimerChanged);
})();