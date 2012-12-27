unit zaklad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, LCLType, player, game, npc;

type

  { TForm1 }

  TForm1 = class(TForm)
    HryObraz: TImage;
    HraCas: TTimer;
    HracCas: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure HraCasTimer(Sender: TObject);
    procedure HracCasTimer(Sender: TObject);
    procedure VykresliInfo(Obraz : TCanvas; Informacie : TPlayer);
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
  Gui : TBitmap;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  HryObraz.Canvas.Brush.Color := Form1.Color;
  HryObraz.Canvas.FillRect(Form1.ClientRect);
  gui := TBitMap.Create;
  gui.LoadFromFile('img/gui.bmp');
  HryObraz.Canvas.Brush.Style := bsClear;
  HryObraz.Canvas.Font.Size := 18;
  HryObraz.Canvas.Font.Color := clWhite;
  HryObraz.Canvas.Font.Bold := true;
  Wall := TSteny.Create;
  Wall.Nacitaj('level', HryObraz.Height, HryObraz.Width); //nacitanie mpay z LEVEL(.txt)
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
      HracCas.Enabled := True;
      //povolime casovac ,ktory bude animovat pohyb hraca aj zmenami x,y
    end;
  end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if ((Hrac.PohybujeSa) and (Key <> VK_SPACE)) then
  begin
    HracCas.Enabled := False;
    Hrac.PohybujeSa := False;
  end;
end;

procedure TForm1.HraCasTimer(Sender: TObject);
begin
  VykresliInfo(HryObraz.Canvas, Hrac);
  Wall.Vykresli(HryObraz.Canvas); //vykreslenie mapy stien a cesty
  if (length(Nepriatel.NPC) > 0) then  //ak je nejaky nepriatel tak vykresli ich
  begin
    Nepriatel.Casovac;
    //s podprocedurami na vybranie nahodneho smeru, fazy animacie, posunutie na mape ...
    Nepriatel.Vykresli(HryObraz.Canvas, Wall); //vykreslenie nepriatelov
    Inc(Hrac.Skore,Nepriatel.VratSkore);
  end;
  if ((Hrac.Bomby <> nil) or (length(Hrac.Bomby) > 0)) then  //ak je polozena bomba
    Hrac.VykresliBombu(HryObraz.Canvas, Wall);    //vykreslenie bomby ci vybuchov
  Hrac.Vykresli(HryObraz.Canvas, Wall, Nepriatel, HracCas); //vykreslenie hraca
end;

procedure TForm1.HracCasTimer(Sender: TObject);
begin
  if Hrac.OverPosun(Wall) then
    Hrac.Posun(Hrac.Smer) //meni poziciu hraca podla orientacie pohybu
  else
  begin
    HracCas.Enabled := False;
    Hrac.PohybujeSa := False;
  end;
end;

procedure TForm1.VykresliInfo(Obraz: TCanvas; Informacie: TPlayer);
begin
  HryObraz.Canvas.Draw(831, 66, gui);
  Obraz.TextOut(915,85, 'x '+IntToStr(Informacie.Zivot));
  Obraz.TextOut(865,125, format('%.6d', [Informacie.Skore]));
  Obraz.TextOut(895,190, IntToStr(Length(Informacie.Bomby))+ ' / '+IntToStr(3));
  Obraz.Font.Size := 9;
  Obraz.Font.Bold := false;
  Obraz.TextOut(895,154, 'Skóre');
  Obraz.Font.Bold := true;
  Obraz.Font.Size := 18;
end;

end.
