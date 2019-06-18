var RaceToHero = {
  human: "npc_dota_hero_kunkka",
  naga: "npc_dota_hero_slark",
  nature: "npc_dota_hero_treant",
  night_elves: "npc_dota_hero_vengefulspirit",
  undead: "npc_dota_hero_abaddon",
  random: "random",
};

var RaceToPanelID = {
  human: "kunkka_selected",
  naga: "slark_selected",
  nature: "treant_selected",
  night_elves: "vengefulspirit_selected",
  undead: "abaddon_selected",
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
  // TODO: Change button style on pressed
  Game.EmitSound("HeroPicker.Selected")

  HideHeroSelect();
}

var HeroSelectPanel = $("#HeroPickHolder");

function HideHeroSelect() {
  HeroSelectPanel.RemoveClass("HeroSelectVisible")
}

function ShowHeroSelect() {
  HeroSelectPanel.AddClass("HeroSelectVisible");
}

(function () {
  // ShowHeroSelect();
  UpdateHeroDetails(CurrentRace);
  GameEvents.Subscribe("hero_select_started", ShowHeroSelect);
  GameEvents.Subscribe("hero_select_ended", HideHeroSelect);
})();