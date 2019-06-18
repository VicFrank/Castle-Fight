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

(function () {
  GameEvents.Subscribe("countdown", UpdateTimer);
  GameEvents.Subscribe("round_started", OnRoundStarted);
  GameEvents.Subscribe("hero_select_started", OnHeroSelectStarted);
  GameEvents.Subscribe("loading_started", OnLoadingStarted);
})();