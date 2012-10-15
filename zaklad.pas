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
  Bomb: TBomba;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i, j : Integer;
begin
  Hrac := TPlayer.Create(2*33+17,2*33+17);
  Wall := TSteny.Create;
  Image1.Canvas.FillRect(Image1.ClientRect);
  for i:=0 to (Image1.Width div pixel)-8 do
  begin
      SetLength(Wall.Steny, Length(Wall.Steny)+1);
      for j:=0 to (Image1.Height div pixel)-5 do
      begin
      SetLength(Wall.Steny[i], Length(Wall.Steny[i])+1);
      if (((i mod 3) = 1) and ((j mod 3) = 1)) then
      begin
         Wall.Steny[i][j] := TStena.Create(i*pixel+17+2*pixel, j*pixel+17+2*pixel, 1);
         Wall.ZmenFarbu(i,j, clRed);
      end
      else
      begin
         Wall.Steny[i][j] := TStena.Create(i*pixel+17+2*pixel, j*pixel+17+2*pixel, 0);
         Wall.ZmenFarbu(i,j, clWhite);
      end;
      end;
  end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key = VK_SPACE) then
    Bomb := TBomba.Create(((Hrac.X div 33)*33 + 17), ((Hrac.Y div 33)*33 + 17), 3, 1);
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
var
  i,j : integer;
begin
   Wall.Vykresli(Image1.Canvas);
   Hrac.Vykresli(Image1.Canvas, Wall, Timer2);
   if (Bomb <> nil) then
   begin
     Bomb.Vykresli(Image1.Canvas, Wall);
     if (Bomb.Sekund <= -1000) then
     begin
       for i:=0 to length(Wall.Steny)-1 do
           for j:= 0 to length(Wall.Steny[i])-1 do
           begin
                if (Wall.Steny[i][j].Typ = 3) then
                   Wall.Steny[i][j].Typ := 0;
           end;
     FreeAndNil(Bomb);
     end;
   end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
     Hrac.Posun(Hrac.Smer);
     if (((Hrac.X mod pixel) = 17) and ((Hrac.Y mod pixel) = 17)) then
     begin
        Hrac.PohybujeSa := false;
        Timer2.Enabled := false;
     end;
end;

end.

