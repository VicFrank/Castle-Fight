"use strict";

var rootPanel = $("#Avatars");

var LocalPlayerID = Players.GetLocalPlayer();
var LocalTeam = Players.GetTeam(LocalPlayerID);
var playerPanels = [];

function Initialize() {
  // Delete existing player panels
  rootPanel.RemoveAndDeleteChildren();
  rootPanel.style.visibility = "visible";
  playerPanels = [];

  let players = [];

  for (let i = 0; i < 8; i++){
    if (Game.GetPlayerInfo(i)) {
      let steam_id = Game.GetPlayerInfo(i).player_steamid;
      let team = Players.GetTeam(i);

      players.push({
        steam_id,
        playerID: i,
        team,
      })
    }
  }

  players.sort(function(a,b) {
    return a.team - b.team;
  });

  players.forEach(function(playerInfo) {
    let steam_id = playerInfo.steam_id;
    let playerID = playerInfo.playerID;

    let playerPanel = CreatePlayerPanel(playerID, steam_id);
    playerPanels.push(playerPanel);
  });
}

function HidePlayerList() {
  rootPanel.style.visibility = "collapse";
}

function CreatePlayerPanel(id, steam_id) {
  let isLocal = id == LocalPlayerID;

  let playerPanel = $.CreatePanel("Panel", rootPanel, "PlayerPanel");
  playerPanel.SetHasClass("IsLocalPlayer", isLocal);
  playerPanel.playerID = id;

  var playerTeam = Players.GetTeam(id);
  var isInEnemyTeam = LocalTeam != playerTeam;

  let AvatarContainer = $.CreatePanel("Panel", playerPanel, "");
  AvatarContainer.AddClass("AvatarContainer");

  AvatarContainer.BCreateChildren(
    '<DOTAAvatarImage hittest="false" id="player_avatar_' + id + '" class="UserAvatar"/>',
    false,
    false
  );

  let AvatarPanel = $("#player_avatar_" + id);
  AvatarPanel.steamid = steam_id;

  let DisconnectedIcon = $.CreatePanel("Panel", AvatarContainer, "DisconnectedIcon");
  
  $.Schedule(1.0, () => CreateHeroIconPanel(id, AvatarContainer));

  let UserInfoContainer = $.CreatePanel("Panel", playerPanel, "user_info" + id);
  UserInfoContainer.AddClass("UserInfoContainer");

  let usernamePanel = $.CreatePanel("DOTAUserName", UserInfoContainer, "Username");
  usernamePanel.steamid = steam_id;

  let FirstRow = $.CreatePanel("Panel", UserInfoContainer, "first_row_panel" + id);
  FirstRow.AddClass("FirstRow");
  
  let InterestContainer = $.CreatePanel("Panel", FirstRow, "interest_container" + id);
  InterestContainer.AddClass("InterestContainer");

  let InterestIconPanel = $.CreatePanel("Panel", InterestContainer, "interest_icon" + id);
  InterestIconPanel.AddClass("InterestIcon");
  
  let InterestText = $.CreatePanel("Label", InterestContainer, "interest_text" + id);
  InterestText.AddClass("InterestText");
  InterestText.text = "+5";
  InterestContainer.style.visibility = "collapse";
  
  var timeToHideIncome = isInEnemyTeam ? 60.0 : 0;
  $.Schedule(timeToHideIncome, () => {    
    InterestContainer.style.visibility = "visible";
  });
  
  if (isInEnemyTeam) {
    playerPanel.AddClass("AvatarEnemy");
  }
  else {
    let ResourcesContainer = $.CreatePanel("Panel", playerPanel, "resources_panel" + id);
    ResourcesContainer.AddClass("ResourcesContainer");
  
    let GoldContainer = $.CreatePanel("Panel", ResourcesContainer, "gold_container" + id);
    GoldContainer.AddClass("GoldContainer");
    
    let GoldIconPanel = $.CreatePanel("Panel", GoldContainer, "gold_icon" + id);
    GoldIconPanel.AddClass("GoldIcon");
    
    let GoldIconText = $.CreatePanel("Label", GoldContainer, "gold_text" + id);
    GoldIconText.AddClass("GoldText");
    GoldIconText.text = Players.GetGold(id);
  
    let LumberContainer = $.CreatePanel("Panel", ResourcesContainer, "lumber_panel" + id);
    LumberContainer.AddClass("LumberContainer");
    
    let LumberIconPanel = $.CreatePanel("Panel", LumberContainer, "lumber_icon" + id);
    LumberIconPanel.AddClass("LumberIcon");
    
    let LumberIconText = $.CreatePanel("Label", LumberContainer, "lumber_text" + id);
    LumberIconText.AddClass("LumberText");
    LumberIconText.text = "0";
  
    let CheeseContainer = $.CreatePanel("Panel", ResourcesContainer, "cheese_panel" + id);
    CheeseContainer.AddClass("CheeseContainer");
    
    let CheeseIconPanel = $.CreatePanel("Panel", CheeseContainer, "cheese_icon" + id);
    CheeseIconPanel.AddClass("CheeseIcon");
    
    let CheeseIconText = $.CreatePanel("Label", CheeseContainer, "cheese_text" + id);
    CheeseIconText.AddClass("CheeseText");
    CheeseIconText.text = "1";
  }

  return playerPanel;
}

function CreateHeroIconPanel(playerID, AvatarContainer) {
  var heroName = Players.GetPlayerSelectedHero(playerID)

  let HeroIconPanel = $.CreatePanel("DOTAHeroImage", AvatarContainer, "hero_icon" + playerID);
  HeroIconPanel.AddClass("HeroIconPanel");
  HeroIconPanel.heroname = heroName;
  HeroIconPanel.heroimagestyle = "icon";  
}

function UpdatePanels() {
  for(let i=0; i<playerPanels.length; i++) {
    let panel = playerPanels[i];
    const playerID = panel.playerID;
    
    let connectionState = Game.GetPlayerInfo(playerID).player_connection_state;
    let isDisconnected = connectionState != DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED

    panel.SetHasClass("Disconnected", isDisconnected);
  }

  $.Schedule(1.0/30.0, UpdatePanels);
}

function OnResourcesUpdated(table_name, playerID, resources) {
  if (!resources) return;  
  
  for(let i = 0; i < playerPanels.length; i++) {
    let panel = playerPanels[i];
    const panelPlayerID = panel.playerID;
    var playerTeam = Players.GetTeam(panelPlayerID);
    var isInEnemyTeam = LocalTeam != playerTeam;

    if(panelPlayerID == playerID && !isInEnemyTeam) {
      $('#gold_text' + panelPlayerID).text = Math.floor(resources.gold);
      $('#cheese_text' + panelPlayerID).text = Math.floor(resources.cheese);
      $('#lumber_text' + panelPlayerID).text = Math.floor(resources.lumber);
      
      break;
    }
  }
}

function OnIncomeUpdated(table_name, playerID, income) {  
  if (!income) return;
  
  for(let i = 0; i < playerPanels.length; i++) {
    let panel = playerPanels[i];
    const panelPlayerID = panel.playerID;

    if(panelPlayerID == playerID) {
      var interestTextPanel = $('#interest_text' + panelPlayerID);
      if(interestTextPanel) {
        interestTextPanel.text = "+" + Math.floor(income.postTaxIncome);
      }
      
      break;
    }
  }
}

function OnHeroSelectStatusChanged(table_name, key, data) {
  if(key != "status") return;

  if (data && data.ongoing) {
    HidePlayerList();
  } else {
    Initialize();
  }
}

(function () {
  CustomNetTables.SubscribeNetTableListener("resources", OnResourcesUpdated);
  CustomNetTables.SubscribeNetTableListener("player_income", OnIncomeUpdated);
  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
})();