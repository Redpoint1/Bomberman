unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game, npc;

type

  { Player }

  { TBomba }

  TBomba = class
    X, Y, Sekund, Radius: integer;
    constructor Create(XX, YY, Sec, Rad: integer);
    procedure Odpocitavaj(Cas: integer);
    function OverStenu(Walle: TSteny; PosY, PosX: integer): boolean;
  end;

  { TPlayer }

  TPlayer = class
    Zivot, X, Y, SpawnX, SpawnY, Smer: integer;
    Farba: TColor;
    PohybujeSa: boolean;
    Bomby: array of TBomba;
    procedure Posun(klaves: integer);
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel : TNepriatel; Cas: TTimer);
    procedure VykresliBombu(Obr: TCanvas; Walli: TSteny);
    procedure ZmazBomby;
    procedure ZmazNilBomby;
    function OverNpc(Nepriatel : TNepriatel): boolean;
    function OverPosun(Okolie: TSteny): boolean;
    function OverVybuch(Okolie: TSteny): boolean;
    constructor Create(XX, YY: integer);
  end;


implementation

{ TBomba }

constructor TBomba.Create(XX, YY, Sec, Rad: integer);
begin
  X := XX;
  Y := YY;
  Sekund := Sec * 1000;
  Radius := Rad;
end;

procedure TBomba.Odpocitavaj(Cas: integer);
begin
  Sekund := Sekund - cas;
end;

function TBomba.OverStenu(Walle: TSteny; PosY, PosX: integer): boolean;
begin
  Result := False;
  if ((PosX < 0) or (PosY < 0) or (PosY >= length(Walle.Steny)) or
    (PosX >= length(Walle.Steny[PosY]))) then
    exit;
  if (Walle.Steny[PosY][PosX].Typ = 4) then
  begin
    Walle.Steny[PosY][PosX].Typ := 3;
    Walle.Steny[PosY][PosX].Faza := 500;
    Result := False;
    exit;
  end;
  if (Walle.Steny[PosY][PosX].Typ = 0) then
  begin
    Walle.Steny[PosY][PosX].Typ := 3;
    Walle.Steny[PosY][PosX].Faza := 500;
    Result := True;
  end
  else if (Walle.Steny[PosY][PosX].Typ = 3) then
    Result := True;
end;

{ Player }

procedure TPlayer.Posun(klaves: integer);
begin
  case klaves of
    0: Y := Y - 1;
    1: Y := Y + 1;
    2: X := X - 1;
    3: X := X + 1;
  end;
end;

procedure TPlayer.Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel : TNepriatel; Cas: TTimer);
begin
  if ((OverVybuch(Okolie)) or (OverNpc(Nepriatel))) then
  begin
    if (Cas.Enabled) then
    begin
      Cas.Enabled := False;
      PohybujeSa := False;
    end;
    X := SpawnX;
    Y := SpawnY;
    Zivot := Zivot - 1;
  end;
  Obr.Brush.Color := Farba;
  Obr.Pen.Color := Farba;
  Obr.Rectangle(X - 17, Y - 17, X + 16, Y + 16);
end;

procedure TPlayer.VykresliBombu(Obr: TCanvas; Walli: TSteny);
var
  i, j: integer;
begin
  Obr.Brush.Color := clBlue;
  Obr.Pen.Color := clBlue;
  for j := 0 to length(Bomby) - 1 do
  begin
    Bomby[j].Odpocitavaj(10);
    if (Bomby[j].Sekund >= 0) then
      Obr.Rectangle(Bomby[j].x - 17, Bomby[j].y - 17, Bomby[j].x + 16, Bomby[j].y + 16)
    else
    begin
      Walli.Steny[Bomby[j].y div 33 - 2][Bomby[j].x div 33 - 2].Typ := 0;
      for i := (Bomby[j].x div 33) downto (Bomby[j].x div 33 - Bomby[j].radius) do
      begin
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div 33 - 2, i - 2)) then
          Obr.Rectangle(i * 33, Bomby[j].y - 17, (i + 1) * 33, Bomby[j].y + 16)
        else
          break;
      end;
      for i := (Bomby[j].x div 33) to (Bomby[j].x div 33 + Bomby[j].radius) do
      begin
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div 33 - 2, i - 2)) then
          Obr.Rectangle(i * 33, Bomby[j].y - 17, (i + 1) * 33, Bomby[j].y + 16)
        else
          break;
      end;
      for i := (Bomby[j].y div 33) to (Bomby[j].y div 33 + Bomby[j].radius) do
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div 33 - 2)) then
          Obr.Rectangle(Bomby[j].x - 17, i * 33, Bomby[j].x + 16, (i + 1) * 33)
        else
          break;
      end;
      for i := (Bomby[j].y div 33) downto (Bomby[j].y div 33 - Bomby[j].radius) do
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div 33 - 2)) then
          Obr.Rectangle(Bomby[j].x - 17, i * 33, Bomby[j].x + 16, (i + 1) * 33)
        else
          break;
      end;
    end;
  end;
  ZmazBomby;
end;

procedure TPlayer.ZmazBomby;
var
  i: integer;
begin
  for i := 0 to length(Bomby) - 1 do
    if (Bomby[i].Sekund < 0) then
      FreeAndNil(Bomby[i]);
  ZmazNilBomby;
end;

procedure TPlayer.ZmazNilBomby;
var
  i, velkost: integer;
begin
  velkost := 0;
  for i := 0 to length(Bomby) - 1 do
    if (Bomby[i] = nil) then
    begin
      Bomby[i] := Bomby[high(Bomby) - velkost];
      Inc(velkost);
    end;
  setlength(Bomby, length(Bomby) - velkost);
end;

function TPlayer.OverNpc(Nepriatel: TNepriatel) : boolean;
var
  i: integer;
begin
     result := false;
     for i:=0 to length(Nepriatel.NPC)-1 do
         if (sqrt(((X - Nepriatel.NPC[i].X)*(X - Nepriatel.NPC[i].X)) + ((Y - Nepriatel.NPC[i].Y)*(Y - Nepriatel.NPC[i].Y))) < 25 ) then
         begin
           result := true;
           exit;
         end;
end;

function TPlayer.OverPosun(Okolie: TSteny): boolean;
begin
  Result := False;
  case Smer of
    0:
    begin
      if ((Y div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Y div 33 - 1 - 2][X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    1:
    begin
      if ((Y div 33 + 1 - 2) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Y div 33 + 1 - 2][X div 33 - 2].Typ = 0) then
        Result := True;
    end;
    2:
    begin
      if ((X div 33 - 1 - 2) < 0) then
        exit;
      if (Okolie.Steny[Y div 33 - 2][X div 33 - 1 - 2].Typ = 0) then
        Result := True;
    end;
    3:
    begin
      if ((X div 33 + 1 - 2) > Length(Okolie.Steny[Y div 33 - 2]) - 1) then
        exit;
      if (Okolie.Steny[Y div 33 - 2][X div 33 + 1 - 2].Typ = 0) then
        Result := True;
    end;
  end;
end;

function TPlayer.OverVybuch(Okolie: TSteny): boolean;
begin
  Result := False;
  if (Okolie.Steny[Y div 33 - 2][X div 33 - 2].Typ = 3) then
    Result := True;
end;

constructor TPlayer.Create(XX, YY: integer);
begin
  Zivot := 3;
  X := XX;
  Y := YY;
  SpawnX := XX;
  SpawnY := YY;
  Farba := clBlack;
  PohybujeSa := False;
  Smer := -1;
  setlength(Bomby, 0);
end;

end.
