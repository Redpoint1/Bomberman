unit zaklad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, LCLType, player, game, npc;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  pixel: integer = 33;

var
  Form1: TForm1;
  Hrac: TPlayer;
  Wall: TSteny;
  Nepriatel: TNepriatel;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  Image1.Canvas.Brush.Color := Form1.Color;
  Image1.Canvas.FillRect(Form1.ClientRect);
  Wall := TSteny.Create;
  Wall.Nacitaj('level', Image1.Height, Image1.Width);
  Hrac := TPlayer.Create(2 * 33 + 17, 2 * 33 + 17);
  Nepriatel := TNepriatel.Create();
  Nepriatel.Pridaj(20 * 33 + 17, 2 * 33 + 17, 1);
  Nepriatel.Pridaj(10 * 33 + 17, 14 * 33 + 17, 1);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (key = VK_SPACE) then
  begin
    if (Wall.Steny[(Hrac.Y div 33) - 2][(Hrac.X div 33) - 2].Typ <> 2) then
    begin
      setlength(Hrac.Bomby, length(Hrac.Bomby) + 1);
      Hrac.Bomby[high(Hrac.Bomby)] :=
        TBomba.Create(((Hrac.X div 33) * 33 + 17), ((Hrac.Y div 33) * 33 + 17), 3, 2);
      Wall.Steny[(Hrac.Y div 33) - 2][(Hrac.X div 33) - 2].Typ := 2;
    end;
  end;
  if not (Hrac.PohybujeSa) then
  begin
    Hrac.Smer := -1;
    case Key of
      VK_UP: Hrac.Smer := 0;
      VK_DOWN: Hrac.Smer := 1;
      VK_LEFT: Hrac.Smer := 2;
      VK_RIGHT: Hrac.Smer := 3;
    end;
    if (Hrac.OverPosun(Wall) and (Hrac.Smer > -1)) then
    begin
      Hrac.PohybujeSa := True;
      Timer2.Enabled := True;
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Wall.Vykresli(Image1.Canvas);
  if (length(Nepriatel.NPC) > 0)then
  begin
       Nepriatel.Casovac;
       Nepriatel.Vykresli(Image1.Canvas, Wall);
  end;
  if ((Hrac.Bomby <> nil) or (length(Hrac.Bomby) > 0)) then
    Hrac.VykresliBombu(Image1.Canvas, Wall);
  Hrac.Vykresli(Image1.Canvas, Wall, Nepriatel, Timer2);
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  Hrac.Posun(Hrac.Smer);
  if (((Hrac.X mod pixel) = 17) and ((Hrac.Y mod pixel) = 17)) then
  begin
    Hrac.PohybujeSa := False;
    Timer2.Enabled := False;
  end;
end;

end.
