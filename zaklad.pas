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
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  Hrac: TPlayer;  //objekt hraca
  Wall: TSteny;   // objekty mapy ,teda stien
  Nepriatel: TNepriatel;   //objekty nepriatelov

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  obr: TBitMap;
begin
  Randomize;
  Image1.Canvas.Brush.Color := Form1.Color;
  Image1.Canvas.FillRect(Form1.ClientRect);
  obr := TBitMap.Create;
  obr.LoadFromFile('img/gui.bmp');
  Image1.Canvas.Draw(831, 66, Obr);
  Wall := TSteny.Create;
  Wall.Nacitaj('level', Image1.Height, Image1.Width); //nacitanie mpay z LEVEL(.txt)
  Hrac := TPlayer.Create(2 * pixel + 17, 2 * pixel + 17);
  //vytvorenie hraca s pociatocnym x a y
  Nepriatel := TNepriatel.Create();
  Nepriatel.Nacitaj('level'); //nacitanie nepriatelov z LEVEL(.txt)
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (key = VK_SPACE) then //ak stlacime medzernik
  begin
    if (Wall.Steny[(Hrac.Y div pixel) - 2][(Hrac.X div pixel) - 2].Typ <> 2) then
      //overenie ci na danej kosticke nie je uz bomba
    begin
      setlength(Hrac.Bomby, length(Hrac.Bomby) + 1);
      Hrac.Bomby[high(Hrac.Bomby)] :=
        TBomba.Create(((Hrac.X div pixel) * pixel + 17),
        ((Hrac.Y div pixel) * pixel + 17), 3, 2);
      //vytvorenie a nastavenie pozicie bomby s radiusom a casov vybuchnutia
      Wall.Steny[(Hrac.Y div pixel) - 2][(Hrac.X div pixel) - 2].Typ := 2;
      //nastavime kosticku mapy ,ze je tam polozena bomba
    end;
  end;
  if (not (Hrac.PohybujeSa) and not (Hrac.Zomrel) and (Key in KlavesnicePohybu)) then
    //ak sa nepohybuje hrac
  begin
    case Key of
      VK_UP: Hrac.Smer := 0; //smer hraca ktorym pojde
      VK_DOWN: Hrac.Smer := 1;
      VK_LEFT: Hrac.Smer := 2;
      VK_RIGHT: Hrac.Smer := 3;
    end;
    if (Hrac.OverPosun(Wall)) then
      //overi posun hraca ci moze ist na danu kosticku ak je stlaceny jeden z klaves s ktorymi sa pohybuje
    begin
      Hrac.Faza := 32; //resetovanie fazy animovania
      Hrac.Opacne := False; //kolisanie a stupanie fazy pohybovania
      Hrac.PohybujeSa := True; //nastavime pohybovanie hraca
      Timer2.Enabled := True;
      //povolime casovac ,ktory bude animovat pohyb hraca aj zmenami x,y
    end;
  end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if ((Hrac.PohybujeSa) and (Key <> VK_SPACE)) then
  begin
    Timer2.Enabled := False;
    Hrac.PohybujeSa := False;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Wall.Vykresli(Image1.Canvas); //vykreslenie mapy stien a cesty
  if (length(Nepriatel.NPC) > 0) then  //ak je nejaky nepriatel tak vykresli ich
  begin
    Nepriatel.Casovac;
    //s podprocedurami na vybranie nahodneho smeru, fazy animacie, posunutie na mape ...
    Nepriatel.Vykresli(Image1.Canvas, Wall); //vykreslenie nepriatelov
  end;
  if ((Hrac.Bomby <> nil) or (length(Hrac.Bomby) > 0)) then  //ak je polozena bomba
    Hrac.VykresliBombu(Image1.Canvas, Wall);    //vykreslenie bomby ci vybuchov
  Hrac.Vykresli(Image1.Canvas, Wall, Nepriatel, Timer2); //vykreslenie hraca
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  if Hrac.OverPosun(Wall) then
    Hrac.Posun(Hrac.Smer) //meni poziciu hraca podla orientacie pohybu
  else
  begin
    Timer2.Enabled := False;
    Hrac.PohybujeSa := False;
  end;
end;

end.
