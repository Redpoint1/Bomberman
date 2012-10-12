unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

    { Player }

    TPlayer = class
      Zivot, X, Y : Integer;
      procedure Posun(klaves: Integer);
      function OverPosun(klavesnica: Integer): boolean;
      constructor Create(XX,YY : Integer);
    end;


implementation

{ Player }

procedure TPlayer.Posun(klaves: Integer);
begin

end;

function TPlayer.OverPosun(klavesnica: Integer): boolean;
begin

end;

constructor TPlayer.Create(XX,YY : Integer);
begin
  Zivot := 3;
  X := XX;
  Y := YY;
end;

end.

