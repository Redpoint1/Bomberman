unit share;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, LCLType, Buttons;

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
procedure ZobrazMenu; //zobrazi nam menu ako pri spusteni

const //zdielane konstanty v hre

  //====vseobecne====
  level: array[0..9] of string =
    ('level1', 'level2', 'level3', 'level4', 'level5', 'level6', 'level7',
    'level8', 'level9', 'level10');
  //nazvy levelov suborov a v ako poradi sa maju otvarat
  nasobitelXP: array[0..2] of real = (1.5, 1, 1);
  //nasobenie skore NPC ,ktore zavisi od obtiaznosti
  Brana = 4; //id upgradeu brany
  BranaMoznost = [4, 7]; //v akom id bloku sa moze nachadzat brana
  pixel: integer = 33; //kolko pixelov ma jedna kocka 33x33
  RadiusCheck: integer = 25; //v akom okruhu najde NPC hraca a zabije ho
  KlavesnicePohybu = [VK_UP, VK_LEFT, VK_DOWN, VK_RIGHT]; //klavesy pohybu hraca
  StenaCas: array[0..7] of real = (1, 1, 0, 0, 2, 1, 3, 2);
  //pre challenge ak nebol zadana cas mapy > 0 sekund nech sa snazi nejako urcit kolko by trvala podla id stien
  ZmenaStien: array[0..7] of integer = (0, 1, 3, 3, 0, 5, 7, 0);
  //ked ho zasiahne vybuch na aky typ steny sa ma zmenit index -> id steny pred hodnota->na aky typ sama zmenit

  //====Player====
  StartBomb: integer = 1; //zaciatocnicke parametre hraca pri vytvoreni
  StartSkore: integer = 0;
  StartZivot: integer = 3;
  StartSpeed: real = 1;
  StartLevel: integer = 0;
  StartRadius: integer = 1;
  SpawnSuradnice: integer = 50; //na akych suradniciach ma zacat hrac
  PovoleneBloky: array[0..2] of SNpcBloky = ([0, 2], [0, 2, 3], [0, 2, 3]);
  //cez ktore typy stien moze prejst
  //povolene bloky ,cez ktore moze hrac prechadzat (volne policko a bomba)
  ZnicitelneBloky = [2, 4, 6, 7]; //ktore bloky moze nicit

  //====Upgrade====
  BlokUpgrade = [4, 7]; //v akom type steny moze byt upgrade (okrem brany)
  UncommonUpgrade: array[0..2] of integer = (0, 1, 2);
  //ktore typy upgradeov su menej cenne
  RareUpgrade: array[0..0] of integer = (3); //ktore su cennejsie
  UpgradeCost: array [0..3] of integer = (2000, 3000, 1500, 4000);
  //kolko skore potrebne na upgrade
  MaxUpgrade: array [0..2] of integer = (4, 2, 6); //maxpocet upgrade-ov
  UpgradeSpeedHodnota: real = 0.10;
  //kolko ma pridavat rychlost docastny upgrade u zakladneho 1 je to zvysenie o 10%

  //===NPC===
  NpcSpeed: array[0..2] of array[0..2] of real = ((0.7, 0.8, 0.6),
    (0.8, 0.9, 0.7),
    (0.8, 0.9, 0.7));
  //rychlost jednotlivych typov npc index -> obtiaznost
  NpcBloky: array[0..2] of array[0..2] of SNpcBloky =
    (([0, 3], [0, 3], [0, 2, 3, 4, 6, 7]),
    ([0], [0], [0, 2, 4, 6, 7]),
    ([0], [0], [0, 2, 4, 6, 7]));
  //cez ktore steny mozu prejst 1. index -> obtiaznost, 2. index -> typ NPC, hodnoty -> typy stien
  NpcNasielHraca: integer = 50; //vzdialenost kedy sa otoci na hraca a pojde za nim
  SkoreZaNpc: array[0..2] of integer = (100, 200, 500);
//kolko skore sa dostane za zabitie npc podla typu

implementation

uses zaklad;

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

procedure ZobrazMenu; //nech to nemame viackrat v kode tak je to hodene do procedury
begin
  Form1.HryObraz.Canvas.Brush.Color := Form1.Color;
  Form1.HryObraz.Canvas.FillRect(Form1.ClientRect); //vypln image
  gui := TBitMap.Create;
  gui.LoadFromFile('img/logo.bmp'); //nacitaj obrazok loga
  gui.Transparent := True;
  Form1.HryObraz.Canvas.Draw((Form1.HryObraz.Width div 2) - (gui.Width div 2), 15, gui);
  //vykreslenie loga v menu
  gui.Transparent := False;
  gui.LoadFromFile('img/gui.bmp'); //nacitanie informacneho panelu pre hraca
  Form1.HryObraz.Canvas.Font.Size := 18;  //defaulty fontu
  Form1.HryObraz.Canvas.Font.Color := clWhite;
  Form1.HryObraz.Canvas.Font.Bold := True;
  Form1.MenuPanel.Show; //ukaz tlacitka menu
end;


end.
