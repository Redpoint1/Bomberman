unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, game;

type

    { Player }

    { TPlayer }

    TPlayer = class
      Zivot, X, Y : Integer;
      Farba: TColor;
      PohybujeSa : boolean;
      procedure Posun(klaves: Integer);
      procedure Vykresli(Obr: TCanvas);
      function OverPosun(klavesnica: Integer; Okolie: TSteny): boolean;
      constructor Create(XX,YY : Integer);
    end;


implementation

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

procedure TPlayer.Vykresli(Obr: TCanvas);
begin
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
              if ((Y div 33 - 1) < 0) then exit;
              if (Okolie.Steny[X div 33][Y div 33 - 1].Typ = 0) then
                 result := true;
         end;
       1:
         begin
              if ((Y div 33 +1) > 19) then exit;
              if (Okolie.Steny[X div 33][Y div 33 + 1].Typ = 0) then
                 result := true;
         end;
       2:
         begin
              if ((X div 33 - 1) < 0) then exit;
              if (Okolie.Steny[X div 33 - 1][Y div 33].Typ = 0) then
                 result := true;
         end;
       3:
         begin
              if ((X div 33 + 1) > 29) then exit;
              if (Okolie.Steny[X div 33 + 1][Y div 33].Typ = 0) then
                 result := true;
         end;
  end;
end;

constructor TPlayer.Create(XX,YY : Integer);
begin
  Zivot := 3;
  X := XX;
  Y := YY;
  Farba := clBlack;
  PohybujeSa := false;
end;

end.

