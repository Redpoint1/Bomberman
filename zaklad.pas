unit zaklad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, Math, LCLType, player, game;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

const pixel : Integer = 33;

var
  Form1: TForm1;
  Hrac: TPlayer;
  Wall: TSteny;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i, j : Integer;
begin
  Hrac := TPlayer.Create(17,17);
  Wall := TSteny.Create;
  Image1.Canvas.FillRect(Image1.ClientRect);
  for i:=0 to length(Wall.Steny)-1 do
      for j:=0 to length(Wall.Steny[i])-1 do
      if (((i mod 3) = 1) and ((j mod 3) = 1)) then
      begin
         Wall.Steny[i][j] := TStena.Create(i*33+17, j*33+17, 1);
         Wall.ZmenFarbu(i,j, clRed);
      end
      else
      begin
         Wall.Steny[i][j] := TStena.Create(i*33+17, j*33+17, 0);
         Wall.ZmenFarbu(i,j, clWhite);
      end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
   VK_UP: Hrac.Posun(0);
   VK_DOWN: Hrac.Posun(1);
   VK_LEFT: Hrac.Posun(2);
   VK_RIGHT: Hrac.Posun(3);
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
   Wall.Vykresli(Image1.Canvas);
end;

end.

