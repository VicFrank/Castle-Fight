"use strict";

var localPlayerID = Players.GetLocalPlayer();
var IsSpectator = Players.IsSpectator(localPlayerID);

function OnDrawButtonPressed() {
	if (IsSpectator) return;

	GameEvents.SendCustomGameEventToServer("draw_vote", {vote: true});

	if (!$.GetContextPanel().BHasClass("vote_in_progress")) {
		// initialize the vote
		$("#DrawButtonLabel").text = "Accept";
		$.GetContextPanel().SetHasClass("vote_in_progress", true);
		$("#WestDrawVotes").text = "West: " +  0;
		$("#EastDrawVotes").text = "East: " +  0;
	}
}

function OnContinueButtonPressed() {
	GameEvents.SendCustomGameEventToServer("draw_vote", {vote: false});
}

function OnSettingsChanged(table_name, key, data) {
	if (key == localPlayerID) {
		if (data.votedToDraw) {
			$("#DrawButtonLabel").text = "Accept";
		} else {

		}
	} else if (key == "draw_votes") {
		$("#WestDrawVotes").text = data.westDrawVotes;
		$("#EastDrawVotes").text = data.eastDrawVotes;
		$("#WestRejectVotes").text = data.westNumReject;
		$("#EastRejectVotes").text = data.eastNumReject;
	} else if (key == "draw_vote_status") {
		$.GetContextPanel().SetHasClass("can_vote", data.canVote);
		$.GetContextPanel().SetHasClass("vote_in_progress", data.inProgress);
		if (!data.inProgress)
			$("#DrawButtonLabel").text = $.Localize("#offer_draw");			
	}
}

(function ()
{	
	CustomNetTables.SubscribeNetTableListener("settings", OnSettingsChanged);
})();
