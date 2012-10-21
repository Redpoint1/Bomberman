unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game;

type

    { Player }

    { TBomba }

    TBomba = class
      X,Y, Sekund, Radius : Integer;
      constructor Create(XX,YY, Sec, Rad : integer);
      procedure Odpocitavaj(Cas : integer);
      function OverStenu(Walle : TSteny; PosX, PosY: integer): boolean;
    end;

    { TPlayer }

    TPlayer = class
      Zivot, X, Y, SpawnX, SpawnY, Smer : Integer;
      Farba: TColor;
      PohybujeSa : boolean;
      Bomby : array of TBomba;
      procedure Posun(klaves: Integer);
      procedure Vykresli(Obr: TCanvas; Okolie : TSteny; Cas : TTimer);
      procedure VykresliBombu(Obr : TCanvas; Walli: TSteny);
      procedure ZmazBomby;
      procedure ZmazNilBomby;
      function OverPosun(klavesnica: Integer; Okolie: TSteny): Boolean;
      function OverVybuch(Okolie: TSteny): Boolean;
      constructor Create(XX,YY : Integer);
    end;


implementation

{ TBomba }

constructor TBomba.Create(XX, YY, Sec, Rad: integer);
begin
  X := XX;
  Y := YY;
  Sekund := Sec*1000;
  Radius := Rad;
end;

procedure TBomba.Odpocitavaj(Cas: integer);
begin
  Sekund := Sekund - cas;
end;

function TBomba.OverStenu(Walle: TSteny; PosX, PosY: integer): boolean;
begin
  result := false;
  if ((PosX < 0) or (PosY < 0) or (PosX >= length(Walle.Steny)) or (PosY >= length(Walle.Steny[PosX]))) then
     exit;
  if (Walle.Steny[PosX][PosY].Typ = 4) then
  begin
    Walle.Steny[PosX][PosY].Typ := 3;
    Walle.Steny[PosX][PosY].Faza := 500;
    result := false;
    exit;
  end;
  if (Walle.Steny[PosX][PosY].Typ = 0) then
  begin
       Walle.Steny[PosX][PosY].Typ := 3;
       Walle.Steny[PosX][PosY].Faza := 500;
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

procedure TPlayer.VykresliBombu(Obr: TCanvas; Walli: TSteny);
var
  i, j: integer;
begin
  Obr.Brush.Color := clBlue;
  Obr.Pen.Color := clBlue;
  for j:= 0 to length(Bomby)-1 do
  begin
      Bomby[j].Odpocitavaj(10);
      if (Bomby[j].Sekund >= 0) then
       Obr.Rectangle(Bomby[j].x-17,Bomby[j].y-17,Bomby[j].x+16,Bomby[j].y+16)
       else
       begin
           Walli.Steny[Bomby[j].x div 33 - 2][Bomby[j].y div 33 - 2].Typ := 0;
           for i:=(Bomby[j].x div 33) downto (Bomby[j].x div 33 - Bomby[j].radius) do
           begin
                if (Bomby[j].OverStenu(Walli, i-2, Bomby[j].y div 33 - 2)) then
                   Obr.Rectangle(i*33,Bomby[j].y-17,(i+1)*33,Bomby[j].y+16)
                else
                    break;
           end;
           for i:=(Bomby[j].x div 33) to (Bomby[j].x div 33 + Bomby[j].radius) do
           begin
                if (Bomby[j].OverStenu(Walli, i-2, Bomby[j].y div 33 - 2)) then
                     Obr.Rectangle(i*33,Bomby[j].y-17,(i+1)*33,Bomby[j].y+16)
                else
                    break;
           end;
           for i:=(Bomby[j].y div 33) to (Bomby[j].y div 33 + Bomby[j].radius) do
           begin
                if (Bomby[j].OverStenu(Walli, Bomby[j].x div 33 - 2, i-2)) then
                   Obr.Rectangle(Bomby[j].x-17,i*33,Bomby[j].x+16,(i+1)*33)
                else
                    break;
           end;
           for i:=(Bomby[j].y div 33) downto (Bomby[j].y div 33 - Bomby[j].radius) do
           begin
                if (Bomby[j].OverStenu(Walli, Bomby[j].x div 33 -2, i-2)) then
                   Obr.Rectangle(Bomby[j].x-17,i*33,Bomby[j].x+16,(i+1)*33)
                else
                    break;
           end;
       end;
  end;
  ZmazBomby;
end;

procedure TPlayer.ZmazBomby;
var
  i : integer;
begin
  for i:=0 to length(Bomby)-1 do
      if (Bomby[i].Sekund < 0) then
         FreeAndNil(Bomby[i]);
  ZmazNilBomby;
end;

procedure TPlayer.ZmazNilBomby;
var
  i,velkost : integer;
begin
  velkost := 0;
  for i:=0 to length(Bomby)-1 do
      if (Bomby[i] = nil) then
      begin
        Bomby[i] := Bomby[high(Bomby)-velkost];
        Inc(velkost);
      end;
  setlength(Bomby, length(Bomby)-velkost);
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
  setlength(Bomby, 0);
end;

end.

