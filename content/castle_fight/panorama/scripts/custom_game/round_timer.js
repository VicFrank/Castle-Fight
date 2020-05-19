var TimerPanel = $("#RoundTimerContainer");

function HideTimer() {
  TimerPanel.RemoveClass("RoundTimerVisible")
}

function ShowTimer() {
  TimerPanel.AddClass("RoundTimerVisible");
}

function UpdateTimer(data) {
  var time = data.seconds;

  $("#CountdownTimer").text = time;
}

function OnRoundStarted(data) {
  HideTimer();

  var round = data.round;
  $("#RoundLabel").text = $.Localize("#round") + " " + round;
}

function OnRoundEnded(data) {
  var round = data.roundNumber;
  $("#RoundLabel").text = $.Localize("#round") + " " + round;
}

function OnHeroSelectStarted(data) {
  $("#RoundStatusLabel").text = $.Localize("#race_selection");
  ShowTimer();
}

function OnLoadingStarted(data) {
  $("#RoundStatusLabel").text = $.Localize("#loading") + "...";
  $("#CountdownTimer").text = "";
}

var localTeam = Players.GetTeam(Players.GetLocalPlayer());

function HideEnemyPicks() {
  if (localTeam == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
    $("#DirePickHider").AddClass("RoundTimerVisible");
  } else {
    $("#RadiantPickHider").AddClass("RoundTimerVisible");
  }
}

function ShowEnemyPicks() {
  if (localTeam == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
    $("#DirePickHider").RemoveClass("RoundTimerVisible");
  } else {
    $("#RadiantPickHider").RemoveClass("RoundTimerVisible");
  }
}

function UpdateHeroSelectState() {  
  var data = CustomNetTables.GetTableValue("hero_select", "status");
  if (data && data.ongoing) {
    OnHeroSelectStarted();
    HideEnemyPicks()
  } else if (data && !data.ongoing) {
    ShowEnemyPicks()
  }
}

function OnHeroSelectStatusChanged(table_name, key, data) {
  UpdateHeroSelectState();
}

(function () {
  GameEvents.Subscribe("countdown", UpdateTimer);
  GameEvents.Subscribe("round_started", OnRoundStarted);
  GameEvents.Subscribe("round_ended", OnRoundEnded);
  GameEvents.Subscribe("loading_started", OnLoadingStarted);

  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
  UpdateHeroSelectState();
})();