unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type

  { TStena }

  TStena = class
    X, Y, Typ: Integer;
    Farba : TColor;
    Constructor Create(XX,YY, TypSteny: Integer);
  end;

  TNieco = array[0..29, 0..19] of TStena;

  { TSteny }

  TSteny = class
    Steny : array of array of TStena;
    procedure ZmenFarbu(X, Y: Integer; Farby : TColor);
    procedure Vykresli(Obr : TCanvas);
    Constructor Create();
  end;

implementation

{ TSteny }

procedure TSteny.ZmenFarbu(X, Y: Integer; Farby : TColor);
begin
  Steny[X][Y].Farba := Farby;
end;

procedure TSteny.Vykresli(Obr : TCanvas);
var
  i,j : integer;
begin
  for i:=0 to length(Steny)-1 do
      for j:=0 to length(Steny[i])-1 do
      begin
          Obr.Pen.Color:= Steny[i][j].Farba;
          Obr.Brush.Color := Steny[i][j].Farba;
          Obr.Rectangle(Steny[i][j].X-17, Steny[i][j].Y-17, Steny[i][j].X+16, Steny[i][j].Y+16);
      end;
end;

constructor TSteny.Create;
begin
 SetLength(Steny, 0);
end;

{ TStena }

constructor TStena.Create(XX, YY, TypSteny: Integer);
begin
  X := XX;
  Y := YY;
  Typ := TypSteny;
end;

end.

