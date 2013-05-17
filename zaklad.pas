unit zaklad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, LCLType, Buttons, player, game, npc, share, upgradeform, highscore;

type

  { TForm1 }

  TForm1 = class(TForm)
    HryObraz: TImage;
    HraCas: TTimer;
    HracCas: TTimer;
    NewGame: TSpeedButton;
    Nastavenia: TSpeedButton;
    MenuPanel: TPanel;
    Quit: TSpeedButton;
    Nacitaj: TSpeedButton;
    Resume: TSpeedButton;
    Highscore: TSpeedButton;
    UpgradeBut: TSpeedButton;
    Uloz: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure HighscoreClick(Sender: TObject);
    procedure HraCasTimer(Sender: TObject);
    procedure HracCasTimer(Sender: TObject);
    procedure NacitajClick(Sender: TObject);
    procedure NastaveniaClick(Sender: TObject);
    procedure NewGameClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    procedure ResumeClick(Sender: TObject);
    procedure UpgradeButClick(Sender: TObject);
    procedure UlozClick(Sender: TObject);
    procedure VykresliInfo(Obraz: TCanvas; Informacie: TPlayer);
  end;

var
  Form1: TForm1;
  Hrac: TPlayer;  //objekt hraca
  Wall: TSteny;   // objekty mapy ,teda stien
  Nepriatel: TNepriatel;   //objekty nepriatelov
  Gui, TempMapa, PartMapa: TBitmap;
// pomocna bitmapa (logo, informacna tabulka pocat hry)

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  HryObraz.Canvas.Brush.Color := Form1.Color;
  HryObraz.Canvas.FillRect(Form1.ClientRect);
  gui := TBitMap.Create;
  gui.LoadFromFile('img/logo.bmp');
  gui.Transparent := True;
  HryObraz.Canvas.Draw((HryObraz.Width div 2) - (gui.Width div 2), 15, gui);
  //vykreslenie loga v menu
  gui.Transparent := False;
  gui.LoadFromFile('img/gui.bmp'); //nacitanie informacneho panelu pre hraca
  HryObraz.Canvas.Font.Size := 18;
  HryObraz.Canvas.Font.Color := clWhite;
  HryObraz.Canvas.Font.Bold := True;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if not (HraCas.Enabled) then //ak nezacala hra skonci
    exit;
  if (key = VK_ESCAPE) then  //ak stlaci escape ukaze menu a pozastavi hru
  begin
    HraCas.Enabled := False;
    HracCas.Enabled := False;
    Resume.Show; //ukaze button na pokracovanie hry
    HryObraz.Canvas.Brush.Color := Form1.Color;
    HryObraz.Canvas.FillRect(Form1.ClientRect);
    gui.LoadFromFile('img/logo.bmp');
    gui.Transparent := True;
    HryObraz.Canvas.Draw((HryObraz.Width div 2) - (gui.Width div 2), 15, gui);
    //vykreslenie loga v menu
    gui.Transparent := True;
    gui.LoadFromFile('img/gui.bmp'); //nacitanie informacneho panelu pre hraca
    HryObraz.Canvas.Font.Size := 18;
    HryObraz.Canvas.Font.Color := clWhite;
    HryObraz.Canvas.Font.Bold := True;
    MenuPanel.Show;
  end;
  if ((key = VK_SPACE) and ((Hrac.PocetBomb + Hrac.UpgradePocetBomb) >
    length(Hrac.Bomby)) and not (Hrac.Zomrel)) then
    //ak stlacime medzernik a hrac nie je mrtvy polozi bombu
  begin
    if ((Wall.Steny[(Hrac.GetY div pixel)][(Hrac.GetX div pixel)].Typ <> 2) and
      (Wall.Steny[(Hrac.GetY div pixel)][(Hrac.GetX div pixel)].Upgrade < 0)) then
      //overenie ci na danej kosticke nie je uz bomba
    begin
      setlength(Hrac.Bomby, length(Hrac.Bomby) + 1);
      Hrac.Bomby[high(Hrac.Bomby)] :=
        TBomba.Create(((Hrac.GetX div pixel) * pixel + 17),
        ((Hrac.GetY div pixel) * pixel + 17), 3, Hrac.BombRadius + Hrac.UpgradeRadius);
      //vytvorenie a nastavenie pozicie bomby s radiusom a casov vybuchnutia
      Wall.Steny[(Hrac.GetY div pixel)][(Hrac.GetX div pixel)].Typ := 2;
      //nastavime kosticku mapy ,ze je tam polozena bomba
    end;
  end;
  if (not (Hrac.Zomrel) and (Key in KlavesnicePohybu)) then
    //ak sa nepohybuje hrac , nezomrel a stlacil klavesu pohybu sa posunie
  begin
    case Key of
      VK_UP: Hrac.Smer := 0; //smer hraca ktorym pojde
      VK_DOWN: Hrac.Smer := 1;
      VK_LEFT: Hrac.Smer := 2;
      VK_RIGHT: Hrac.Smer := 3;
    end;
    if (Hrac.OverPosun(Wall) and not (HracCas.Enabled)) then
      //overi posun hraca ci moze ist na danu kosticku a nepohybuje sa
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
  if not (HraCas.Enabled) then //nech nerobi nic pokial nie je spustena hra
    exit;
  if ((Hrac.PohybujeSa) and (Key in KlavesnicePohybu)) then
    //ak pustime klavesu pohybu
  begin
    if (((key = VK_UP) and (Hrac.Smer = 0)) or ((key = VK_DOWN) and (Hrac.Smer = 1)) or
      ((key = VK_LEFT) and (Hrac.Smer = 2)) or ((key = VK_RIGHT) and
      (Hrac.Smer = 3)))
    then //overenie ci pustame tu klavesu ,ktorym smerom sa pohybuje hrac
    begin
      HracCas.Enabled := False; //skoncime pohyb
      Hrac.PohybujeSa := False;
    end;
  end;
end;

procedure TForm1.HighscoreClick(Sender: TObject);
begin
  HiSc.Show; //ukaze upgrade viac v upgradeform unit
end;

procedure TForm1.HraCasTimer(Sender: TObject);
var
  X, Y: integer;
begin
  if Hrac.OverKoniec(Wall, Nepriatel) then //ak je na brane a na mape nie je ziadne npc
  begin
    HraCas.Enabled := False; //skonci vykreslovanie a vymaz premenne
    HracCas.Enabled := False;
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    Inc(Hrac.Level); //zvysenie levelu
    if (Hrac.Level < length(level)) then //ak nepresiel vsetky urovne
    begin
      Hrac.ResetNextMap; //resetneme docastne upgrade-y a pridame skore za mapu
      Nepriatel := TNepriatel.Create(); //nacitanie nepriatelov a mapy dalsieho levelu
      Nepriatel.Nacitaj(level[Hrac.Level]);
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      HraCas.Enabled := True; //spustime hru
      MenuPanel.Hide; //ukri menu
      Upgrade.Hide; //ukri upgrade-y
      exit; //skonci
    end
    else //ak presiel vsetky urovnia
    begin
      Resume.Hide; //zakryjeme tlacitko pokracovania
      HryObraz.Canvas.Brush.Color := Form1.Color; //ukazeme si uvodny obrazok
      HryObraz.Canvas.FillRect(Form1.ClientRect);
      gui.LoadFromFile('img/logo.bmp');
      gui.Transparent := True;
      HryObraz.Canvas.Draw((HryObraz.Width div 2) - (gui.Width div 2), 15, gui);
      //vykreslenie loga v menu
      gui.Transparent := True;
      gui.LoadFromFile('img/gui.bmp'); //nacitanie informacneho panelu pre hraca
      MenuPanel.Show;
      Hrac.Save; //ulozime profil (kvazi zablokujeme kedze sme presli hru)
      FreeAndNil(Hrac);
      ShowMessage('GRATULUJEME! Prešli ste hru!'); //oznamenie skoncenia celej hry
      exit;  //skonci a dalej nechod
    end;
  end;
  if ((Hrac.Zomrel) and (Hrac.Faza = 65) and (Hrac.Zivot > 0)) then
    //ak zomrel a ma este zivoty resetni mapu
  begin
    HraCas.Enabled := False;
    HracCas.Enabled := False;
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    Hrac.resetMap; //resetne mapu (podrobnejsie priamo v procedure)
    Nepriatel := TNepriatel.Create();  //znova vytvorenie nepriatelov a mapy
    Nepriatel.Nacitaj(level[Hrac.Level]);
    Wall := TSteny.Create;
    Wall.Nacitaj(level[Hrac.Level]);
    HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
    HraCas.Enabled := True; //spustime hru znova
    exit;
  end;
  if ((Hrac.Zivot < 1) and (Hrac.Zomrel) and (Hrac.Faza = 65)) then
    //ak zomrel a nema ziadne zivoty
  begin
    HraCas.Enabled := False; //skonci vsetky casovace uvolnime premenne
    HracCas.Enabled := False;
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    Hrac.Save; //ulozime profil aby sa nedalo pokracovat
    Hrac.UlozSkore; //ulozime jeho highscore ak patri medzi top
    FreeAndNil(Hrac);
    Resume.Hide; //zakrytie pokracovania (tlacitko)
    HryObraz.Canvas.Brush.Color := Form1.Color;
    HryObraz.Canvas.FillRect(Form1.ClientRect);
    gui.LoadFromFile('img/logo.bmp');
    gui.Transparent := True;
    HryObraz.Canvas.Draw((HryObraz.Width div 2) - (gui.Width div 2), 15, gui);
    //vykreslenie loga v menu
    gui.Transparent := True;
    gui.LoadFromFile('img/gui.bmp'); //nacitanie informacneho panelu pre hraca
    MenuPanel.Show;
    ShowMessage('Prehrali ste!'); //oznam o prehre
    exit; //skonci v timeri
  end;
  //ak nezomrel, nepostupil ....
  VykresliInfo(HryObraz.Canvas, Hrac);  //vykreslenie informacneho panelu
  Wall.Vykresli(TempMapa.Canvas); //vykreslenie mapy stien a cesty
  if ((Hrac.Bomby <> nil) or (length(Hrac.Bomby) > 0)) then  //ak je polozena bomba
    Hrac.VykresliBombu(TempMapa.Canvas, Wall);    //vykreslenie bomby ci vybuchov
  if ((Nepriatel <> nil) or (length(Nepriatel.NPC) > 0)) then
    //ak je nejaky nepriatel tak vykresli ich
  begin
    Nepriatel.Casovac;
    //s podprocedurami na vybranie nahodneho smeru, fazy animacie, posunutie na mape ...
    Nepriatel.Vykresli(TempMapa.Canvas, Wall); //vykreslenie nepriatelov
    Inc(Hrac.LevelSkore, Nepriatel.VratSkore); //priradenie skore zabitych npc
  end;
  Hrac.Vykresli(TempMapa.Canvas, Wall, Nepriatel, HracCas); //vykreslenie hraca
  if ((length(Wall.Steny) <= 15) and (length(Wall.Steny[low(Wall.Steny)]) <= 23)) then
    HryObraz.Canvas.Draw(66 + (759 - length(Wall.Steny[low(Wall.Steny)]) * pixel) div
      2, 66 + (495 - length(Wall.Steny) * pixel) div 2, TempMapa)
  else
  begin
    if ((Hrac.GetX > PartMapa.Width div 2) and
      (Hrac.GetX < TempMapa.Width - PartMapa.Width div 2)) then
      Hrac.PosunX := Hrac.GetX - PartMapa.Width div 2;
    if (Hrac.GetY > PartMapa.Height div 2) and
      (Hrac.GetY < TempMapa.Height - PartMapa.Height div 2) then
      Hrac.PosunY := Hrac.GetY - PartMapa.Height div 2;
    PartMapa.Canvas.Draw(-Hrac.PosunX, -Hrac.PosunY, TempMapa);
    HryObraz.Canvas.Draw(66, 66, PartMapa);
  end;
end;

procedure TForm1.HracCasTimer(Sender: TObject);
begin
  if Hrac.OverPosun(Wall) then
    //overenie ci sa moze pohnut a nema ziadnu prekazku pred sebou
  begin
    Hrac.Posun(Hrac.Smer); //meni poziciu hraca podla orientacie pohybu
    Hrac.OverUpgrade(Wall); //overi ci nevstupil na upgrade
  end
  else
  begin
    HracCas.Enabled := False;  //ak ma prekazku prestan sa pohybovat
    Hrac.PohybujeSa := False;
  end;
end;

procedure TForm1.NacitajClick(Sender: TObject);
var
  profil: string;
begin
  if InputQuery('Výber profilu', 'Napíšte názov profilu', profil) then
    //vyber profilu
    if fileexists('profil/' + profil + '.dat') then //ak ten profil existuje nacitaj hru
    begin
      FreeAndNil(Hrac); //istota uvolnenia premennych
      FreeAndNil(Wall);
      FreeAndNil(Nepriatel);
      FreeAndNil(TempMapa);
      FreeAndNil(PartMapa);
      Hrac := TPlayer.Create(profil);
      Hrac.Load(profil); //nacita profil zo suboru
      if ((Hrac.Level >= length(level)) or (Hrac.Zivot < 1)) then
        //ak uz presiel ci uz nema zivoty
      begin
        FreeAndNil(Hrac);
        ShowMessage('Tento profil už prešiel hru, alebo ste ju neprešli!');
        exit; //vypise ze uz ste prehrali ci vyhrali a skonci cely proces
      end;
      //ak neprehral ci nevyhral nacita mapu a zacne sa hra
      Nepriatel := TNepriatel.Create();
      Nepriatel.Nacitaj(level[Hrac.Level]); //nacitanie nepriatelov
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      TempMapa := TBitMap.Create;
      TempMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      TempMapa.Height := length(Wall.Steny) * pixel;
      if ((length(Wall.Steny) > 15) or (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin
        PartMapa := TBitmap.Create;
        PartMapa.Width := 759;
        PartMapa.Height := 495;
      end;
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      HraCas.Enabled := True; //spustime hru
      MenuPanel.Hide; //ukri menu
      Upgrade.Hide;
    end
    else //ak nenasiel profil oznami to a nic neurobi
      ShowMessage('Profil sa nenašiel!');
end;

procedure TForm1.NastaveniaClick(Sender: TObject);
begin
  //volby obtiaznosti 4. etapa
end;

procedure TForm1.NewGameClick(Sender: TObject);
var
  profil: string;
begin
  if InputQuery('Názov profilu', 'Napíšte názov profilu', profil) then
    if (profil <> '') then //ak ste zadali nejake meno vytvori profil
    begin
      FreeAndNil(Wall); //istota
      FreeAndNil(Nepriatel);
      FreeAndNil(Hrac);
      FreeAndNil(TempMapa);
      FreeAndNil(PartMapa);
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      Hrac := TPlayer.Create(profil);
      //vytvorenie hraca s pociatocnym x a y
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      Nepriatel := TNepriatel.Create;
      Nepriatel.Nacitaj(level[Hrac.Level]); //nacitanie nepriatelov zo suboru
      TempMapa := TBitMap.Create;
      TempMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      TempMapa.Height := length(Wall.Steny) * pixel;
      if ((length(Wall.Steny) > 15) or (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin
        PartMapa := TBitmap.Create;
        PartMapa.Width := 759;
        PartMapa.Height := 495;
      end;
      HraCas.Enabled := True; //spustime hru
      MenuPanel.Hide; //ukri menu
      Hrac.Save; //ulozime profil s pociatocnymi informaciami o hracovi
      Upgrade.Hide;
    end
    else
      ShowMessage('Nepodarilo sa vytvoriť profil!'); //ak sa nenapisal nazov profilu
end;

procedure TForm1.QuitClick(Sender: TObject);
begin
  Close; //vyjde z hry
end;

procedure TForm1.ResumeClick(Sender: TObject);
begin
  if (Hrac <> nil) then //osetrenie aby to nespustalo ked nie je nacitany profil
  begin
    MenuPanel.Hide; //zajryjeme uvodnu obrazovku a spustime hru
    Upgrade.Hide;
    HryObraz.Canvas.Brush.Color := Form1.Color;
    HryObraz.Canvas.FillRect(Form1.ClientRect);
    HraCas.Enabled := True;
  end;
end;

procedure TForm1.UpgradeButClick(Sender: TObject);
begin
  if (Hrac <> nil) then //ak je nacitany nejaky profil
  begin
    Upgrade.Vytvor(@Hrac);
    //posleme pointer hraca do upgrade unitu kedze cez priradenie by neslo...
    Upgrade.Show; //ukazeme upgrade
  end;
end;

procedure TForm1.UlozClick(Sender: TObject);
begin
  if (Hrac <> nil) then //ak je nejaky profil nacitany
  begin
    Hrac.Save; //uloz ho a oznam to
    ShowMessage('Uložené');
  end;
end;

procedure TForm1.VykresliInfo(Obraz: TCanvas; Informacie: TPlayer);
begin
  HryObraz.Canvas.Draw(831, 66, gui); //vykreslime informacny panel hraca
  Obraz.Brush.Style := bsClear;
  Obraz.TextOut(915, 85, 'x ' + IntToStr(Informacie.Zivot));
  //nastavujeme poziciu kde sa bude zobrazovat informacia o zivote
  Obraz.TextOut(865, 125, format('%.6d', [Informacie.Skore + Informacie.LevelSkore]));
  //to iste iba skore sa bude zobrazovat vo formate 001000
  Obraz.TextOut(895, 190, IntToStr(Length(Informacie.Bomby)) + ' / ' +
    IntToStr(Informacie.PocetBomb + Informacie.UpgradePocetBomb));
  //zobrazi informacie ze kolko ma polozenych bomb z povolenych
  Obraz.TextOut(870, 240, 'Level ' + IntToStr(Informacie.Level + 1));
  //info ,ktory je to level
  Obraz.Font.Size := 9; //mensie upravy fontu na vykreslovanie slova 'Skore'
  Obraz.Font.Bold := False;
  Obraz.TextOut(895, 154, 'Skóre');
  Obraz.Font.Bold := True;
  Obraz.Font.Size := 18;
  Obraz.Brush.Style := bsSolid;
end;

end.
