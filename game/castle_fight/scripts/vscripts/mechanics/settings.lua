function UpdateSettingsNetTable(playerID)
  CustomNetTables:SetTableValue("settings", tostring(playerID), {
    votedToDraw = GameRules.drawVotes[playerID],
  })
end

--------------------------------------------------
-- Draws
--------------------------------------------------
function ClearDrawSettings()
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

function GameMode:StartDrawVoteCountdown(delay)
  GameRules.DrawTimer = Timers:CreateTimer(delay, function()
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
  -- hide the vote after it's been rejected
  GameMode:StartDrawVoteCountdown(100)
end

function OnDrawVoteChanged(playerID, vote)
  local voteChanged = GameRules.drawVotes[playerID] == nil or GameRules.drawVotes[playerID] ~= vote

  if not voteChanged then return end

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
  local eastNumVoters = 0
  local westNumVoters = 0
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
    else
      if team == DOTA_TEAM_GOODGUYS then
        westNumVoters = westNumVoters + 1
      elseif team == DOTA_TEAM_BADGUYS then
        eastNumVoter = eastNumVoters + 1
      end
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
      elseif vote == false then
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

  if westNumReject == westNumVoters or eastNumReject == eastNumVoters then
    EndDrawVoting()
  end

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

  GameRules.numRoundsVotes[playerID] = numRoundsVote
  
  local result = GetVoteResult(GameRules.numRoundsVotes, 2)

  CustomNetTables:SetTableValue("settings", "num_rounds", {
    numRounds = result
  })
end

function OnAllowBotsVote(eventSourceIndex, args)
  local playerID = args.PlayerID
  local allowBots = args.allowBots == 1

  GameRules.allowBotsVote[playerID] = allowBots

  local result = GetVoteResult(GameRules.allowBotsVote, false)
  
  CustomNetTables:SetTableValue("settings", "bots_enabled", {
    botsEnabled = result
  })
end

function OnDraftModeVote(eventSourceIndex, args)
    local playerID = args.PlayerID
    local draftMode = args.id
  
    if draftMode == "-1" then
        GameRules.draftMode[playerID] = nil
    else
        GameRules.draftMode[playerID] = draftMode
    end
    
    local result = GetVoteResult(GameRules.draftMode, 1)
  
    CustomNetTables:SetTableValue("settings", "draft_mode", {
        draftMode = result
    })
end

function ClearGGVote(team)
  for _,playerID in pairs(GameRules.playerIDs) do
    GameRules.drawVotes[playerID] = false
  end
end

function GameMode:CountGGVotes(team)
  local votes = 0
  local numPlayers = 0

  for _,playerID in pairs(GameRules.playerIDs) do
    local playerTeam = PlayerResource:GetTeam(playerID)
    local vote = GameRules.ggVote[playerID]

    if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED
      and not PlayerResource:IsFakeClient(playerID) then
        if playerTeam == team then
          numPlayers = numPlayers + 1
          if vote then
            votes = votes + 1
          end
        end
    end
  end

  return votes, numPlayers
end

function GameMode:VoteGG(playerID)
  if not GameRules.roundInProgress then
    return
  end

  local roundDuration = GameRules:GetGameTime() - GameRules.roundStartTime
  if roundDuration < 400 then
    Say(nil, "It is too early to concede", false)
    return
  end

  GameRules.ggVote[playerID] = true
  local team = PlayerResource:GetTeam(playerID)
  local votes, numPlayers = GameMode:CountGGVotes(team)

  local teamString = ""
  if team == DOTA_TEAM_GOODGUYS then
    teamString = "West"
  elseif team == DOTA_TEAM_BADGUYS then
    teamString = "East"
  end

  local voteStatus = votes .. "/" .. numPlayers .. " " .. teamString
    .. " players voted to forfeit!"
  Say(nil, voteStatus, false)

  if votes == numPlayers then
    GameMode:EndRound(team)
  else
    if team == DOTA_TEAM_GOODGUYS then
      Timers:RemoveTimer(GameRules.GGTimerWest)
      GameRules.GGTimerWest = Timers:CreateTimer(90, function()
        Say(nil, "GG vote failed for West", false)
        ClearGGVote(team)
      end)
    elseif team == DOTA_TEAM_BADGUYS then
      Timers:RemoveTimer(GameRules.GGTimerEast)
      GameRules.GGTimerEast = Timers:CreateTimer(90, function()
        Say(nil, "GG vote failed for East", false)
        ClearGGVote(team)
      end)
    end
  end
end

--------------------------------------------------
-- Vote Utility
--------------------------------------------------

function GetVoteResult(voteTable, default)
  local votes = {}

  for playerID,vote in pairs(voteTable) do
    if not votes[vote] then
      votes[vote] = 1
    else
      votes[vote] = votes[vote] + 1
    end
  end

  return GetPluralityVoteOutcome(votes, default)
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