unit share;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType;

type
  RSkore = record  //na lahsie nacitavanie zo skore.dat
    nick: string[20];
    body: integer;
  end;
  TPoleSkore = array of RSkore; //definovanie polia
  PPoleSkore = ^TPoleSkore;
  //aby sme nemuseli robit funkciu ktora vrati utriedene ,ale nech to zrobi hned
  SNpcBloky = set of byte; //aby sme vedeli definovat pole mnozin

procedure Sortenie(Zoznam: PPoleSkore); //usortenie skore hracov

const //zdielane konstanty v hre
  //vseobecne
  level: array[0..2] of string = ('level0', 'level1', 'level2');
  //nazvy levelov suborov a v ako poradi sa maju otvarat
  Brana = 4; //id upgradeu brany
  BranaMoznost = [4]; //v akom id bloku sa moze nachadzat brana
  pixel: integer = 33; //kolko pixelov ma jedna kocka 33x33
  KlavesnicePohybu = [VK_UP, VK_LEFT, VK_DOWN, VK_RIGHT]; //klavesy pohybu hraca

  //Player
  StartBomb: integer = 1; //zaciatocnicke parametre hraca pri vytvoreni
  StartSkore: integer = 0;
  StartZivot: integer = 3;
  StartSpeed: real = 1;
  StartLevel: integer = 0;
  StartRadius: integer = 1;
  PovoleneBloky = [0, 2];
  SpawnSuradnice = 116; //spawnovaci pixel (prve volne policko od laveho horneho rohu)
  //povolene bloky ,cez ktore moze hrac prechadzat (volne policko a bomba)
  ZnicitelneBloky = [2, 4]; //ktore bloky moze nicit

  //Upgrade
  BlokUpgrade = [4]; //v akom type steny moze byt upgrade (okrem brany)
  UncommonUpgrade: array[0..2] of integer = (0, 1, 2);
  //ktore typy upgradeov su menej cenne
  RareUpgrade: array[0..0] of integer = (3); //ktore su cennejsie
  UpgradeCost: array [0..3] of integer = (0, 0, 0, 0); //kolko skore potrebne na upgrade
  MaxUpgrade: array [0..2] of integer = (4, 2, 4); //maxpocet upgrade-ov
  MaxPocetBomb: integer = 5;
  //kolko bomb moze mat maximalne hrac spolu dokopy (kvoli docastnm upgradeom nech nenajde 4x tento upgrade na mape a nech nema max upgrade to by bol velmi velky radius)
  MaxRadiusBomby: integer = 4; //rovnako
  MaxHracSpeed: real = 1.5;  //rovnako
  UpgradeSpeedHodnota: real = 0.10;
  //kolko ma pridavat rychlost docastny upgrade u zakladneho 1 je to zvysenie o 10%

  //NPC
  NpcSpeed: array[0..2] of real = (0.75, 0.75, 1); //rychlost jednotlivych typov npc
  NpcBloky: array[0..2] of SNpcBloky = ([0, 2], [0, 2], [0, 2, 4]);
//bloky cez ktore moze prechadzat typ npc

implementation

procedure Sortenie(Zoznam: PPoleSkore); //min sort ala v mojom podani max sort :)
var
  I, J, Max: integer;
  Pom: RSkore;
begin
  if (length(zoznam^) < 2) then
    exit; //ak neobsahuje aspon 2 prvky nema co sortovat
  for I := 0 to length(Zoznam^) - 2 do
  begin
    Max := I; //max nastavime na prvok i v poli (kedze predchodzie su usortene uz
    for J := I + 1 to length(Zoznam^) - 1 do
      if Zoznam^[J].body > Zoznam^[Max].body then //hladame od i-teho najvacsi
        Max := J;
    Pom := Zoznam^[Max]; //prehodime ich
    Zoznam^[Max] := Zoznam^[I];
    Zoznam^[I] := Pom;
  end;
end;


end.
