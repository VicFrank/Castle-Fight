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
  random: "random",
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
  random: "random_selected",
};

var CurrentRace = "human";

function OnRaceSelected(race) {
  CurrentRace = race;
  UpdateHeroDetails(race);
  Game.EmitSound("General.ButtonClick")
}

var CurrentSelectedMoviePanel = $("#kunkka_selected");

function UpdateHeroDetails(race) {
  var heroLabel = $("#CurrentHeroLabel");
  var heroImage = $("#HeroImageSelected");
  var description = $("#RaceDescriptionLabel");

  heroLabel.text = $.Localize("#" + race);
  description.text = $.Localize("#" + race + "_description");

  var moviePanelID = RaceToPanelID[race];
  var moviePanel = $("#" + moviePanelID);

  CurrentSelectedMoviePanel.style.visibility = "collapse";
  moviePanel.style.visibility = "visible";
  CurrentSelectedMoviePanel = moviePanel;
}

function OnHeroSelectButtonPressed() {
  GameEvents.SendCustomGameEventToServer("on_race_selected", 
    {
      hero: RaceToHero[CurrentRace]
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
  HeroSelectPanel.RemoveClass("HeroSelectVisible")
  ShowHeroPanel();  
}

function ShowHeroSelect() {
  HeroSelectPanel.AddClass("HeroSelectVisible");
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
}

(function () {
  // ShowHeroSelect();
  UpdateHeroDetails(CurrentRace);

  $.Schedule(1, HideHeroesInScoreboard);

  CustomNetTables.SubscribeNetTableListener("hero_select", OnHeroSelectStatusChanged);
  UpdateHeroSelectVisibility();
})();