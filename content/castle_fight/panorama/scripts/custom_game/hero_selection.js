var RaceToHero = {
  human: "npc_dota_hero_kunkka",
  naga: "npc_dota_hero_slark",
  nature: "npc_dota_hero_treant",
  night_elves: "npc_dota_hero_vengefulspirit",
  undead: "npc_dota_hero_abaddon",
};

var CurrentRace = "human";

function OnRaceSelected(race) {
  CurrentRace = race;

  UpdateHeroDetails(race);
}

function UpdateHeroDetails(race) {
  var heroLabel = $("#CurrentHeroLabel");
  var heroImage = $("#SelectedHeroImage");
  var description = $("#RaceDescription");

  heroLabel.text = $.Localize("#" + race);
  description.text = $.Localize("#" + race + "_description");
  heroImage.heroname = RaceToHero[race];
}

function OnHeroSelectButtonPressed() {
  GameEvents.SendCustomGameEventToServer("on_race_selected", 
    {
      hero: RaceToHero[CurrentRace]
    });
  // TODO: Change button style on pressed

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
  ShowHeroSelect();
  UpdateHeroDetails(CurrentRace);
})();