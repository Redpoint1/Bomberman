unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type

  { TStena }

  TStena = class
    X, Y, Typ, Faza, BombaSmer: integer;
    Obraz : TBitmap;
    Farba: TColor;
    constructor Create(XX, YY, TypSteny: integer);
  end;

  { TSteny }

  TSteny = class
    Steny: array of array of TStena;
    StenyObr: array[0..4] of TBitMap;
    BombyObr: array[0..4] of array[0..6] of TBitMap;
    procedure ZmenFarbu(X, Y: integer; Farby: TColor);
    procedure Vykresli(Obr: TCanvas);
    procedure ZmenFazu;
    procedure VykresliFazu;
    procedure Nacitaj(Subor: string; Vyska, Sirka: integer);
    procedure PriradObraz;
    constructor Create();
  end;

implementation

{ TSteny }

procedure TSteny.ZmenFarbu(X, Y: integer; Farby: TColor);
begin
  Steny[X][Y].Farba := Farby;
end;

procedure TSteny.Vykresli(Obr: TCanvas);
var
  i, j: integer;
begin
  for i := 0 to length(Steny) - 1 do
    for j := 0 to length(Steny[i]) - 1 do
      Obr.Draw(Steny[i][j].X - 17, Steny[i][j].Y - 17, Steny[i][j].Obraz);
  VykresliFazu;
end;

procedure TSteny.ZmenFazu;
var
  xokolie, yokolie: integer;
begin
  for yokolie := 0 to length(Steny) - 1 do
    for xokolie := 0 to length(Steny[yokolie]) - 1 do
      if ((Steny[yokolie][xokolie].Typ = 3) and (Steny[yokolie][xokolie].Faza = 0)) then
      begin
        Steny[yokolie][xokolie].Typ := 0;
        Steny[yokolie][xokolie].Obraz := StenyObr[0];
        Steny[yokolie][xokolie].BombaSmer:= 0;
        Steny[yokolie][xokolie].Faza := Steny[yokolie][xokolie].Faza - 1;
      end
      else if (Steny[yokolie][xokolie].Faza > 0) then
      begin
        Steny[yokolie][xokolie].Faza := Steny[yokolie][xokolie].Faza - 10;
      end;
end;

procedure TSteny.VykresliFazu;
var
  i, j: integer;
begin
  ZmenFazu;
  for i := 0 to length(Steny) - 1 do
    for j := 0 to length(Steny[i]) - 1 do
    begin
      if (Steny[i][j].Typ = 3) then
      begin
        case (Steny[i][j].Faza div 100) of
          4: Steny[i][j].Obraz := BombyObr[0][Steny[i][j].BombaSmer];
          3: Steny[i][j].Obraz := BombyObr[1][Steny[i][j].BombaSmer];
          2: Steny[i][j].Obraz := BombyObr[2][Steny[i][j].BombaSmer];
          1: Steny[i][j].Obraz := BombyObr[3][Steny[i][j].BombaSmer];
          0: Steny[i][j].Obraz := BombyObr[4][Steny[i][j].BombaSmer];
        end;
      end;
    end;
end;

procedure TSteny.Nacitaj(Subor: string; Vyska, Sirka: integer);
var
  t, x, y: integer;
  Sub: TextFile;
begin
  if fileexists(Subor + '.txt') then
  begin
    AssignFile(Sub, Subor + '.txt');
    Reset(Sub);
    Read(Sub, Y);
    Readln(Sub, X);
    Readln(Sub);
    repeat
      begin
        if (Length(Steny) <= ((Vyska div 33) - 5)) then
        begin
          SetLength(Steny, Length(Steny) + 1);
          repeat
            begin
              Read(Sub, t);
              if (Length(Steny[high(Steny)]) <= ((Sirka div 33) - 8)) then
              begin
                SetLength(Steny[high(Steny)], Length(Steny[high(Steny)]) + 1);
                Steny[high(Steny)][high(Steny[high(Steny)])] := TStena.Create(high(Steny[high(Steny)]) * 33 + 17 + 2 * 33, high(Steny) * 33 + 17 + 2 * 33, t);
                case t of
                  0: ZmenFarbu(high(Steny), high(Steny[high(Steny)]), clWhite);
                  1: ZmenFarbu(high(Steny), high(Steny[high(Steny)]), clRed);
                  2: ZmenFarbu(high(Steny), high(Steny[high(Steny)]), clBlue);
                  4: ZmenFarbu(high(Steny), high(Steny[high(Steny)]), clGreen);
                end;
              end;
            end;
          until Length(Steny[high(Steny)]) = X;
        end;
        readln(Sub);
      end;
    until Length(Steny) = Y;
    CloseFile(Sub);
  end;
  PriradObraz;
end;

procedure TSteny.PriradObraz;
var
  i,j : integer;
begin
for i:=0 to length(Steny)-1 do
    for j:=0 to length(Steny[i])-1 do
    begin
      if ((Steny[i][j].Typ < 2) or (Steny[i][j].Typ = 4)) then
         Steny[i][j].Obraz := StenyObr[Steny[i][j].Typ];
    end;
end;

constructor TSteny.Create;
var
  Obrazok : TBitMap;
  i, j: integer;
begin
  SetLength(Steny, 0);
  Obrazok := TBitmap.Create;
  Obrazok.LoadFromFile('img/steny.bmp');
  for i := 0 to length(StenyObr)-1 do
  begin
      StenyObr[i] := TBitmap.Create;
      StenyObr[i].Width := 33;
      StenyObr[i].Height := 33;
      StenyObr[i].Transparent := True;
      StenyObr[i].TransparentColor:= clFuchsia;
      StenyObr[i].PixelFormat := pf24bit;
      StenyObr[i].Canvas.Draw(-i*33, -0, Obrazok);
  end;
  Obrazok.LoadFromFile('img/bomba.bmp');
  for i := 0 to 4 do
    for j := 0 to 6 do
    begin
      BombyObr[i][j] := TBitmap.Create;
      BombyObr[i][j].Width := 33;
      BombyObr[i][j].Height := 33;
      BombyObr[i][j].Transparent := True;
      BombyObr[i][j].TransparentColor := clFuchsia;
      BombyObr[i][j].PixelFormat := pf24bit;
      BombyObr[i][j].Canvas.Draw(-j * 33, (-i-1) * 33, Obrazok);
    end;
  Obrazok.Free;
end;

{ TStena }

constructor TStena.Create(XX, YY, TypSteny: integer);
begin
  X := XX;
  Y := YY;
  Faza := 0;
  Typ := TypSteny;
  BombaSmer := 0;
end;

end.
