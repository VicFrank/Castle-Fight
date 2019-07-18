function UpdateSettingsNetTable(playerID)
  CustomNetTables:SetTableValue("settings", tostring(playerID), {
    votedToDraw = GameRules.drawVotes[playerID],
  })
end

--------------------------------------------------
-- Draws
--------------------------------------------------
function ClearDrawSettings(canVote)
  for _,playerID in pairs(GameRules.playerIDs) do
    GameRules.drawVotes[playerID] = false
  end

  CustomNetTables:SetTableValue("settings", "draw_votes", {
    westDrawVotes = 0,
    eastDrawVotes = 0,
  })

  CustomNetTables:SetTableValue("settings", "draw_vote_status", {
    inProgress = false,
    canVote = false,
  })

  Timers:RemoveTimer(GameRules.DrawTimer)
end

function GameMode:StartDrawVoteCountdown()
  GameRules.DrawTimer = Timers:CreateTimer(DRAW_VOTE_DELAY, function()
    AllowDrawVotes()
  end)
end

function DrawRound()
  GameMode:EndRound(DOTA_TEAM_NEUTRALS)
end

function AllowDrawVotes()
  CustomNetTables:SetTableValue("settings", "draw_vote_status", {
    inProgress = false,
    canVote = true,
  })
end

function EndDrawVoting()
  ClearDrawSettings()
  AllowDrawVotes()
  EmitAnnouncerSound("announcer_ann_custom_vote_complete")
end

function OnDrawVoteChanged(playerID, vote)
  local voteChanged = GameRules.drawVotes[playerID] == vote

  GameRules.drawVotes[playerID] = vote
  UpdateSettingsNetTable(playerID)
  CustomNetTables:SetTableValue("settings", "draw_vote_status", {
    inProgress = true,
  })

  -- Check to see if we should end the round in a draw
  local westVotes = 0
  local eastVotes = 0
  local westNumVotes = 0
  local eastNumVotes = 0
  for _,playerID in pairs(GameRules.playerIDs) do
    -- print(PlayerResource:GetTeam(playerID), playerID, GameRules.drawVotes[playerID])
    local team = PlayerResource:GetTeam(playerID)
    local vote = GameRules.drawVotes[playerID]
    local score

    if vote then
      score = 1
    else
      score = -1
    end

    -- don't count connected players or bots
    if not PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED
    or PlayerResource:IsFakeClient(playerID) then
      score = 0
    end

    if team == DOTA_TEAM_GOODGUYS then
      westVotes = westVotes + score
      if vote then
        westNumVotes = westNumVotes + 1
      end
    elseif team == DOTA_TEAM_BADGUYS then
      eastVotes = eastVotes + score
      if vote then
        print(vote)
        eastNumVotes = eastNumVotes + 1
      end
    end
  end

  CustomNetTables:SetTableValue("settings", "draw_votes", {
    westDrawVotes = westNumVotes,
    eastDrawVotes = eastNumVotes,
  })

  if westVotes >= 0 and eastVotes >= 0 then
    DrawRound()
  else
    -- Hide the draw UI if no one has changed their vote in a minute
    Timers:RemoveTimer(GameRules.DrawTimer)
    GameRules.DrawTimer = Timers:CreateTimer(60, function()
      EndDrawVoting()
    end)
  end
end

--------------------------------------------------
-- Event listeners
--------------------------------------------------

function OnAddAI(eventSourceIndex, args)
  local playerID = args.PlayerID
  local team = args.team
  local teamBool = team == DOTA_TEAM_GOODGUYS
  print(team == DOTA_TEAM_GOODGUYS)

  Tutorial:AddBot("npc_dota_hero_wisp", "", "", teamBool)
end

function OnVoteDraw(eventSourceIndex, args)
  local playerID = args.PlayerID
  local vote = args.vote == 1

  OnDrawVoteChanged(playerID, vote)
end

function OnVoteNumRounds(eventSourceIndex, args)
  local playerID = args.PlayerID

end