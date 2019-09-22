"use strict";

var currentPanel = $("#SettingsPanel")

function UpdateCurrentPanel(newPanel)
{
  currentPanel.style.visibility = "collapse";
  currentPanel = newPanel;
  newPanel.style.visibility = "visible";
}

function OnHomeClicked()
{
  UpdateCurrentPanel($("#SettingsPanel"));
}

function OnInfoClicked()
{
  UpdateCurrentPanel($("#InfoPanel"));
}

function OnTipsClicked()
{
  UpdateCurrentPanel($("#TipsPanel"));
}

function OnCreditsClicked()
{
  UpdateCurrentPanel($("#CreditsPanel"));
}

function SetUpdateDate() {
  var lastUpdate = "9/22/2019";

  $("#LatestUpdate").text = lastUpdate;
}

function OnSettingsChanged() {
  var numRounds = CustomNetTables.GetTableValue("settings", "num_rounds")["numRounds"];
  var botsEnabled = CustomNetTables.GetTableValue("settings", "bots_enabled")["botsEnabled"] == 1;
  
  $("#RoundsToWinLabel").text = numRounds;
  if (botsEnabled)
    $("#AllowBotsLabel").text = $.Localize("#yes");
  else
    $("#AllowBotsLabel").text = $.Localize("#no");
}

(function () {
  SetUpdateDate();
  CustomNetTables.SubscribeNetTableListener("settings", OnSettingsChanged);
})();