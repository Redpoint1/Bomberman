unit npc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game;

type

  { TNpc }

  TNpc = class  //trieda nepriatelov
    X, Y, Smer, Faza, Typ, Sekunda: integer;
    //suradnice, orientacia pohybu, animacia, typ nepriatela, cas pohybu
    Zomrel, PohybujeSa: boolean; //prave sa pohybuje
    constructor Create(XX, YY, TypNPC: integer);
  end;

  { TNepriatel }

  TNepriatel = class  //trieda nepratelov (viacerych)
    NPC: array of TNpc; //pole objektov nepriatelov
    NpcObr: array[0..0] of array[0..2] of TBitMap; //obrazky nepriatelov
    procedure Pridaj(XX, YY, Typ: integer); //pridanie dalsieho nepriatela
    procedure vymazNilNpc; //vymazanie z pola nepratelov ktori boli zniceni
    constructor Create();
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny);
    //vykreslenie nepriatelov na obrazok
    procedure Casovac;  // odpocitavanie pohybu nepriatelov
    procedure PohybujSa(Kto: TNpc; Okolie: TSteny); //procedura na pohyb nepriatelov
    procedure VyberSmer(Komu: TNpc); //vyberanie smeru kam sa bude pohybovat
    procedure Posun(Koho: TNpc); //zmena suradnic nepriatela
    procedure OverVybuch(Okolie: TSteny); //overenie ci nepiratela zasiahol vybuch
    procedure Nacitaj(S: string);  //nacitanie zo suboru poziciu a typ nepriatela
    function OverPosun(Komu: TNpc; Okolie: TSteny): boolean;
    //overenie ci sa moze posunu do daneho policka
  end;

implementation

{ TNepriatel }

procedure TNepriatel.Pridaj(XX, YY, Typ: integer);
begin
  setLength(NPC, length(NPC) + 1); //priradenie do pola nepriatelov
  NPC[high(NPC)] := TNpc.Create(XX, YY, Typ);
end;

procedure TNepriatel.vymazNilNpc;
var
  i, j: integer;
begin
  j := 0;    //zmazeme zaniknutych nepriatelov a skracujeme pole nepriatelov
  for i := 0 to length(NPC) - 1 do
    if (NPC[i] <> nil) then
    begin
      NPC[j] := NPC[i];
      Inc(j);
      //prehadzujeme zaniknutycha  hadzeme ich an koniec pola
    end;
  SetLength(NPC, j); //pole nepriatelov zmensujeme o pocet zaniknutych
end;

constructor TNepriatel.Create;
var
  Obrazok: TBitMap;
  i, j: integer;
begin
  setLength(NPC, 0);
  Obrazok := TBitMap.Create;
  Obrazok.LoadFromFile('img/npc.bmp');  //nacitanie obrazkov nepriatelov aj s animaciami
  for i := 0 to 0 do
    for j := 0 to 2 do
    begin
      NpcObr[i][j] := TBitMap.Create;
      NpcObr[i][j].Width := pixel;
      NpcObr[i][j].Height := pixel;
      NpcObr[i][j].Transparent := True;
      NpcObr[i][j].TransparentColor := Obrazok.Canvas.Pixels[0, 0];
      NpcObr[i][j].PixelFormat := pf24bit;
      NpcObr[i][j].Canvas.Draw(-j * pixel, -i * pixel, Obrazok);
    end;
  Obrazok.Free;
end;

procedure TNepriatel.Vykresli(Obr: TCanvas; Okolie: TSteny);
var
  i: integer;
begin
  OverVybuch(Okolie); //pred vykreslovanim skontrolujeme ci ich nezasiahlo vybuch
  VymazNilNpc;   //zmazeme ktorych zasiahol vybuch
  for i := 0 to length(NPC) - 1 do
  begin
    if not (NPC[i].Zomrel) then
    begin
      PohybujSa(NPC[i], Okolie);
      //zmena pozicie pri pohybovani ,alebo priradenie dalsieho pohybu na ine policko
      Obr.Draw(NPC[i].X - 17, NPC[i].Y - 17, NpcObr[NPC[i].Typ][NPC[i].Faza div 50]);
      //vykreslenie
    end
    else
    begin
      if (NPC[i].Sekunda <= 0) then
      begin
        FreeAndNil(NPC[i]);
        VymazNilNpc;
      end
      else
      begin
        Obr.Draw(NPC[i].X - 17, NPC[i].Y - 17, NpcObr[NPC[i].Typ][2]);
        Dec(NPC[i].Sekunda, 10);
      end;
    end;
  end;
end;

procedure TNepriatel.Casovac;
var
  i: integer;
begin
  for i := 0 to length(NPC) - 1 do //pre vsetkych nepriatelov z pola
  begin
    if ((NPC[i].pohybujeSa) and not (NPC[i].Zomrel)) then
      //ak sa prave pohybuje a nezomrel
    begin
      Posun(NPC[i]); //zmenime poziciu
      if (((NPC[i].X mod pixel) = 17) and ((NPC[i].Y mod pixel) = 17) and
        (NPC[i].Smer <> 0)) then  //ak doslo do stredu noveho policka
      begin
        NPC[i].PohybujeSa := False;  //skonci pohyb
      end;
      if (((NPC[i].X mod pixel) = 17) and ((NPC[i].Y mod pixel) = 17) and
        (NPC[i].Smer = 0)) then  //ak je v strede policka
      begin
        if (NPC[i].Sekunda = 0) then //a uz skoncil pohyb
        begin
          NPC[i].PohybujeSa := False; //zresetujeme cas na pohyb
          NPC[i].Sekunda := 1000;
        end
        else
        begin
          NPC[i].Sekunda := NPC[i].Sekunda - 10; //inac mu odpocitavame z casu pohybu
        end;
      end;
    end;
  end;
end;

procedure TNepriatel.PohybujSa(Kto: TNpc; Okolie: TSteny);
begin
  VyberSmer(Kto); //vybereme smer nepriatelovi ktorym ma ist
  if (not (Kto.PohybujeSa)) then
    if (OverPosun(Kto, Okolie)) then //ak sa nepohybuje a moze ist na dane policko
    begin
      Kto.PohybujeSa := True; //zacne sa pohybovat
    end
    else
      Kto.PohybujeSa := False; //ak nevi prejst na dalsie policko nepohne sa
  if (Kto.faza = 0) then //ak skoncila animacia
    Kto.Faza := 100; //zresetujeme animaciu
  Dec(Kto.Faza, 1);
end;

procedure TNepriatel.VyberSmer(Komu: TNpc);
var
  nahodne, nahodnysmer: integer;
begin
  if (not (Komu.PohybujeSa)) then //ak sa nepohybuje
  begin
    nahodne := random(10) + 1;
    if ((nahodne >= 8) and (nahodne < 10)) then
      //20% sanca ze vyberie iny smer akym siel doteraz
    begin
      repeat
        nahodnysmer := random(4) + 1;
      until Komu.Smer <> nahodnysmer; //pokial to nebude iny smer ako doteraz
      Komu.Smer := nahodnysmer; //zmenime na novy smer
    end;
    if (nahodne = 10) then //10% sanca ze zostane stat
      Komu.Smer := 0;  //smer na statie na mietse
    if ((Komu.Smer = 0) and (nahodne < 7)) then
      //70% snaca ze sa zacne pobybovat nejakym smerom ak stoji
    begin
      repeat
        nahodnysmer := random(4) + 1;
      until Komu.Smer <> nahodnysmer;
      Komu.Smer := nahodnysmer;
    end;
  end;
end;

procedure TNepriatel.Posun(Koho: TNpc);
begin
  case Koho.Smer of  //podla smeru zmenime suradnice nepriatela
    1: Koho.Y := Koho.Y - 1;
    2: Koho.Y := Koho.Y + 1;
    3: Koho.X := Koho.X - 1;
    4: Koho.X := Koho.X + 1;
  end;
end;

procedure TNepriatel.OverVybuch(Okolie: TSteny);
var
  i: integer;
begin
  for i := 0 to length(NPC) - 1 do
    //pre vsetkych nepriatelov overi ci nezabilo ich vybuch
    if (Okolie.Steny[NPC[i].Y div pixel - 2][NPC[i].X div pixel - 2].Typ = 3) then
    begin
      NPC[i].Zomrel := True;
      ;   //ak ano tak zomrel
      NPC[i].Sekunda := 500;
    end;
end;

procedure TNepriatel.Nacitaj(S: string);
var
  Sub: TextFile;
  X, Y, Typ: integer;
begin
  if fileexists(S + '.txt') then //overenie ci existuje ten subor
  begin
    AssignFile(Sub, S + '.txt'); //zadefinujeme a otvorime subor
    Reset(Sub);
    Readln(Sub, Y);
    repeat
      readln(Sub);
      Dec(Y);
    until Y = -2; //prejdeme cez subor pokial nenajdeme informacie o nepriateloch v subore
    repeat
      Read(Sub, X);
      Read(Sub, Y);
      Readln(Sub, Typ);
      Pridaj(X, Y, Typ);
    until EOF(Sub);  //nacitavame nepriatelov pokial nie je koniec suboru
    CloseFile(Sub);
  end;
end;

function TNepriatel.OverPosun(Komu: TNpc; Okolie: TSteny): boolean;
begin
  Result := False;
  case Komu.Smer of //podla smeru
    0: Result := True; //ak stoji tak nema ziadnu barieru kam by nemohol ist
    1: //hore
    begin
      if ((Komu.Y div pixel - 1 - 2) < 0) then   //ak by chcel ist za okraje mapy
        exit;
      if (Okolie.Steny[Komu.Y div pixel - 1 - 2][Komu.X div pixel - 2].Typ = 0) then
        //ak am volne policko kam moze ist
        Result := True;
    end;
    //opakuje sa
    2:  //dole
    begin
      if ((Komu.Y div pixel + 1 - 2) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Komu.Y div pixel + 1 - 2][Komu.X div pixel - 2].Typ = 0) then
        Result := True;
    end;
    3: //doprava
    begin
      if ((Komu.X div pixel - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Komu.Y div pixel - 2][Komu.X div pixel - 1 - 2].Typ = 0) then
        Result := True;
    end;
    4:  //dolava
    begin
      if ((Komu.X div pixel + 1 - 2) >
        Length(Okolie.Steny[Komu.Y div pixel - 2]) - 1) then
        exit;
      if (Okolie.Steny[Komu.Y div pixel - 2][Komu.X div pixel + 1 - 2].Typ = 0) then
        Result := True;
    end;
  end;
end;

{ TNpc }

constructor TNpc.Create(XX, YY, TypNPC: integer);
begin
  Zomrel := False;
  X := (XX + 1) * pixel + 17;  //pridavame nepriatelov do policok
  Y := (YY + 1) * pixel + 17;
  Typ := TypNPC; //aky typ npc to je
  Smer := 0; //defaulny smer statia
  PohybujeSa := False; //nepohybuje sa
  Faza := 100;  //animacia nepriatela
  Sekunda := 1000;  //cas pohybu
end;

end.
