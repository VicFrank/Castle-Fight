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
  $("#RoundLabel").text = "Round " + round;
}

function OnHeroSelectStarted(data) {
  $.Msg("OnHeroSelectStarted")
  $("#RoundStatusLabel").text = "Race Selection";
  ShowTimer();
}

function OnLoadingStarted(data) {
  $.Msg("OnLoadingStarted")
  $("#RoundStatusLabel").text = "Loading...";
  $("#CountdownTimer").text = "";
}

function UpdateHeroSelectState() {
  $.Msg("UpdateHeroSelectVisibility");
  
  var data = CustomNetTables.GetTableValue("hero_select", "status");
  if (data && data.ongoing) {
    OnHeroSelectStarted();
  }
}

function OnHeroSelectStatusChanged(table_name, key, data) {
  UpdateHeroSelectState();
}

(function () {
  GameEvents.Subscribe("countdown", UpdateTimer);
  GameEvents.Subscribe("round_started", OnRoundStarted);
  GameEvents.Subscribe("loading_started", OnLoadingStarted);

  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
  UpdateHeroSelectState();
})();