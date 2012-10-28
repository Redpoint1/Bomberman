unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game, npc;

type

  { Player }

  { TBomba }

  TBomba = class
    X, Y, Sekund, Radius, Faza: integer;
    Obr: array[0..1] of TBitmap;
    constructor Create(XX, YY, Sec, Rad: integer);
    procedure Odpocitavaj(Cas: integer);
    function OverStenu(Walle: TSteny; PosY, PosX, Smer: integer): boolean;
  end;

  { TPlayer }

  TPlayer = class
    Zivot, X, Y, SpawnX, SpawnY, Smer, Faza: integer;
    Farba: TColor;
    PohybujeSa: boolean;
    Bomby: array of TBomba;
    BombyObr: array[0..3] of TBitMap;
    HracObr: array[0..3] of array[0..2] of TBitMap;
    procedure Posun(klaves: integer);
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel: TNepriatel;
      Cas: TTimer);
    procedure VykresliBombu(Obr: TCanvas; Walli: TSteny);
    procedure ZmazBomby;
    procedure ZmazNilBomby;
    function OverNpc(Nepriatel: TNepriatel): boolean;
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
  Faza := 0;
end;

procedure TBomba.Odpocitavaj(Cas: integer);
begin
  Sekund := Sekund - cas;
end;

function TBomba.OverStenu(Walle: TSteny; PosY, PosX, Smer: integer): boolean;
begin
  Result := False;
  if ((PosX < 0) or (PosY < 0) or (PosY >= length(Walle.Steny)) or
    (PosX >= length(Walle.Steny[PosY]))) then
    exit;
  if (Walle.Steny[PosY][PosX].Typ = 4) then
  begin
    Walle.Steny[PosY][PosX].Typ := 0;
    Walle.Steny[PosY][PosX].Obraz := Walle.StenyObr[0];
    Result := False;
    exit;
  end;
  if (Walle.Steny[PosY][PosX].Typ = 0) then
  begin
    Walle.Steny[PosY][PosX].Typ := 3;
    Walle.Steny[PosY][PosX].Faza := 500;
    Result := True;
    case Smer of
      0:
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][4];
        Walle.Steny[PosY][PosX].BombaSmer := 4;
      end;
      1:
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][4];
        Walle.Steny[PosY][PosX].BombaSmer := 4;
      end;
      2:
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][1];
        Walle.Steny[PosY][PosX].BombaSmer := 1;
      end;
      3:
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][1];
        Walle.Steny[PosY][PosX].BombaSmer := 1;
      end;
    end;
  end
  else if (Walle.Steny[PosY][PosX].Typ = 3) then
  begin
    Walle.Steny[PosY][PosX].Faza := 500;
    Result := True;
  end;
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

procedure TPlayer.Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel: TNepriatel;
  Cas: TTimer);
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
  Obr.Draw(X - 17, Y - 17, HracObr[1][0]);
end;

procedure TPlayer.VykresliBombu(Obr: TCanvas; Walli: TSteny);
var
  i, j: integer;
begin
  for j := 0 to length(Bomby) - 1 do
  begin
    Bomby[j].Odpocitavaj(10);
    Bomby[j].Faza := (Bomby[j].Sekund div 500) mod 2;
    if (Bomby[j].Sekund >= 0) then
      Obr.Draw(Bomby[j].x - 17, Bomby[j].y - 17, BombyObr[Bomby[j].Faza])
    else
    begin
      Walli.Steny[Bomby[j].y div 33 - 2][Bomby[j].x div 33 - 2].Typ := 0;
      for i := (Bomby[j].x div 33) downto (Bomby[j].x div 33 - Bomby[j].radius) do
        //dolava
      begin
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div 33 - 2, i - 2, 2)) then
        begin
          if (i = (Bomby[j].x div 33 - Bomby[j].radius)) then
          begin
            Walli.Steny[Bomby[j].y div 33 - 2][i - 2].Obraz := Walli.BombyObr[0][0];
            Walli.Steny[Bomby[j].y div 33 - 2][i - 2].BombaSmer := 0;
          end;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].x div 33) to (Bomby[j].x div 33 + Bomby[j].radius) do //doprava
      begin
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div 33 - 2, i - 2, 3)) then
        begin
          if (i = (Bomby[j].x div 33 + Bomby[j].radius)) then
          begin
            Walli.Steny[Bomby[j].y div 33 - 2][i - 2].Obraz := Walli.BombyObr[0][3];
            Walli.Steny[Bomby[j].y div 33 - 2][i - 2].BombaSmer := 3;
          end;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div 33) to (Bomby[j].y div 33 + Bomby[j].radius) do //dole
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div 33 - 2, 1)) then
        begin
          if (i = (Bomby[j].y div 33 + Bomby[j].radius)) then
          begin
            Walli.Steny[i - 2][Bomby[j].x div 33 - 2].Obraz := Walli.BombyObr[0][6];
            Walli.Steny[i - 2][Bomby[j].x div 33 - 2].BombaSmer := 6;
          end;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div 33) downto (Bomby[j].y div 33 - Bomby[j].radius) do
        //hore
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div 33 - 2, 0)) then
        begin
          if (i = (Bomby[j].y div 33 - Bomby[j].radius)) then
          begin
            Walli.Steny[i - 2][Bomby[j].x div 33 - 2].Obraz := Walli.BombyObr[0][5];
            Walli.Steny[i - 2][Bomby[j].x div 33 - 2].BombaSmer := 5;
          end;
        end
        else
        begin
          break;
        end;
      end;
      Walli.Steny[Bomby[j].y div 33 - 2][Bomby[j].x div 33 - 2].Obraz :=
        Walli.BombyObr[0][2];
      Walli.Steny[Bomby[j].y div 33 - 2][Bomby[j].x div 33 - 2].BombaSmer := 2;
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

function TPlayer.OverNpc(Nepriatel: TNepriatel): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to length(Nepriatel.NPC) - 1 do
    if (sqrt(((X - Nepriatel.NPC[i].X) * (X - Nepriatel.NPC[i].X)) +
      ((Y - Nepriatel.NPC[i].Y) * (Y - Nepriatel.NPC[i].Y))) < 25) then
    begin
      Result := True;
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
var
  Obrazok: TBitMap;
  i, j: integer;
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
  Obrazok := TBitmap.Create;
  Obrazok.LoadFromFile('img/bomba.bmp');
  for i := 0 to 1 do
  begin
    BombyObr[i] := TBitmap.Create;
    BombyObr[i].Width := 33;
    BombyObr[i].Height := 33;
    BombyObr[i].Transparent := True;
    BombyObr[i].TransparentColor := clFuchsia;
    BombyObr[i].PixelFormat := pf24bit;
    BombyObr[i].Canvas.Draw(-i * 33, -0, Obrazok);
  end;
  Obrazok.LoadFromFile('img/player.bmp');
  for j := 0 to 3 do
    for i := 0 to 1 do
    begin
      HracObr[j][i] := TBitmap.Create;
      HracObr[j][i].Width := 33;
      HracObr[j][i].Height := 33;
      HracObr[j][i].Transparent := True;
      HracObr[j][i].TransparentColor := Obrazok.Canvas.Pixels[0,0];
      HracObr[j][i].PixelFormat := pf24bit;
      HracObr[j][i].Canvas.Draw(-i * 33, -j * 33, Obrazok);
    end;
  Obrazok.Free;
end;

end.
