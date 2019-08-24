"use strict";


//--------------------------------------------------------------------------------------------------
// Handeler for when the unssigned players panel is clicked that causes the player to be reassigned
// to the unssigned players team
//--------------------------------------------------------------------------------------------------
function OnAddBotPressed()
{
	// Game.PlayerJoinTeam( 5 ); // 5 == unassigned ( DOTA_TEAM_NOTEAM )
	var teamID = $.GetContextPanel().GetAttributeInt("team_id", -1);
	GameEvents.SendCustomGameEventToServer("add_ai", {team: teamID});
}