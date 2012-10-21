unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type

  { TStena }

  TStena = class
    X, Y, Typ, Faza: integer;
    Farba: TColor;
    constructor Create(XX, YY, TypSteny: integer);
  end;

  { TSteny }

  TSteny = class
    Steny: array of array of TStena;
    procedure ZmenFarbu(X, Y: integer; Farby: TColor);
    procedure Vykresli(Obr: TCanvas);
    procedure ZmenFazu;
    procedure VykresliFazu;
    procedure Nacitaj(Subor: string; Vyska, Sirka: integer);
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
  ZmenFazu;
  VykresliFazu;
  for i := 0 to length(Steny) - 1 do
    for j := 0 to length(Steny[i]) - 1 do
    begin
      Obr.Pen.Color := Steny[i][j].Farba;
      Obr.Brush.Color := Steny[i][j].Farba;
      Obr.Rectangle(Steny[i][j].X - 17, Steny[i][j].Y - 17, Steny[i][j].X + 16,
        Steny[i][j].Y + 16);
    end;
end;

procedure TSteny.ZmenFazu;
var
  xokolie, yokolie: integer;
begin
  for xokolie := 0 to length(Steny) - 1 do
    for yokolie := 0 to length(Steny[xokolie]) - 1 do
      if (((Steny[xokolie][yokolie].Typ = 3) or
        (Steny[xokolie][yokolie].Typ = 2)) and (Steny[xokolie][yokolie].Faza = 0)) then
      begin
        Steny[xokolie][yokolie].Typ := 0;
        Steny[xokolie][yokolie].Farba := clWhite;
        Steny[xokolie][yokolie].Faza := Steny[xokolie][yokolie].Faza - 1;
      end
      else if (Steny[xokolie][yokolie].Faza > 0) then
      begin
        Steny[xokolie][yokolie].Faza := Steny[xokolie][yokolie].Faza - 10;
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
          4: Steny[i][j].Farba := RGBToColor(1 * 42, 1 * 42, 1 * 42);
          3: Steny[i][j].Farba := RGBToColor(2 * 42, 2 * 42, 2 * 42);
          2: Steny[i][j].Farba := RGBToColor(3 * 42, 3 * 42, 3 * 42);
          1: Steny[i][j].Farba := RGBToColor(4 * 42, 4 * 42, 4 * 42);
          0: Steny[i][j].Farba := RGBToColor(5 * 42, 5 * 42, 5 * 42);
        end;
      end;
    end;
end;

procedure TSteny.Nacitaj(Subor: string; Vyska, Sirka: integer);
var
  t: integer;
  Sub: TextFile;
begin
  if fileexists(Subor + '.txt') then
  begin
    AssignFile(Sub, Subor + '.txt');
    Reset(Sub);
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
          until EoLn(Sub);
        end;
        readln(Sub);
      end;
    until EOF(Sub);
    CloseFile(Sub);
  end;
end;

constructor TSteny.Create;
begin
  SetLength(Steny, 0);
end;

{ TStena }

constructor TStena.Create(XX, YY, TypSteny: integer);
begin
  X := XX;
  Y := YY;
  Faza := 0;
  Typ := TypSteny;
end;

end.
