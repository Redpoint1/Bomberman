unit npc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game, share;

type

  { TNpc }

  TNpc = class  //trieda nepriatelov
    X, Y: real;
    Smer, Faza, Typ, Sekunda: integer;
    //suradnice, orientacia pohybu, animacia, typ nepriatela, cas statia
    Zomrel, PohybujeSa: boolean; //prave sa pohybuje
    constructor Create(XX, YY, TypNPC: integer);
    function GetX: integer; //real -> int
    function GetY: integer; //to iste
  end;

  { TNepriatel }

  TNepriatel = class  //trieda nepratelov (viacerych)
    Skore: integer; //celkovy pocet skore hraca ,ktore ziskal vybuchom
    NPC: array of TNpc; //pole objektov nepriatelov
    NpcObr: array[0..2] of array[0..2] of TBitMap; //obrazky nepriatelov
    procedure Pridaj(XX, YY, Typ: integer); //pridanie dalsieho nepriatela
    procedure vymazNilNpc; //vymazanie z pola nepratelov ktori boli zniceni
    constructor Create();
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny; Diff, XX, YY: integer);
    //vykreslenie nepriatelov na obrazok
    procedure Casovac(Diff: integer);  // odpocitavanie pohybu nepriatelov
    procedure PohybujSa(Kto: TNpc; Okolie: TSteny; Diff, XX, YY: integer);
    //procedura na pohyb nepriatelov
    procedure VyberSmer(Komu: TNpc); //vyberanie smeru kam sa bude pohybovat
    procedure Posun(Koho: TNpc; Diff: integer); //zmena suradnic nepriatela
    procedure OverVybuch(Okolie: TSteny); //overenie ci nepiratela zasiahol vybuch
    procedure Nacitaj(S: string);  //nacitanie zo suboru poziciu a typ nepriatela
    procedure PridajSkore(Nepriatel: TNPC); //pripocita skore podla typu nepriatela
    function vratSkore: integer; //vrati pocet skore
    function OverPosun(Komu: TNpc; Okolie: TSteny; Diff: integer): boolean;
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
    if ((NPC[i] <> nil) and (((NPC[i].Zomrel) and (NPC[i].Sekunda > 0)) or not
      (NPC[i].Zomrel))) then
      //ak nie je nil a zaroven zomrel ,ale beha animacka ,alebo nezomrel
    begin
      NPC[j] := NPC[i];
      Inc(j);
      //prehadzujeme nezaniknutycha na zaciatok pola
    end;
  SetLength(NPC, j); //pole nepriatelov zmensujeme o pocet nezaniknutych
end;

constructor TNepriatel.Create;
var
  Obrazok: TBitMap;
  i, j: integer;
begin
  setLength(NPC, 0);
  Obrazok := TBitMap.Create;
  Obrazok.LoadFromFile('img/npc.bmp');  //nacitanie obrazkov nepriatelov aj s animaciami
  for i := 0 to length(NpcObr) - 1 do
    for j := 0 to length(NpcObr[i]) - 1 do
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

procedure TNepriatel.Vykresli(Obr: TCanvas; Okolie: TSteny; Diff, XX, YY: integer);
var
  i: integer;
begin
  OverVybuch(Okolie); //pred vykreslovanim skontrolujeme ci ich nezasiahlo vybuch
  VymazNilNpc;   //zmazeme ktorych zasiahol vybuch
  for i := 0 to length(NPC) - 1 do
  begin
    if not (NPC[i].Zomrel) then  //ak nevybuchol
    begin
      PohybujSa(NPC[i], Okolie, Diff, XX, YY);
      //zmena pozicie pri pohybovani ,alebo priradenie dalsieho pohybu na ine policko
      Obr.Draw(NPC[i].GetX - 17, NPC[i].GetY - 17,
        NpcObr[NPC[i].Typ][NPC[i].Faza div 50]);
      //vykreslenie
    end
    else  //ak vybuchol
    begin
      Obr.Draw(NPC[i].GetX - 17, NPC[i].GetY - 17, NpcObr[NPC[i].Typ][2]);
      //zrob animaciu umrtia
      Dec(NPC[i].Sekunda, 10);
    end;
  end;
end;

procedure TNepriatel.Casovac(Diff: integer);
var
  i: integer;
begin
  for i := 0 to length(NPC) - 1 do //pre vsetkych nepriatelov z pola
  begin
    if ((NPC[i].pohybujeSa) and not (NPC[i].Zomrel)) then
      //ak sa prave pohybuje a nezomrel
    begin
      Posun(NPC[i], Diff); //zmenime poziciu
      if (((NPC[i].GetX mod pixel) = 17) and ((NPC[i].GetY mod pixel) = 17) and
        (NPC[i].Smer <> 0)) then  //ak doslo do stredu noveho policka
      begin
        NPC[i].PohybujeSa := False;  //skonci pohyb
      end;
      if (((NPC[i].GetX mod pixel) = 17) and ((NPC[i].GetY mod pixel) = 17) and
        (NPC[i].Smer = 0)) then  //ak je v strede policka a stoji
      begin
        if (NPC[i].Sekunda = 0) then //a uz skoncil pohyb "statia"
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

procedure TNepriatel.PohybujSa(Kto: TNpc; Okolie: TSteny; Diff, XX, YY: integer);
begin
  if (Kto.faza = 0) then //ak skoncila animacia
    Kto.Faza := 100; //zresetujeme animaciu
  Dec(Kto.Faza, 1);
  if (Kto.PohybujeSa) then //ak sa pohybuje nepokracuj
    exit;
  if ((diff = 0) or (((XX div pixel - Kto.GetX div pixel) <> 0) and
    ((YY div pixel - Kto.GetY div pixel) <> 0))) then
    VyberSmer(Kto)
  //ak hrac ma lahku uroven alebo sa hrac nenachadza s danym npc v rovnakej X a Y
  else
  begin
    if (((YY div pixel - Kto.GetY div pixel) = 0) and (XX > Kto.GetX) and
      (abs(XX - Kto.getX) <= NPCNasielHraca)) then
      //ak hrac je od neho napravo a registruje ho tak nasmeruj npc smerom doprava
      Kto.Smer := 4
    else if (((YY div pixel - Kto.GetY div pixel) = 0) and (XX < Kto.GetX) and
      (abs(XX - Kto.getX) <= NPCNasielHraca)) then //to iste iba dolava
      Kto.Smer := 3
    else if (((XX div pixel - Kto.GetX div pixel) = 0) and (YY > Kto.GetY) and
      (abs(YY - Kto.getY) <= NPCNasielHraca)) then ///to iste dole
      Kto.Smer := 2
    else if (((XX div pixel - Kto.GetX div pixel) = 0) and (YY < Kto.GetY) and
      (abs(YY - Kto.getY) <= NPCNasielHraca)) then  //to iste hore
      Kto.Smer := 1
    else if ((XX - Kto.GetX = 0) and (YY - Kto.GetY = 0)) then
      //ak su na rovnakom nech stoji
    begin
      Kto.Smer := 0;
      Kto.Sekunda := 1000;
    end
    else
      VyberSmer(Kto);
    //ak nesplna ani jedno z podmienok tak pokracuj ako na "lahkej" obtiaznosti
  end;
  if (OverPosun(Kto, Okolie, Diff)) then //ak sa nepohybuje a moze ist na dane policko
    Kto.PohybujeSa := True //zacne sa pohybovat
  else     //hod vyber smer este
    Kto.PohybujeSa := False; //ak nevi prejst na dalsie policko nepohne sa
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

procedure TNepriatel.Posun(Koho: TNpc; Diff: integer);
begin
  case Koho.Smer of  //podla smeru zmenime suradnice nepriatela a podla obtiaznosti hry
    1: Koho.Y := Koho.Y - NpcSpeed[Diff][Koho.Typ];
    2: Koho.Y := Koho.Y + NpcSpeed[Diff][Koho.Typ];
    3: Koho.X := Koho.X - NpcSpeed[Diff][Koho.Typ];
    4: Koho.X := Koho.X + NpcSpeed[Diff][Koho.Typ];
  end;
end;

procedure TNepriatel.OverVybuch(Okolie: TSteny);
var
  i: integer;
begin
  for i := 0 to length(NPC) - 1 do
    //pre vsetkych nepriatelov overi ci nezabilo ich vybuch
    if ((Okolie.Steny[NPC[i].GetY div pixel][NPC[i].GetX div pixel].Typ = 3) and
      not (NPC[i].Zomrel)) then
    begin
      NPC[i].Zomrel := True;  //ak ano tak zomrel
      NPC[i].Sekunda := 500; //cas animacie
      PridajSkore(NPC[i]); //pripocita hracovi skore
    end;
end;

procedure TNepriatel.Nacitaj(S: string);
var
  Sub: TFileStream;
  X, Y, Typ: integer;
begin
  if fileexists('mapy/' + S + '.dat') then //overenie ci existuje ten subor
  begin
    x := 0;
    y := 0;
    typ := 0;
    Sub := TFileStream.Create('mapy/' + S + '.dat', fmOpenRead);
    //zadefinujeme a otvorime subor
    Sub.ReadBuffer(Y, 4);
    Sub.ReadBuffer(X, 4);
    Sub.Position := (X * Y + 5) * 4;
    //preskocime na poziciu kde zacinaju informacie o nepriateloch na mape
    if (Sub.Size > Sub.Position) then //ak nejaky su
    begin
      repeat
        Sub.ReadBuffer(X, 4);
        Sub.ReadBuffer(Y, 4);
        Sub.ReadBuffer(Typ, 4);
        Pridaj(X, Y, Typ);
      until Sub.Position = Sub.Size;
      //nacitavame nepriatelov pokial nie je koniec suboru
    end;
    Sub.Free; //zatvorime subor
  end;
end;

procedure TNepriatel.PridajSkore(Nepriatel: TNPC);
begin
  Inc(Skore, SkoreZaNpc[Nepriatel.Typ]); //pridaj skore za dany typ npc
end;

function TNepriatel.vratSkore: integer;
begin
  Result := Skore; //vrati celkovy pocet skore (ziskanych vybuchom)
  Skore := 0; //zresetuj skore
end;

function TNepriatel.OverPosun(Komu: TNpc; Okolie: TSteny; Diff: integer): boolean;
begin
  Result := False;
  case Komu.Smer of //podla smeru
    0: Result := True; //ak stoji tak nema ziadnu barieru kam by nemohol ist
    1: //hore
    begin
      if ((Komu.GetY div pixel - 1) < 0) then   //ak by chcel ist za okraje mapy
        exit;
      if (Okolie.Steny[Komu.GetY div pixel - 1][Komu.GetX div pixel].Typ in
        NpcBloky[Diff][Komu.Typ]) then
        //ak moze ist do urcite typu policka
        Result := True;
    end;
    //opakuje sa
    2:  //dole
    begin
      if ((Komu.GetY div pixel + 1) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Komu.GetY div pixel + 1][Komu.GetX div pixel].Typ in
        NpcBloky[Diff][Komu.Typ]) then
        Result := True;
    end;
    3: //doprava
    begin
      if ((Komu.GetX div pixel - 1) < 0) then
        exit;
      if (Okolie.Steny[Komu.GetY div pixel][Komu.GetX div pixel - 1].Typ in
        NpcBloky[Diff][Komu.Typ]) then
        Result := True;
    end;
    4:  //dolava
    begin
      if ((Komu.GetX div pixel + 1) >
        Length(Okolie.Steny[Komu.GetY div pixel]) - 1) then
        exit;
      if (Okolie.Steny[Komu.GetY div pixel][Komu.GetX div pixel + 1].Typ in
        NpcBloky[Diff][Komu.Typ]) then
        Result := True;
    end;
  end;
end;

{ TNpc }

constructor TNpc.Create(XX, YY, TypNPC: integer);
begin
  Zomrel := False;
  X := (XX - 1) * pixel + 17;  //pridavame nepriatelov do policok
  Y := (YY - 1) * pixel + 17;
  Typ := TypNPC; //aky typ npc to je
  Smer := 0; //defaulny smer statia
  PohybujeSa := False; //nepohybuje sa
  Faza := 100;  //animacia nepriatela
  Sekunda := 1000;  //cas pohybu
end;

function TNpc.GetX: integer;
begin
  Result := Round(X);  //real -> int
end;

function TNpc.GetY: integer;
begin
  Result := Round(Y);
end;

end.
