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
    procedure VyberSmer;
    procedure Posun;
    procedure PohybujSa(Okolie: TSteny; Cas: TTimer);
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny; Cas: TTimer);
    function OverPosun(Okolie: TSteny): boolean;
  end;

implementation

{ TNpc }

constructor TNpc.Create(XX, YY, TypNPC: integer);
begin
  X := XX;
  Y := YY;
  Typ := TypNPC;
  Smer := random(5);
  PohybujeSa := true;
  Farba := clLime;
  Sekunda := 1000;
end;

procedure TNpc.VyberSmer;
var
  nahodne, nahodnysmer: integer;
begin
  if (not(PohybujeSa)) then
  begin
    nahodne := random(10) + 1;
    if ((nahodne >= 8) and (nahodne < 10)) then
    begin
      repeat
        nahodnysmer := random(4) + 1;
      until Smer <> nahodnysmer;
      Smer := nahodnysmer;
    end;
    if (nahodne = 10) then
      Smer := 0;
    if ((Smer = 0) and (nahodne < 7)) then
    begin
      repeat
        nahodnysmer := random(4) + 1;
      until Smer <> nahodnysmer;
      Smer := nahodnysmer;
    end;
  end;
end;

procedure TNpc.Posun;
begin
  case Smer of
    1: Y := Y - 1;
    2: Y := Y + 1;
    3: X := X - 1;
    4: X := X + 1;
  end;
end;

procedure TNpc.PohybujSa(Okolie: TSteny; Cas: TTimer);
begin
  VyberSmer;
  if (not(Cas.Enabled) and not(PohybujeSa)) then
    if (OverPosun(Okolie)) then
    begin
      PohybujeSa := True;
      Cas.Enabled := True;
    end
    else
      PohybujeSa := False;
end;

procedure TNpc.Vykresli(Obr: TCanvas; Okolie: TSteny; Cas: TTimer);
begin
  PohybujSa(Okolie, Cas);
  Obr.Brush.Color := Farba;
  Obr.Pen.Color := Farba;
  Obr.Rectangle(X - 17, Y - 17, X + 16, Y + 16);
end;

function TNpc.OverPosun(Okolie: TSteny): boolean;
begin
  Result := False;
  case Smer of
    0: Result := True;
    1:
    begin
      if ((Y div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Y div 33 - 1 - 2][X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    2:
    begin
      if ((Y div 33 + 1 - 2) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Y div 33 + 1 - 2][X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    3:
    begin
      if ((X div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Y div 33 - 2][X div 33 - 1 - 2].Typ = 0) then
        Result := True;
    end;
    4:
    begin
      if ((X div 33 + 1 - 2) > Length(Okolie.Steny[Y div 33 - 2]) - 1) then
        exit;
      if (Okolie.Steny[Y div 33 - 2][X div 33 + 1 - 2].Typ = 0) then
        Result := True;
    end;
  end;

end;

end.

