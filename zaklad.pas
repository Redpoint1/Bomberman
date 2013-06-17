unit zaklad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Math,
  ExtCtrls, LCLType, Buttons, LazHelpHTML, player, game, npc, share,
  upgradeform, highscore, nastaveniahry;

type

  { TForm1 }

  TForm1 = class(TForm)
    HryObraz: TImage;
    HraCas: TTimer;
    HTMLBrowserHelpViewer1: THTMLBrowserHelpViewer;
    HTMLHelpDatabase1: THTMLHelpDatabase;
    InfoScr: TTimer;
    NewGame: TSpeedButton;
    Nastavenia: TSpeedButton;
    MenuPanel: TPanel;
    Quit: TSpeedButton;
    Nacitaj: TSpeedButton;
    Resume: TSpeedButton;
    Highscore: TSpeedButton;
    Custom: TSpeedButton;
    UpgradeBut: TSpeedButton;
    Uloz: TSpeedButton;
    procedure CustomClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; {%H-}Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: word; {%H-}Shift: TShiftState);
    procedure HighscoreClick(Sender: TObject);
    procedure HraCasTimer(Sender: TObject);
    procedure InfoScrStartTimer(Sender: TObject);
    procedure InfoScrTimer(Sender: TObject);
    procedure NacitajClick(Sender: TObject);
    procedure NastaveniaClick(Sender: TObject);
    procedure NewGameClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    procedure ResumeClick(Sender: TObject);
    procedure UpgradeButClick(Sender: TObject);
    procedure UlozClick(Sender: TObject);
    procedure VykresliInfo(Obraz: TCanvas; Informacie: TPlayer; Mapa: TSteny);
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
  ZobrazMenu; //v share unite viacej
end;

procedure TForm1.CustomClick(Sender: TObject);
var
  mapa: string;
begin
  mapa := '';
  if InputQuery('Custom mapa', 'Napíšte názov mapy', mapa) then
    if fileexists('mapy/' + mapa + '.dat') then
      //po zadani nazvu overi ci existuje ten subor
    begin
      FreeAndNil(Hrac); //istota uvolnenia premennych
      FreeAndNil(Wall);
      FreeAndNil(Nepriatel);
      FreeAndNil(TempMapa);
      FreeAndNil(PartMapa);
      Uloz.Enabled := False;//profil je docastny tak znepristupnime moznost ulozenia
      Hrac := TPlayer.Create(mapa);
      Hrac.CustomMapa := True; //identifikator ,ze profil je len docastny
      Hrac.Level := -1; //nech nam vypise Level 0
      Hrac.Skore := 70000; //ak by chcel mat upgrade-y a zivoty na vyskusanie mapy
      Nepriatel := TNepriatel.Create;
      Nepriatel.Nacitaj(mapa); //nacitanie nepriatelov
      Wall := TSteny.Create;
      Wall.Nacitaj(mapa); //nacitanie mapy
      TempMapa := TBitMap.Create; //bitmapa kam sa vykresluje vylsedny obrazok
      TempMapa.Width := length(Wall.Steny[high(Wall.Steny)]) * pixel;
      TempMapa.Height := length(Wall.Steny) * pixel; //nastavenie vysky a sirky
      if ((length(Wall.Steny) > 15) or (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin  //ak je vacsia ako maximalna velkost vykreslovania mapy nastav obmedzenu velkost
        PartMapa := TBitmap.Create;
        if (length(Wall.Steny) > 15) then
          PartMapa.Height := 495
        else
          PartMapa.Height := length(Wall.Steny) * pixel;
        if (length(Wall.Steny[low(Wall.Steny)]) > 23) then
          PartMapa.Width := 759
        else
          PartMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      end;
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      MenuPanel.Hide; //ukri menu
      Nastavenia.Enabled := True; //moznost si nastvit obtiaznost a autosave
      InfoScr.Enabled := True; //spustime hru
    end
    else
      ShowMessage(
        'Mapa sa nenašla. Skontrolujte či ste zadali správny názov, alebo či sa nachádza v adresári "mapy".');
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if not (HraCas.Enabled) then //ak nezacala hra skonci
    exit;
  if (key = VK_ESCAPE) then  //ak stlaci escape ukaze menu a pozastavi hru
  begin
    HraCas.Enabled := False;
    Hrac.PohybujeSa := False;
    Resume.Show; //ukaze button na pokracovanie hry
    ZobrazMenu;
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
    if (Hrac.OverPosun(Wall) and not (Hrac.PohybujeSa)) then
      //overi posun hraca ci moze ist na danu kosticku a nepohybuje sa
    begin
      Hrac.Faza := 32; //resetovanie fazy animovania
      Hrac.Opacne := False; //kolisanie a stupanie fazy pohybovania
      Hrac.PohybujeSa := True; //nastavime pohybovanie hraca
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
      Hrac.PohybujeSa := False;  //skoncime pohyb
    end;
  end;
end;

procedure TForm1.HighscoreClick(Sender: TObject);
begin
  Form1.Hide;
  HiSc.Show; //ukaze upgrade viac v upgradeform unit
end;

procedure TForm1.HraCasTimer(Sender: TObject);
begin
  if Hrac.OverKoniec(Wall, Nepriatel) then //ak je na brane a na mape nie je ziadne npc
  begin
    HraCas.Enabled := False; //skonci vykreslovanie a vymaz premenne
    Hrac.PohybujeSa := False;
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    FreeAndNil(TempMapa);
    FreeAndNil(PartMapa);
    Inc(Hrac.Level); //zvysenie levelu
    if ((Hrac.Level < length(level)) and not (Hrac.CustomMapa)) then
      //ak nepresiel vsetky urovne a profil nie je docasny
    begin
      Hrac.ResetNextMap; //resetneme docasne upgrade-y a pridame skore za mapu
      Nepriatel := TNepriatel.Create; //nacitanie nepriatelov a mapy dalsieho levelu
      Nepriatel.Nacitaj(level[Hrac.Level]);
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      MenuPanel.Hide; //ukri menu
      TempMapa := TBitMap.Create;  //vyssie som popisal v customClick
      TempMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      ShowMessage(IntToStr(TempMapa.Width));
      TempMapa.Height := length(Wall.Steny) * pixel;
      if ((length(Wall.Steny) > 15) or (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin
        PartMapa := TBitmap.Create;
        if (length(Wall.Steny) > 15) then
          PartMapa.Height := 495
        else
          PartMapa.Height := length(Wall.Steny) * pixel;
        if (length(Wall.Steny[low(Wall.Steny)]) > 23) then
          PartMapa.Width := 759
        else
          PartMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      end;
      InfoScr.Enabled := True; //spustime Info screen
      exit; //skonci
    end
    else //ak presiel vsetky urovne alebo custom mapu
    begin
      Resume.Hide; //zakryjeme tlacitko pokracovania
      Uloz.Enabled := True; //znova povolime moznost ulozenia profilu
      ZobrazMenu;
      Inc(Hrac.Skore, Hrac.LevelSkore);
      //posledne zvysovanie skore pred porovnanim high score
      Hrac.LevelSkore := 0; //zresetujeme skore ,ktore sme ziskali za mapu
      if not (Hrac.CustomMapa) then  //ak nie je dostany profil
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
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    Hrac.resetMap; //resetne mapu (podrobnejsie priamo v procedure)
    Nepriatel := TNepriatel.Create;  //znova vytvorenie nepriatelov a mapy
    Wall := TSteny.Create;
    if not (Hrac.CustomMapa) then
    begin
      Nepriatel.Nacitaj(level[Hrac.Level]); //nacitaj zo suboru podla levelu
      Wall.Nacitaj(level[Hrac.Level]);
    end
    else
    begin
      Nepriatel.Nacitaj(Hrac.Nick); //nacitaj podla nicku (nick = custom mapa)
      Wall.Nacitaj(Hrac.Nick);
    end;
    HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
    InfoScr.Enabled := True; //spustime Info screen
    exit;
  end;
  if (((Hrac.Zivot < 1) and (Hrac.Zomrel) and (Hrac.Faza = 65)) or
    ((Hrac.CasMapy > Wall.Cas) and (Hrac.Obtiaznost = 2))) then
    //ak zomrel a nema ziadne zivoty alebo ak vyprasal cas na challenge
  begin
    HraCas.Enabled := False; //skonci vsetky casovace uvolnime premenne
    FreeAndNil(Wall);
    FreeAndNil(Nepriatel);
    Hrac.Zivot := 0; //istota kvoli challange .. podla toho sa overuje ci prehral
    Inc(Hrac.Skore, Hrac.LevelSkore); //posledne zvysovanie pred porovnanim high skore
    Hrac.LevelSkore := 0; //istota
    if not (Hrac.CustomMapa) then
    begin
      Hrac.Save; //ulozime profil aby sa nedalo pokracovat ak nie je docastny profil
      Hrac.UlozSkore; //ulozime jeho score ak patri medzi top
    end;
    FreeAndNil(Hrac);
    Uloz.Enabled := True; //zase povolime moznost ulozenia
    Resume.Hide; //zakrytie pokracovania (tlacitko)
    ZobrazMenu;
    ShowMessage('Prehrali ste!'); //oznam o prehre
    exit; //skonci v timeri
  end;
  //ak nezomrel, nepostupil ....


  VykresliInfo(HryObraz.Canvas, Hrac, Wall);  //vykreslenie informacneho panelu
  Wall.Vykresli(TempMapa.Canvas); //vykreslenie mapy stien a cesty
  if ((Hrac.Bomby <> nil) or (length(Hrac.Bomby) > 0)) then  //ak je polozena bomba
    Hrac.VykresliBombu(TempMapa.Canvas, Wall);    //vykreslenie bomby ci vybuchov
  if ((Nepriatel <> nil) or (length(Nepriatel.NPC) > 0)) then
    //ak je nejaky nepriatel tak vykresli ich
  begin
    Nepriatel.Casovac(Hrac.Obtiaznost);
    //s podprocedurami na vybranie nahodneho smeru, fazy animacie, posunutie na mape ...
    Nepriatel.Vykresli(TempMapa.Canvas, Wall, Hrac.Obtiaznost, Hrac.GetX, Hrac.GetY);
    //vykreslenie nepriatelov
    Inc(Hrac.LevelSkore, Round(Nepriatel.VratSkore * nasobitelXP[Hrac.Obtiaznost]));
    //priradenie skore zabitych npc
  end;
  Hrac.PohybujSa(Wall); //overenie posunu, posun
  Hrac.CasMapy := Hrac.CasMapy + 0.01; //cas ,ktory hra na mape
  Hrac.Vykresli(TempMapa.Canvas, Wall, Nepriatel); //vykreslenie hraca
  if ((length(Wall.Steny) <= 15) and (length(Wall.Steny[low(Wall.Steny)]) <= 23)) then
    HryObraz.Canvas.Draw(10 + (759 - length(Wall.Steny[low(Wall.Steny)]) * pixel) div
      2, 10 + (495 - length(Wall.Steny) * pixel) div 2, TempMapa)
  //ak je mensia mapa ako maximalna povolene vykreslenie mapy vycentruj to
  else
  begin //inac ak nam zobrazi iba cas mapy, tak vykresli iba tu cast kde je vidno hrac
    if ((Hrac.GetX > PartMapa.Width div 2) and (Hrac.GetX <
      TempMapa.Width - PartMapa.Width div 2)) then
      Hrac.PosunX := Hrac.GetX - PartMapa.Width div 2;
    //ak je za stredom vykreslenej mapy tak o kolko dame do premennej
    if (Hrac.GetY > PartMapa.Height div 2) and (Hrac.GetY <
      TempMapa.Height - PartMapa.Height div 2) then
      Hrac.PosunY := Hrac.GetY - PartMapa.Height div 2; //to iste
    PartMapa.Canvas.Draw(-Hrac.PosunX, -Hrac.PosunY, TempMapa);
    if ((length(Wall.Steny) > 15) and (length(Wall.Steny[low(Wall.Steny)]) <= 23)) then //centrovanie vykreslovania ciastocnej mapy
      HryObraz.Canvas.Draw(10 + (759 - length(Wall.Steny[low(Wall.Steny)]) * pixel) div
        2, 10, PartMapa)
    else if ((length(Wall.Steny) <= 15) and (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      HryObraz.Canvas.Draw(10, 10 + (495 - length(Wall.Steny) * pixel) div 2, PartMapa)
    else
      HryObraz.Canvas.Draw(10, 10, PartMapa);
  end;
end;

procedure TForm1.InfoScrStartTimer(Sender: TObject);
begin
  //spusti sa to hned po Timer.Enabled := true;
  HryObraz.Canvas.FillRect(Form1.ClientRect); //vyplnime farbou
  HryObraz.Canvas.Draw(430, 260, Hrac.HracObr[1][0]); //vykreslime obrazok postavicky
  HryObraz.Canvas.TextOut(460, 260, 'x ' + IntToStr(Hrac.Zivot));
  //vypiseme kolko zivotom mu zostava
  HryObraz.Canvas.TextOut(425, 230, 'Level ' + IntToStr(Hrac.Level + 1));
  //ktory level bude hrat
end;

procedure TForm1.InfoScrTimer(Sender: TObject);
begin
  //spusti sa to po Danom intervale a po InfoScrStartTime
  InfoScr.Enabled := False; //vypneme casovat
  HraCas.Enabled := True; //povolime hru
end;

procedure TForm1.NacitajClick(Sender: TObject);
var
  profil: string;
begin
  profil := '';
  if InputQuery('Výber profilu', 'Napíšte názov profilu', profil) then
    //vyber profilu
    if fileexists('profil/' + profil + '.dat') then //ak ten profil existuje nacitaj hru
    begin
      FreeAndNil(Hrac); //istota uvolnenia premennych
      FreeAndNil(Wall);
      FreeAndNil(Nepriatel);
      FreeAndNil(TempMapa);
      FreeAndNil(PartMapa);
      ULoz.Enabled := True;
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
      Nepriatel := TNepriatel.Create;
      Nepriatel.Nacitaj(level[Hrac.Level]); //nacitanie nepriatelov
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      TempMapa := TBitMap.Create;  //vyssie som popisal v customClick
      TempMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      TempMapa.Height := length(Wall.Steny) * pixel;
      if ((length(Wall.Steny) > 15) or (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin
        PartMapa := TBitmap.Create;
        if (length(Wall.Steny) > 15) then
          PartMapa.Height := 495
        else
          PartMapa.Height := length(Wall.Steny) * pixel;
        if (length(Wall.Steny[low(Wall.Steny)]) > 23) then
          PartMapa.Width := 759
        else
          PartMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      end;
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      MenuPanel.Hide; //ukri menu
      Nastavenia.Enabled := True; //povolime moznost nastavenia obtiaznosti a autosave
      InfoScr.Enabled := True; //spustime hru
    end
    else //ak nenasiel profil oznami to a nic neurobi
      ShowMessage('Profil sa nenašiel!');
end;

procedure TForm1.NastaveniaClick(Sender: TObject);
begin
  if Hrac <> nil then //aby nam to nepadlo
  begin
    NastavHraca := Hrac;  //priradime do premennej z nastaveniahry.pas
    NastavPop.RadioGroup1.ItemIndex := Hrac.Obtiaznost;  //zmenime radio v druhom forme
    NastavPop.AutoSave.Checked := Hrac.AutoSave; //nastavime checkbox
    NastavPop.Show;
    Form1.Hide;
  end;
end;

procedure TForm1.NewGameClick(Sender: TObject);
var
  profil: string;
  diff: integer;
begin
  profil := '';
  if InputQuery('Názov profilu', 'Napíšte názov profilu', profil) then
    if (profil <> '') then //ak ste zadali nejake meno vytvori profil
    begin
      if (fileexists('profil/' + profil + '.dat')) then
        //overenie ci existuej taky profil
        if (MessageDlg('POZOR!',
          'Už existuje profil s rovnakym nazvom. Chcete ho prepísať?',
          mtConfirmation, [mbYes, mbNo], 0) = mrNo) then  //je to napisane co chce <---
          exit;
      FreeAndNil(Wall); //istota
      FreeAndNil(Nepriatel);
      FreeAndNil(Hrac);
      FreeAndNil(TempMapa);
      FreeAndNil(PartMapa);
      HryObraz.Canvas.FillRect(Form1.ClientRect); //prefarbenie pozadia
      Hrac := TPlayer.Create(profil); //vytvorenie hraca s pociatocnym x a y
      profil := ''; //dalsia istota
      repeat
        if not (InputQuery('Obtiažnosť',
          'Zadajte počiatočnú obtiažnosť:' + sLineBreak +
          '0 - Lahká' + sLineBreak + '1 - Normálna' + sLineBreak +
          '2 - Challenge', profil)) then  //ak da cancel
        begin
          diff := 0;
          break;
        end;
      until tryStrToInt(profil, diff) and (diff >= 0) and (diff < 3);
      //opakuj pokial si nevyberes jednu zo spravnych moznosti
      Hrac.Obtiaznost := diff; //priradi obtiaznost do profilu
      Uloz.Enabled := True; //moznost ulozenia profilu
      Wall := TSteny.Create;
      Wall.Nacitaj(level[Hrac.Level]);
      Nepriatel := TNepriatel.Create;
      Nepriatel.Nacitaj(level[Hrac.Level]); //nacitanie nepriatelov zo suboru
      TempMapa := TBitMap.Create; //popisane v customClick
      TempMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      TempMapa.Height := length(Wall.Steny) * pixel;
      if ((length(Wall.Steny) > 15) or
        (length(Wall.Steny[low(Wall.Steny)]) > 23)) then
      begin
        PartMapa := TBitmap.Create;
        if (length(Wall.Steny) > 15) then
          PartMapa.Height := 495
        else
          PartMapa.Height := length(Wall.Steny) * pixel;
        if (length(Wall.Steny[low(Wall.Steny)]) > 23) then
          PartMapa.Width := 759
        else
          PartMapa.Width := length(Wall.Steny[low(Wall.Steny)]) * pixel;
      end;
      MenuPanel.Hide; //ukri menu
      Nastavenia.Enabled := True;
      Hrac.Save; //ulozime profil s pociatocnymi informaciami o hracovi
      InfoScr.Enabled := True;
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
    MenuPanel.Hide; //zakryjeme uvodnu obrazovku a spustime hru
    HryObraz.Canvas.Brush.Color := Form1.Color;
    HryObraz.Canvas.FillRect(Form1.ClientRect);
    HraCas.Enabled := True; //spustime znova hru
  end;
end;

procedure TForm1.UpgradeButClick(Sender: TObject);
begin
  if (Hrac <> nil) then //ak je nacitany nejaky profil
  begin
    Upgrade.Vytvor(@Hrac);
    //posleme pointer hraca do upgrade unitu
    Form1.Hide;
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

procedure TForm1.VykresliInfo(Obraz: TCanvas; Informacie: TPlayer; Mapa: TSteny);
begin
  HryObraz.Canvas.Draw(775, 10, gui); //vykreslime informacny panel hraca
  Obraz.Brush.Style := bsClear;
  Obraz.TextOut(859, 29, 'x ' + IntToStr(Informacie.Zivot));
  //nastavujeme poziciu kde sa bude zobrazovat informacia o zivote
  Obraz.TextOut(809, 69, format('%.6d', [Informacie.Skore + Informacie.LevelSkore]));
  //to iste iba skore sa bude zobrazovat vo formate 001000
  Obraz.TextOut(839, 134, IntToStr(Length(Informacie.Bomby)) + ' / ' +
    IntToStr(Informacie.PocetBomb + Informacie.UpgradePocetBomb));
  //zobrazi informacie ze kolko ma polozenych bomb z povolenych
  Obraz.TextOut(817, 184, 'Level ' + IntToStr(Informacie.Level + 1));
  //info ,ktory je to level
  Obraz.TextOut(820, 259, format('%.2d', [Floor(Informacie.CasMapy) div 60]) +
    ':' + format('%.2d', [Floor(Informacie.CasMapy) mod 60])); //kolko hrajeme danu mapu
  Obraz.Font.Size := 9; //mensie upravy fontu na vykreslovanie slova 'Skore'
  Obraz.Font.Bold := False;
  Obraz.TextOut(839, 236, format('%.2d', [Floor(Mapa.Cas) div 60]) +
    ':' + format('%.2d', [Floor(Mapa.Cas) mod 60]));
  //kolko casu mame u challenge obtiaznosti
  Obraz.Font.Bold := True;
  Obraz.Font.Size := 18;
  Obraz.Brush.Style := bsSolid;
end;

end.
