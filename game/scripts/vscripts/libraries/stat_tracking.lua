local SERVER_URL = (IsInToolsMode() and "http://localhost:3000") or "http://165.22.34.55";
local SERVER_KEY = "v1";

function SendGameStatsToServer()
  -- Check if we're ranked before sending
  GameRules.GameData.ranked = GameMode:IsRanked()
  -- DeepPrintTable(GameRules.GameData)

  local data = GameRules.GameData

  local raw_json_text = json.encode(data)

  local request_url = SERVER_URL .. "/api/games"
  print(request_url)
  local req = CreateHTTPRequestScriptVM("POST", request_url)
  req:SetHTTPRequestGetOrPostParameter(
    "server_key",
    GetDedicatedServerKeyV2(SERVER_KEY)
  )
  req:SetHTTPRequestGetOrPostParameter(
    "data",
    raw_json_text
  )
  req:Send(function(res)
    if not res.StatusCode == 201 then
      print("Failed SendGameStatsToServer error: " .. res.StatusCode)
      return
    end
    local body = json.decode(res.Body)
    print(res.Body)
  end)
end

-- I don't know where to put this function so it's here
function GameMode:IsRanked()
  if GameRules:IsCheatMode() then
    return false
  elseif CustomNetTables:GetTableValue("settings", "bots_enabled")["botsEnabled"] == 1 then
    return false
  elseif not GameMode:AreTeamsEven() then
    return false
  elseif TableCount(GameRules.playerIDs) < 4 then
    return false
  end

  return true
end

function GameMode:AreTeamsEven()
  local count = 0

  for _,playerID in pairs(GameRules.playerIDs) do
    local team = PlayerResource:GetTeam(playerID)
    if team == DOTA_TEAM_GOODGUYS then
      count = count + 1
    elseif team == DOTA_TEAM_BADGUYS then
      count = count - 1
    end
  end

  return count == 0
end