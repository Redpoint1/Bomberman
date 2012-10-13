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
    Timer2: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
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
  if not(Hrac.PohybujeSa) then
  begin
       Hrac.Smer := -1;
       case Key of
        VK_UP: Hrac.Smer := 0;
        VK_DOWN: Hrac.Smer := 1;
        VK_LEFT: Hrac.Smer := 2;
        VK_RIGHT: Hrac.Smer := 3;
       end;
       if (Hrac.OverPosun(Hrac.Smer, Wall) and (Hrac.Smer > -1)) then
       begin
         Hrac.PohybujeSa := true;
         Timer2.Enabled := true;
       end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
   Wall.Vykresli(Image1.Canvas);
   Hrac.Vykresli(Image1.Canvas);
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  Hrac.Posun(Hrac.Smer);
  if (((Hrac.X mod 33) = 17) and ((Hrac.Y mod 33) = 17)) then
  begin
     Hrac.PohybujeSa := false;
     Timer2.Enabled := false;
  end;
end;

end.

