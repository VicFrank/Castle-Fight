"use strict";

var currentPanel = $("#SettingsPanel");

function UpdateCurrentPanel(newPanel) {
  currentPanel.style.visibility = "collapse";
  currentPanel = newPanel;
  newPanel.style.visibility = "visible";
}

function OnHomeClicked() {
  UpdateCurrentPanel($("#SettingsPanel"));
}

function OnInfoClicked() {
  UpdateCurrentPanel($("#InfoPanel"));
}

function OnTipsClicked() {
  UpdateCurrentPanel($("#TipsPanel"));
}

function OnCreditsClicked() {
  UpdateCurrentPanel($("#CreditsPanel"));
}

function SetUpdateDate() {
  const lastUpdate = "3/24/2023";

  $("#LatestUpdate").text = lastUpdate;
}

function OnSettingsChanged() {
  const numRounds =
    CustomNetTables.GetTableValue("settings", "num_rounds")?.numRounds ?? 1;
  const botsEnabled =
    CustomNetTables.GetTableValue("settings", "bots_enabled")?.botsEnabled == 1;
  const draftMode =
    CustomNetTables.GetTableValue("settings", "draft_mode")?.draftMode ?? "1";
  const treasureBoxEnabled =
    CustomNetTables.GetTableValue("settings", "treasure_box_enabled")
      ?.treasureBoxEnabled == 1;
  const cagingEnabled =
    CustomNetTables.GetTableValue("settings", "caging_enabled")?.caging == 1;

  $("#RoundsToWinLabel").text = numRounds;

  if (botsEnabled) $("#AllowBotsLabel").text = $.Localize("#yes");
  else $("#AllowBotsLabel").text = $.Localize("#no");

  if (treasureBoxEnabled) $("#AllowTreasureBoxLabel").text = $.Localize("#yes");
  else $("#AllowTreasureBoxLabel").text = $.Localize("#no");

  if (cagingEnabled) $("#AllowCagingLabel").text = $.Localize("#yes");
  else $("#AllowCagingLabel").text = $.Localize("#no");

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

function OnPlayerVoteChanged(table_name, key, value) {
  const draftModeVoteKey = "vote_draft_mode_";
  if (!key.startsWith(draftModeVoteKey)) return;

  var draftModeVotes = {};

  for (let playerID = 0; playerID < 8; playerID++) {
    var draftModeVote = CustomNetTables.GetTableValue(
      "settings",
      draftModeVoteKey + playerID
    );
    if (!draftModeVote) continue;

    var draftModeVoteIndex = draftModeVote["vote"];
    if (draftModeVotes[draftModeVoteIndex] != null) {
      draftModeVotes[draftModeVoteIndex]++;
    } else {
      draftModeVotes[draftModeVoteIndex] = 1;
    }
  }

  SetDraftModeVoteTexts(draftModeVotes);
}

function SetDraftModeVoteTexts(draftModeVotes) {
  var draftVotesPanel = $("#draft_votes_panel");
  draftVotesPanel.RemoveAndDeleteChildren();

  for (const [draftMode, votes] of Object.entries(draftModeVotes)) {
    if (draftMode == "-1") continue;

    let draftVotePanel = $.CreatePanel(
      "Label",
      draftVotesPanel,
      "draft_vote_" + draftMode
    );
    draftVotePanel.AddClass("draft-vote-text");

    switch (draftMode) {
      case "1": //All pick
        draftVotePanel.text = $.Localize("#All_pick");
        break;
      case "2": //Single draft
        draftVotePanel.text = $.Localize("#Single_draft");
        break;
      case "3": //All random
        draftVotePanel.text = $.Localize("#All_random");
        break;
    }
    draftVotePanel.text = draftVotePanel.text + " (" + votes + ")";
  }
}

(function () {
  SetUpdateDate();
  CustomNetTables.SubscribeNetTableListener("settings", OnSettingsChanged);
  CustomNetTables.SubscribeNetTableListener("settings", OnPlayerVoteChanged);
})();
