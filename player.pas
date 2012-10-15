unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game;

type

    { Player }

    { TPlayer }

    TPlayer = class
      Zivot, X, Y, SpawnX, SpawnY, Smer : Integer;
      Farba: TColor;
      PohybujeSa : boolean;
      procedure Posun(klaves: Integer);
      procedure Vykresli(Obr: TCanvas; Okolie : TSteny; Cas : TTimer);
      function OverPosun(klavesnica: Integer; Okolie: TSteny): Boolean;
      function OverVybuch(Okolie: TSteny): Boolean;
      constructor Create(XX,YY : Integer);
    end;

    { TBomba }

    TBomba = class
      X,Y, Sekund, Radius : Integer;
      Farba: TColor;
      constructor Create(XX,YY, Sec, Rad : integer);
      procedure Odpocitavaj(Cas : integer);
      procedure Vykresli(Obr : TCanvas; Walli: TSteny);
      function OverStenu(Walle : TSteny; PosX, PosY: integer): boolean;
    end;


implementation

{ TBomba }

constructor TBomba.Create(XX, YY, Sec, Rad: integer);
begin
  X := XX;
  Y := YY;
  Sekund := Sec*1000;
  Farba := clBlue;
  Radius := Rad;
end;

procedure TBomba.Odpocitavaj(Cas: integer);
begin
    Sekund := Sekund - cas;
end;

procedure TBomba.Vykresli(Obr : TCanvas; Walli : TSteny);
var
  i: integer;
begin
  Obr.Brush.Color := Farba;
  Obr.Pen.Color := Farba;
  Odpocitavaj(50);
  if (Sekund >= 0) then
    Obr.Rectangle(x-17,y-17,x+16,y+16)
  else
  begin
    for i:=(x div 33 - radius) to (x div 33) do
    begin
      if (OverStenu(Walli, i-2, y div 33 - 2)) then
         Obr.Rectangle(i*33,y-17,(i+1)*33,y+16)
      else
          break;
    end;
    for i:=(x div 33) to (x div 33 + radius) do
    begin
      if (OverStenu(Walli, i-2, y div 33 - 2)) then
      begin
         Obr.Rectangle(i*33,y-17,(i+1)*33,y+16);
      end
      else
          break;
    end;
    for i:=(y div 33) to (y div 33 + radius) do
    begin
      if (OverStenu(Walli, x div 33 - 2, i-2)) then
         Obr.Rectangle(x-17,i*33,x+16,(i+1)*33)
      else
          break;
    end;
    for i:=(y div 33 - radius) to (y div 33) do
    begin
      if (OverStenu(Walli, x div 33 -2, i-2)) then
         Obr.Rectangle(x-17,i*33,x+16,(i+1)*33)
      else
          break;
    end;
  end;
end;

function TBomba.OverStenu(Walle: TSteny; PosX, PosY: integer): boolean;
begin
  result := false;
  if ((PosX < 0) or (PosY < 0) or (PosX >= length(Walle.Steny)) or (PosY >= length(Walle.Steny[PosX]))) then
     exit;
  if (Walle.Steny[PosX][PosY].Typ = 0) then
  begin
       Walle.Steny[PosX][PosY].Typ := 3;
       result := true;
  end
  else if (Walle.Steny[PosX][PosY].Typ = 3) then
       result := true;
end;

{ Player }

procedure TPlayer.Posun(klaves: Integer);
begin
    case klaves of
         0: Y := Y-1;
         1: Y := Y+1;
         2: X := X-1;
         3: X := X+1;
    end;
end;

procedure TPlayer.Vykresli(Obr: TCanvas; Okolie : TSteny; Cas : TTimer);
begin
    if (OverVybuch(Okolie)) then
    begin
         if (Cas.Enabled) then
         begin
            Cas.Enabled := false;
            PohybujeSa := false;
         end;
         X := SpawnX;
         Y := SpawnY;
         Zivot := Zivot -1;
    end;
    Obr.Brush.Color := Farba;
    Obr.Pen.Color := Farba;
    Obr.Rectangle(X-17,Y-17,X+16,Y+16);
end;

function TPlayer.OverPosun(klavesnica: Integer; Okolie: TSteny): boolean;
begin
  result := false;
  case klavesnica of
       0:
         begin
              if ((Y div 33 - 1 - 2) < 0) then exit;
              if (Okolie.Steny[X div 33 - 2][Y div 33 - 1 - 2].Typ = 0) then
                 result := true;
         end;
       1:
         begin
              if ((Y div 33 + 1 - 2) > Length(Okolie.Steny[X div 33 - 2])-1) then exit;
              if (Okolie.Steny[X div 33 - 2][Y div 33 + 1 - 2].Typ = 0) then
                 result := true;
         end;
       2:
         begin
              if ((X div 33 - 1 - 2) < 0) then exit;
              if (Okolie.Steny[X div 33 - 1 - 2][Y div 33 - 2].Typ = 0) then
                 result := true;
         end;
       3:
         begin
              if ((X div 33 + 1 - 2) > Length(Okolie.Steny)-1) then exit;
              if (Okolie.Steny[X div 33 + 1 - 2][Y div 33 - 2].Typ = 0) then
                 result := true;
         end;
  end;
end;

function TPlayer.OverVybuch(Okolie: TSteny): Boolean;
begin
  result := false;
  if (Okolie.Steny[X div 33 - 2][Y div 33 -2].Typ = 3) then
     result := true;
end;

constructor TPlayer.Create(XX,YY : Integer);
begin
  Zivot := 3;
  X := XX;
  Y := YY;
  SpawnX := XX;
  SpawnY := YY;
  Farba := clBlack;
  PohybujeSa := false;
  Smer := -1;
end;

end.

