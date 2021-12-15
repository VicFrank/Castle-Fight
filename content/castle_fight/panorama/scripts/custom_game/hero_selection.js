var RaceToHero = {
  human: "npc_dota_hero_kunkka",
  naga: "npc_dota_hero_slark",
  nature: "npc_dota_hero_treant",
  night_elves: "npc_dota_hero_vengefulspirit",
  undead: "npc_dota_hero_abaddon",
  orc: "npc_dota_hero_juggernaut",
  north: "npc_dota_hero_tusk",
  elves: "npc_dota_hero_invoker",
  chaos: "npc_dota_hero_chaos_knight",
  corrupted: "npc_dota_hero_grimstroke",
  mech: "npc_dota_hero_tinker",
  elemental: "npc_dota_hero_wisp",
};

var RaceToPanelID = {
  human: "kunkka_selected",
  naga: "slark_selected",
  nature: "treant_selected",
  night_elves: "vengefulspirit_selected",
  undead: "abaddon_selected",
  orc: "juggernaut_selected",
  north: "tusk_selected",
  elves: "invoker_selected",
  chaos: "chaos_knight_selected",
  corrupted: "grimstroke_selected",
  mech: "tinker_selected",
  elemental: "wisp_selected",
};

var RaceToMovieSource = {
  human: "file://{resources}/videos/heroes/npc_dota_hero_kunkka.webm",
  naga: "file://{resources}/videos/heroes/npc_dota_hero_slark.webm",
  nature: "file://{resources}/videos/heroes/npc_dota_hero_treant.webm",
  night_elves: "file://{resources}/videos/heroes/npc_dota_hero_vengefulspirit.webm",
  undead: "file://{resources}/videos/heroes/npc_dota_hero_abaddon.webm",
  orc: "file://{resources}/videos/heroes/npc_dota_hero_juggernaut.webm",
  north: "file://{resources}/videos/heroes/npc_dota_hero_tusk.webm",
  elves: "file://{resources}/videos/heroes/npc_dota_hero_invoker.webm",
  chaos: "file://{resources}/videos/heroes/npc_dota_hero_chaos_knight.webm",
  corrupted: "file://{resources}/videos/heroes/npc_dota_hero_grimstroke.webm",
  mech: "file://{resources}/videos/heroes/npc_dota_hero_tinker.webm",
  elemental: "file://{resources}/videos/heroes/npc_dota_hero_wisp.webm",
};

var CurrentSelectedMoviePanel;
var CurrentRace = "human";

function OnHeroesAvailableChanged(table_name, keyPlayerID, data) {
    var localPlayerID = Players.GetLocalPlayer();
    if(localPlayerID != keyPlayerID) {
      return;
    }

    var heroesAvailable = CustomNetTables.GetTableValue("heroes_available", localPlayerID);
    if (heroesAvailable && heroesAvailable.heroes) {
      SetAvailableHeroes();
    }
}

function SetAvailableHeroes() {
  var localPlayerID = Players.GetLocalPlayer();
  var availableHeroes = CustomNetTables.GetTableValue("heroes_available", localPlayerID);
  
  var amountOfAvailableHeroes = Object.keys(availableHeroes.heroes).length;
  var heroListPanel = $("#HeroPickHolder");

  const amountOfHeroesPerRow = 6;
  const amountOfRows = Math.ceil(amountOfAvailableHeroes / amountOfHeroesPerRow);
  for (let rowIndex = 0; rowIndex < amountOfRows; rowIndex++) {
    let heroRowPanel = $.CreatePanel("Panel", heroListPanel, "heroRow" + rowIndex);
    heroRowPanel.AddClass("HeroRow");

    for (let heroIndex = amountOfHeroesPerRow * rowIndex; heroIndex < amountOfHeroesPerRow * (rowIndex + 1); heroIndex++) {
      const hero = availableHeroes.heroes[heroIndex + 1];
      if(!hero) {
        break;
      }

      CreateHeroMoviePanel(hero, heroIndex, heroRowPanel);
    }
  }

  const heroToSelect = Math.floor(Math.random() * amountOfAvailableHeroes) + 1;
  OnRaceSelected(availableHeroes.heroes[heroToSelect]);
}

function RemoveOldHeroPanels() {
  CurrentSelectedMoviePanel = null;
  var rowIndex = 0;
  do {    
    var heroRowPanel = $("#heroRow" + rowIndex);
    if(heroRowPanel) {
      heroRowPanel.DeleteAsync(0);
      rowIndex++;
    }
    else {
      break;
    }
  } while (true);
}

function CreateHeroMoviePanel(hero, heroIndex, parentPanel) {
  const heroNameLocalized = $.Localize("#" + hero);
  const videoSource = RaceToMovieSource[hero];

  const heroPanelProperties = {
    class: "HeroImage",
    src: videoSource,
    repeat: true,
    autoplay: "onload",
    onmouseover: `UIShowTextTooltip(${heroNameLocalized})`,
    onmouseout: `UIHideTextTooltip()`,
    onactivate: `OnRaceSelected('${hero}')`
  }

  return $.CreatePanelWithProperties(
    "MoviePanel",
    parentPanel,
    `heroMovie${hero}`,
    heroPanelProperties
  );
}

function OnRaceSelected(race) {
  CurrentRace = race;
  UpdateHeroDetails(race);
  Game.EmitSound("General.ButtonClick")
}

function UpdateHeroDetails(race) {
  var heroLabel = $("#CurrentHeroLabel");
  var heroImage = $("#HeroImageSelected");
  var description = $("#RaceDescriptionLabel");

  heroLabel.text = $.Localize("#" + race);
  description.text = $.Localize("#" + race + "_description");

  if(CurrentSelectedMoviePanel) {
    CurrentSelectedMoviePanel.RemoveClass("hero-selected");
  }
  var moviePanel = $("#heroMovie" + race);

  if(!moviePanel) {
    return;
  }

  CurrentSelectedMoviePanel = moviePanel;
  CurrentSelectedMoviePanel.AddClass("hero-selected");
}

function OnHeroSelectButtonPressed() {
  GameEvents.SendCustomGameEventToServer("on_race_selected", 
    {
      hero: RaceToHero[CurrentRace]
    });

  Game.EmitSound("HeroPicker.Selected")

  HideHeroSelect();
}

function OnRandomHeroButtonPressed() {
  GameEvents.SendCustomGameEventToServer("on_race_selected", 
    {
      hero: "random"
    });

  Game.EmitSound("HeroPicker.Selected")

  HideHeroSelect();
}

var HUD = $.GetContextPanel().GetParent().GetParent().GetParent();
var HeroHUD = HUD.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats");

function HideHeroPanel() {
  HeroHUD.style.visibility = "collapse";
}

function ShowHeroPanel() {
  HeroHUD.style.visibility = "visible";
}

var HeroSelectPanel = $("#HeroPickHolder");

function HideHeroSelect() {
  HeroSelectPanel.RemoveClass("HeroSelectVisible");
  $("#DraftModeContainer").AddClass("hidden");
  $("#DraftModeContainer").RemoveClass("visible");
  $("#HeroDetailsContainer").AddClass("hidden");
  $("#HeroDetailsContainer").RemoveClass("visible");

  RemoveOldHeroPanels();

  ShowHeroPanel();  
}

function ShowHeroSelect() {  
  HeroSelectPanel.AddClass("HeroSelectVisible");
  $("#DraftModeContainer").AddClass("visible");
  $("#DraftModeContainer").RemoveClass("hidden");
  $("#HeroDetailsContainer").AddClass("visible");
  $("#HeroDetailsContainer").RemoveClass("hidden");

  HideHeroPanel();
}

// Dota TV Spectators have PlayerID of -1
var IsSpectator = !Players.IsValidPlayerID(Players.GetLocalPlayer());
var IsSpectator = false;
function UpdateHeroSelectVisibility() {
  if (IsSpectator) return;
  
  var data = CustomNetTables.GetTableValue("hero_select", "status");
  if (data && data.ongoing) {
    ShowHeroSelect();
  } else {
    HideHeroSelect();
  }
  
  SetDraftModeText();
}


function SetDraftModeText() {
  var draftMode = CustomNetTables.GetTableValue("settings", "draft_mode")["draftMode"];

  switch (draftMode) {
    case "1": //All pick
      $("#DraftModeHeroSelectLabel").text = $.Localize("#All_pick");
      $("#RandomHeroButton").visible = true;
      break;
    case "2": //Single draft
      $("#DraftModeHeroSelectLabel").text = $.Localize("#Single_draft");
      $("#RandomHeroButton").visible = true;
      break;
    case "3": //All random
      $("#DraftModeHeroSelectLabel").text = $.Localize("#All_random");
      $("#RandomHeroButton").visible = false;
      break;
  }
}

function OnHeroSelectStatusChanged(table_name, key, data) {
  UpdateHeroSelectVisibility();
}

function HideHeroesInScoreboard() {
  var HUD = $.GetContextPanel().GetParent().GetParent().GetParent();
  var scoreboard = HUD.FindChildTraverse("HUDElements").FindChildTraverse("scoreboard");

  var heroImages = scoreboard.FindChildrenWithClassTraverse("ScoreboardHeroImage");
  var heroNames = scoreboard.FindChildrenWithClassTraverse("HeroNameLabel");

  heroImages.forEach(
    function(panel) {
      panel.style.visibility = "collapse";
    }
   );

  heroNames.forEach(
    function(panel) {
      panel.style.visibility = "collapse";
    }
   );

   $.Schedule(1.0/4.0, HideHeroesInScoreboard);
}

(function () {
  UpdateHeroDetails(CurrentRace);
  HideHeroesInScoreboard();

  CustomNetTables.SubscribeNetTableListener("heroes_available", OnHeroesAvailableChanged);
  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
  UpdateHeroSelectVisibility();
})();