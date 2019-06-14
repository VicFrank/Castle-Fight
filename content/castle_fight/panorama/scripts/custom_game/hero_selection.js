var RaceToHero = {
  human: "npc_dota_hero_kunkka",
  naga: "npc_dota_hero_slark",
  nature: "npc_dota_hero_treant",
  night_elves: "npc_dota_hero_vengefulspirit",
  undead: "npc_dota_hero_abaddon",
};

var RaceToHeroWebm = {
  humanwebm: "file://{resources}/videos/heroes/npc_dota_hero_kunkka.webm",
  nagawebm: "file://{resources}/videos/heroes/npc_dota_hero_slark.webm",
  naturewebm: "file://{resources}/videos/heroes/npc_dota_hero_treant.webm",
  night_elveswebm: "file://{resources}/videos/heroes/npc_dota_hero_vengefulspirit.webm",
  undeadwebm: "file://{resources}/videos/heroes/npc_dota_hero_abaddon.webm",
};

var CurrentRace = "human";

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
  heroImage.src = RaceToHeroWebm[race];
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
  ShowHeroSelect();
  UpdateHeroDetails(CurrentRace);
})();