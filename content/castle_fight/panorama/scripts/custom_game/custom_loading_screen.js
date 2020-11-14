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
  var lastUpdate = "10/27/2020";

  $("#LatestUpdate").text = lastUpdate;
}

function OnSettingsChanged() {
  var numRounds = CustomNetTables.GetTableValue("settings", "num_rounds")["numRounds"];
  var botsEnabled = CustomNetTables.GetTableValue("settings", "bots_enabled")["botsEnabled"] == 1;
  var draftMode = CustomNetTables.GetTableValue("settings", "draft_mode")["draftMode"];
  
  $("#RoundsToWinLabel").text = numRounds;
  if (botsEnabled)
    $("#AllowBotsLabel").text = $.Localize("#yes");
  else
    $("#AllowBotsLabel").text = $.Localize("#no");

  switch (draftMode) {
    case "1": //All pick
      $("#DraftModeLabel").text = $.Localize("#All_pick");
      break;
    case "2": //Single draft
      $("#DraftModeLabel").text = $.Localize("#Single_draft");
      break;
    case "3": //All random
      $("#DraftModeLabel").text = $.Localize("#All_random");
      break;
  }
}

(function () {
  SetUpdateDate();
  CustomNetTables.SubscribeNetTableListener("settings", OnSettingsChanged);
})();