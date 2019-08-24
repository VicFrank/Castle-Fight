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
    GameRules.drawVotes[playerID] = nil
  end

  CustomNetTables:SetTableValue("settings", "draw_votes", {
    westDrawVotes = 0,
    eastDrawVotes = 0,
    westNumReject = 0,
    eastNumReject = 0,
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
    canVote = true,
  })

  -- Check to see if we should end the round in a draw
  local westVotes = 0
  local eastVotes = 0
  local westNumVotes = 0
  local westNumReject = 0
  local eastNumVotes = 0
  local eastNumReject = 0
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
      if vote == true then
        westNumVotes = westNumVotes + 1
      elseif not vote == nil and vote == false then
        westNumReject = westNumReject + 1
      end
    elseif team == DOTA_TEAM_BADGUYS then
      eastVotes = eastVotes + score
      if vote == true then
        eastNumVotes = eastNumVotes + 1
      elseif not vote == nil and vote == false then
        eastNumReject = eastNumReject + 1
      end
    end
  end

  CustomNetTables:SetTableValue("settings", "draw_votes", {
    westDrawVotes = westNumVotes,
    eastDrawVotes = eastNumVotes,
    westNumReject = westNumReject,
    eastNumReject = eastNumReject,
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

function OnNumRoundsVote(eventSourceIndex, args)
  local playerID = args.PlayerID
  local numRoundsVote = args.numRounds

  CustomNetTables:SetTableValue("settings", "num_rounds_vote", {
    playerID = numRoundsVote,
  })
  
  local defaultNumRounds = 2
  local result = GetVoteResult("num_rounds_vote", 2)

  CustomNetTables:SetTableValue("settings", "num_rounds", {
    numRounds = result
  })
  print(result)
end

function OnAllowBotsVote(eventSourceIndex, args)
  local playerID = args.PlayerID
  local allowBots = args.allowBots == 1

  CustomNetTables:SetTableValue("settings", "allow_bots_vote", {
    playerID = allowBots,
  })
  
  local result = GetVoteResult("allow_bots_vote", false)
  
  CustomNetTables:SetTableValue("settings", "bots_enabled", {
    botsEnabled = result
  })
end

function OnDraftModeVote(eventSourceIndex, args)
  local playerID = args.PlayerID

end

--------------------------------------------------
-- Vote Utility
--------------------------------------------------

function GetVoteResult(key, default)
  local votesNetTable = CustomNetTables:GetTableValue("settings", key)

  local votes = {}

  for playerID,vote in pairs(votesNetTable) do
    if not votes[vote] then
      votes[vote] = 1
    else
      votes[vote] = votes[vote] + 1
    end
  end

  return GetPluralityVoteOutcome(votes, 2)
end

function GetPluralityVoteOutcome(votes, default)
  local winners = {}
  local maxVotes = 0

  for vote,numVotes in pairs(votes) do
    if numVotes > maxVotes then
      winners = {vote}
      maxVotes = numVotes
    elseif numVotes == maxVotes then
      table.insert(winners, vote)
    end
  end

  for _,winner in pairs(winners) do
    if winner == default then
      return winner
    end
  end

  return GetRandomTableElement(winners)
end