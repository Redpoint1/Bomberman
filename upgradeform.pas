unit upgradeform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, ExtCtrls, player, share;

type

  { TUpgrade }

  PPlayer = ^TPlayer;

  TUpgrade = class(TForm)
    Button1: TButton;
    Image1: TImage;
    RadiusButton: TSpeedButton;
    CountButton: TSpeedButton;
    SpeedButton: TSpeedButton;
    LifeButton: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure CountButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LifeButtonClick(Sender: TObject);
    procedure RadiusButtonClick(Sender: TObject);
    procedure SpeedButtonClick(Sender: TObject);
    procedure vykresliInfo;
  private
    { private declarations }
  public
    Hrac: PPlayer;
    procedure Vytvor(Zmena: PPlayer);
  end;

var
  Upgrade: TUpgrade;

implementation

{$R *.lfm}

{ TUpgrade }

procedure TUpgrade.RadiusButtonClick(Sender: TObject); //ak chceme zvacsi radius vybuchu
begin
  if ((Hrac^.Skore >= UpgradeCost[1]) and ((Hrac^.BombRadius - 1) < MaxUpgrade[1])) then
  begin //over ci je na to dostatocny pocet skore a ci nemame upgradnenuty na max
    Inc(Hrac^.BombRadius);  //zvysime ten radius
    Dec(Hrac^.Skore, UpgradeCost[1]); //znizime skore
    vykresliInfo; //vykreslenie updatenutych info v upgrade forme
    ShowMessage('Veľkosť radiusu je: ' + IntToStr(Hrac^.BombRadius));
    //oznamenie ,ze aky radius mame
  end
  else
    ShowMessage('Nemáte dostatočný počet bodov, alebo máte maximálny počet dovolených upgrade-ov!'); // <---
end;

procedure TUpgrade.SpeedButtonClick(Sender: TObject); //ak chceme zvysit rychlost hraca
begin
  if ((Hrac^.Skore >= UpgradeCost[2]) and (Hrac^.Speed < StartSpeed +
    MaxUpgrade[2] * 0.05)) then
  begin //ak mame dostatocne skore a nemame max upgrade
    Hrac^.Speed := Hrac^.Speed + 0.05; //zvysime rychlost
    Dec(Hrac^.Skore, UpgradeCost[2]); //znizime skore
    vykresliInfo; //to iste ako u radius
    ShowMessage('Rýchlosť je: +' +
      IntToStr(Round((Hrac^.Speed - StartSpeed) * 100)) + '%');
    //o kolko % mame zvysenu rychlost od povodnej
  end
  else
    ShowMessage('Nemáte dostatočný počet bodov, alebo máte maximálny počet dovolených upgrade-ov!'); // <---
end;

procedure TUpgrade.vykresliInfo;
//vykreslenie ceny jednotlivych upgradeov a poctu upgradeov
begin
  Image1.Canvas.Brush.Color := Upgrade.Color;
  Image1.Canvas.FillRect(Upgrade.ClientRect);
  Image1.Canvas.font.Color := $FFFFFF;
  //info ze kolko skore mame aby sme vedeli ci mozme kupit upgrade (nepripocita skore z mapy na ktorej prave hrajeme, aby sa to nedalo podvadzat
  Image1.Canvas.TextOut(Image1.Width div 2 - Image1.Canvas.TextWidth('Vaše skore:') div
    2, 50, 'Vaše skore:');
  //centrovanie textu nad buttonom kolko_mame/max_kolko_mozmo
  Image1.Canvas.TextOut(Image1.Width div 2 - Image1.Canvas.TextWidth(
    IntToStr(Hrac^.Skore)) div 2, 70, IntToStr(Hrac^.Skore));
  Image1.Canvas.TextOut(104 - Image1.Canvas.TextWidth(
    IntToStr(Hrac^.PocetBomb - 1) + '/' + IntToStr(MaxUpgrade[0])) div 2, 125,
    IntToStr(Hrac^.PocetBomb - 1) + '/' + IntToStr(MaxUpgrade[0]));
  Image1.Canvas.TextOut(208 - Image1.Canvas.TextWidth(
    IntToStr(Hrac^.BombRadius - 1) + '/' + IntToStr(MaxUpgrade[1])) div 2, 125,
    IntToStr(Hrac^.BombRadius - 1) + '/' + IntToStr(MaxUpgrade[1]));
  Image1.Canvas.TextOut(312 - Image1.Canvas.TextWidth(
    IntToStr(Round((Hrac^.Speed - StartSpeed) / 0.05)) + '/' +
    IntToStr(MaxUpgrade[2])) div 2, 125, IntToStr(Round(
    (Hrac^.Speed - StartSpeed) / 0.05)) + '/' + IntToStr(MaxUpgrade[2]));
  Image1.Canvas.font.Color := $000066;
  //vycentrovanie pod buttonmi a vykreslenie kolko stoji upgrade
  Image1.Canvas.TextOut(104 - (Image1.Canvas.TextWidth(IntToStr(UpgradeCost[0]))) div
    2, 220, IntToStr(UpgradeCost[0]));
  Image1.Canvas.TextOut(208 - (Image1.Canvas.TextWidth(IntToStr(UpgradeCost[1]))) div
    2, 220, IntToStr(UpgradeCost[1]));
  Image1.Canvas.TextOut(312 - (Image1.Canvas.TextWidth(IntToStr(UpgradeCost[2]))) div
    2, 220, IntToStr(UpgradeCost[2]));
  Image1.Canvas.TextOut(416 - (Image1.Canvas.TextWidth(IntToStr(UpgradeCost[3]))) div
    2, 220, IntToStr(UpgradeCost[3]));
  Image1.Canvas.font.Color := $FFFFFF;
end;

procedure TUpgrade.CountButtonClick(Sender: TObject);
//ak chceme zvysit pocet bomb ,ktore mozme polozit
begin
  if ((Hrac^.Skore >= UpgradeCost[0]) and ((Hrac^.PocetBomb - 1) < MaxUpgrade[0])) then
  begin //ak mame tolko skore a nie je max upgrade
    Inc(Hrac^.PocetBomb); //zvysime pocet bomb
    Dec(Hrac^.Skore, UpgradeCost[0]); //znizime skore
    vykresliInfo; //to iste ako u radiusu
    ShowMessage('Počet bomb je: ' + IntToStr(Hrac^.PocetBomb));
    //oznami ze kolko bomb mozme pokladat
  end
  else
    ShowMessage('Nemáte dostatočný počet bodov, alebo máte maximálny počet dovolených upgrade-ov!'); //<---
end;

procedure TUpgrade.FormCreate(Sender: TObject);
begin
  Image1.Canvas.font.Size := 12; //nastavenie pisma a sirky pisma
  Image1.Canvas.Font.Bold := True;
end;

procedure TUpgrade.Button1Click(Sender: TObject);
begin
  Upgrade.Hide; //ukry formular
end;

procedure TUpgrade.LifeButtonClick(Sender: TObject); //ak chceme zivoty
begin
  if (Hrac^.Skore >= UpgradeCost[3]) then  // ak mame na to skore
  begin
    Inc(Hrac^.Zivot); //zvys pocet zivota hracovi
    Dec(Hrac^.Skore, UpgradeCost[3]); //zniz skore
    vykresliInfo; //ako u radiusu
    ShowMessage('Počet životov je: ' + IntToStr(Hrac^.Zivot));
    //oznami kolko zivotov mame
  end
  else
    ShowMessage('Nemáte dostatočný počet bodov, alebo máte maximálny počet dovolených upgrade-ov!');  //<---
end;

procedure TUpgrade.Vytvor(Zmena: PPlayer);
begin
  if (Hrac = nil) then //ak v premenj nie je ziadny pointer ci nie je vytvoreny vytvor ho
    new(Hrac);
  Hrac := Zmena; //priradime pointer hraca z zaklad unitu
  vykresliInfo; //vykreslenie skore, upgradeov ...
end;

end.
