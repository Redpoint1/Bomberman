unit npc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game;

type

  { TNpc }

  TNpc = class
    X, Y, Smer, Faza, Typ, Sekunda: integer;
    PohybujeSa: boolean;
    Farba: TColor;
    constructor Create(XX, YY, TypNPC: integer);
  end;

  { TNepriatel }

  TNepriatel = class
    NPC: array of TNpc;
    procedure Pridaj(XX, YY, Typ: integer);
    procedure vymazNilNpc;
    constructor Create();
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny);
    procedure Casovac;
    procedure PohybujSa(Kto: TNpc; Okolie: TSteny);
    procedure VyberSmer(Komu: TNpc);
    procedure Posun(Koho: TNpc);
    procedure OverVybuch(Okolie: TSteny);
    function OverPosun(Komu: TNpc; Okolie: TSteny): boolean;
  end;

implementation

{ TNepriatel }

procedure TNepriatel.Pridaj(XX, YY, Typ: integer);
begin
  setLength(NPC, length(NPC) + 1);
  NPC[high(NPC)] := TNpc.Create(XX, YY, Typ);
end;

procedure TNepriatel.vymazNilNpc;
var
  i, j: integer;
begin
  j := 0;
  for i := 0 to length(NPC) - 1 do
    if (NPC[i] = nil) then
    begin
      NPC[i] := NPC[high(NPC) - j];
      Inc(j);
    end;
  SetLength(NPC, length(NPC) - j);
end;

constructor TNepriatel.Create;
begin
  setLength(NPC, 0);
end;

procedure TNepriatel.Vykresli(Obr: TCanvas; Okolie: TSteny);
var
  i: integer;
begin
  OverVybuch(Okolie);
  VymazNilNpc;
  for i := 0 to length(NPC) - 1 do
  begin
    PohybujSa(NPC[i], Okolie);
    Obr.Brush.Color := NPC[i].Farba;
    Obr.Pen.Color := NPC[i].Farba;
    Obr.Rectangle(NPC[i].X - 17, NPC[i].Y - 17, NPC[i].X + 16, NPC[i].Y + 16);
  end;
end;

procedure TNepriatel.Casovac;
var
  i: integer;
begin
  for i := 0 to length(NPC) - 1 do
  begin
    if (NPC[i].pohybujeSa) then
    begin
      Posun(NPC[i]);
      if (((NPC[i].X mod 33) = 17) and ((NPC[i].Y mod 33) = 17) and
        (NPC[i].Smer <> 0)) then
      begin
        NPC[i].PohybujeSa := False;
      end;
      if (((NPC[i].X mod 33) = 17) and ((NPC[i].Y mod 33) = 17) and
        (NPC[i].Smer = 0)) then
      begin
        if (NPC[i].Sekunda = 0) then
        begin
          NPC[i].PohybujeSa := False;
          NPC[i].Sekunda := 1000;
        end
        else
        begin
          NPC[i].Sekunda := NPC[i].Sekunda - 10;
        end;
      end;
    end;
  end;
end;

procedure TNepriatel.PohybujSa(Kto: TNpc; Okolie: TSteny);
begin
  VyberSmer(Kto);
  if (not (Kto.PohybujeSa)) then
    if (OverPosun(Kto, Okolie)) then
    begin
      Kto.PohybujeSa := True;
    end
    else
      Kto.PohybujeSa := False;
end;

procedure TNepriatel.VyberSmer(Komu: TNpc);
var
  nahodne, nahodnysmer: integer;
begin
  if (not (Komu.PohybujeSa)) then
  begin
    nahodne := random(10) + 1;
    if ((nahodne >= 8) and (nahodne < 10)) then
    begin
      repeat
        nahodnysmer := random(4) + 1;
      until Komu.Smer <> nahodnysmer;
      Komu.Smer := nahodnysmer;
    end;
    if (nahodne = 10) then
      Komu.Smer := 0;
    if ((Komu.Smer = 0) and (nahodne < 7)) then
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
  case Koho.Smer of
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
    if (Okolie.Steny[NPC[i].Y div 33 - 2][NPC[i].X div 33 - 2].Typ = 3) then
      FreeAndNil(NPC[i]);
end;

function TNepriatel.OverPosun(Komu: TNpc; Okolie: TSteny): boolean;
begin
  Result := False;
  case Komu.Smer of
    0: Result := True;
    1:
    begin
      if ((Komu.Y div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Komu.Y div 33 - 1 - 2][Komu.X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    2:
    begin
      if ((Komu.Y div 33 + 1 - 2) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Komu.Y div 33 + 1 - 2][Komu.X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    3:
    begin
      if ((Komu.X div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Komu.Y div 33 - 2][Komu.X div 33 - 1 - 2].Typ = 0) then
        Result := True;
    end;
    4:
    begin
      if ((Komu.X div 33 + 1 - 2) > Length(Okolie.Steny[Komu.Y div 33 - 2]) - 1) then
        exit;
      if (Okolie.Steny[Komu.Y div 33 - 2][Komu.X div 33 + 1 - 2].Typ = 0) then
        Result := True;
    end;
  end;
end;

{ TNpc }

constructor TNpc.Create(XX, YY, TypNPC: integer);
begin
  X := XX;
  Y := YY;
  Typ := TypNPC;
  Smer := 0;
  PohybujeSa := False;
  Farba := clLime;
  Sekunda := 1000;
end;

end.