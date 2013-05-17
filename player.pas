unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game, npc, share;

type

  { Player }

  { TBomba }

  TBomba = class  //objekt bomby
    X, Y, Sekund, Radius, Faza: integer;
    //pozicia bomby, cas vybuchnutia, velkost vybuchu, faza animacie bomby
    constructor Create(XX, YY, Sec, Rad: integer);  //vytvorenie bomby
    procedure Odpocitavaj(Cas: integer);  //odpocitavanie casu bomby do vybuchnutia
    function OverStenu(Walle: TSteny; Bombs: array of TBomba;
      PosY, PosX, Smer: integer): boolean;
    //overenie vybuchov aby nebucha aj kde je stena
  end;

  { TPlayer }

  TPlayer = class
    Nick: string;
    Zivot, Smer, Faza, Skore, PocetBomb, UpgradePocetBomb, UpgradeRadius,
    BombRadius, Level, LevelSkore, PosunX, PosunY: integer;
    //snad z nazvovo premennych pochopitelne iba tie s Upgrade* su docastne upgrade-y na mapu
    X, Y, UpgradeSpeed, Speed: real;
    //pozicia hraca, docasne zvysenie rychlosti na mapu a rychlost hraca
    Zomrel, PohybujeSa, Opacne: boolean;
    //ci zomrel, sa pohybuje a opakovanie animacie pohybovania
    Bomby: array of TBomba;  //polozene bomby hraca
    BombyObr: array[0..1] of TBitMap;  //animacie bomby
    HracObr: array[0..4] of array[0..2] of TBitMap; //animacie hraca
    procedure Posun(klaves: integer); //zmena pozicie hraca podla orientacie pohybu
    procedure Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel: TNepriatel;
    //vykreslenie hraca
      Cas: TTimer);
    procedure VykresliBombu(Obr: TCanvas; Walli: TSteny); //vykreslenie bomby
    procedure ZmazBomby; //zmazanie vybuchnutych bomb
    procedure ZmazNilBomby; //zmazanie bomb z pola
    procedure OverUpgrade(Okolie: TSteny); //ak isiel na upgrade tak prirad dotycny
    procedure Load(sub: string); //nacitanie profily zo suboru
    procedure Save; //ulozenie hraca do suboru profilu hraca
    procedure UlozSkore; //ulozi skore hraca do suboru
    procedure resetMap; //resetnutie premennych hraca pri zabiti
    procedure resetNextMap; //resetnutie premenych pri pokracovanie do dalsieho levelu
    function OverNpc(Nepriatel: TNepriatel): boolean;
    //zabitie hraca ked je nepriatel blizko
    function OverPosun(Okolie: TSteny): boolean;
    //overenie policka ci sa hrac moze presunut
    function OverVybuch(Okolie: TSteny): boolean; //zabitie hraca ak ho zasiahla bomba
    function OverKoniec(Okolie: TSteny; Nepriatel: TNepriatel): boolean;
    //ak skoncil celu hru
    function GetX: integer; //zokruhlenie pozicie hraca real > integer
    function GetY: integer; //to iste
    constructor Create(Profil: string);  //vytvorenie hraca
  end;


implementation

{ TBomba }

constructor TBomba.Create(XX, YY, Sec, Rad: integer);
  //nastavenie premennych pri vytvoreni bomby
begin
  X := XX;
  Y := YY;
  Sekund := Sec * 1000; //cas buchnutia
  Radius := Rad; //radius vybuchu
  Faza := 0; //animacia
end;

procedure TBomba.Odpocitavaj(Cas: integer); //odpocitavanie casu do vybuchu
begin
  Sekund := Sekund - cas; //odpocitavanie casu vybuchu
end;

function TBomba.OverStenu(Walle: TSteny; Bombs: array of TBomba;
  PosY, PosX, Smer: integer): boolean;
  //overenie ci nie je stena pri vybuchu
var
  i: integer;
begin
  Result := False;
  if ((PosX < 0) or (PosY < 0) or (PosY >= length(Walle.Steny)) or
    (PosX >= length(Walle.Steny[PosY]))) then
    //ak vybuch siaha za okraj mapy nevykresli vybuch
    exit;
  if (Walle.Steny[PosY][PosX].Typ = 0) and (Walle.Steny[PosY][PosX].Upgrade >= 0) and
    (Walle.Steny[PosY][PosX].Upgrade <> Brana) then //ak je tam upgrade znic ho
    Walle.Steny[PosY][PosX].Upgrade := -1;
  if ((Walle.Steny[PosY][PosX].Typ in ZnicitelneBloky) or
    (Walle.Steny[PosY][PosX].upgrade = brana)) then
    //ak je znicitelna stena znic ju a dalej nechod s vybuchom ,alebo je to brana
  begin
    if (Walle.Steny[PosY][PosX].Typ = 2) then //ak je to bomba
    begin
      for i := 0 to high(bombs) do //vyhladame tu bombu
        if ((bombs[i].X = (((PosX) * pixel + 17))) and
          (bombs[i].Y = ((PosY) * pixel + 17))) then //ak je to ta bomba
        begin
          bombs[i].Sekund := 0; //nastavime cas vybuchu
          Result := False; //skonci pokracovanie vybuchu
          exit;
        end;
    end
    else //ak to nie je bomba ale ina stena
    begin
      if (Walle.Steny[PosY][PosX].Upgrade < 0) then
        //ak nema upgrade teda nie je to brana
      begin
        Walle.Steny[PosY][PosX].Typ := 0;  //nastavenie na volne policko
        Walle.Steny[PosY][PosX].Obraz := Walle.StenyObr[0];
        //zmenime obrazok policka na volne policko
      end
      else //ak je pod stenou brana
      begin
        Walle.Steny[PosY][PosX].Typ := 0; //nastav na volne policko
        Walle.Steny[PosY][PosX].Obraz :=
          Walle.UpgradeObr[Walle.Steny[PosY][PosX].Upgrade];  //a hod obrazok brany
      end;
      Result := False; //skkonci a dalej nepokracuj s vybuchom
      exit;
    end;
  end;
  if (Walle.Steny[PosY][PosX].Typ = 0) then
    //ak je volne policko nastavi policky na vybuch
  begin
    Walle.Steny[PosY][PosX].Typ := 3;
    Walle.Steny[PosY][PosX].Faza := 501;
    Result := True;
    case Smer of  // vlozenie presneho obrazku podla smeru vybuchu
      0: //hore
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][4];
        Walle.Steny[PosY][PosX].BombaSmer := 4;
      end;
      1: //dole
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][4];
        Walle.Steny[PosY][PosX].BombaSmer := 4;
      end;
      2: //doprava
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][1];
        Walle.Steny[PosY][PosX].BombaSmer := 1;
      end;
      3: //dolava
      begin
        Walle.Steny[PosY][PosX].Obraz := Walle.BombyObr[0][1];
        Walle.Steny[PosY][PosX].BombaSmer := 1;
      end;
    end;
  end
  else if (Walle.Steny[PosY][PosX].Typ = 3) then
    //ak uz na tom policku vybuchuje tak len obnovi dlzku vybuchu na policku
  begin
    Walle.Steny[PosY][PosX].Faza := 500;
    Result := True;
  end;
end;

{ Player }

procedure TPlayer.Posun(klaves: integer);
begin
  case klaves of    //podla orientacie smeru pohybu meni poziciu hraca
    0: Y := Y - UpgradeSPeed - Speed;
    1: Y := Y + UpgradeSPeed + Speed;
    2: X := X - UpgradeSPeed - Speed;
    3: X := X + UpgradeSPeed + Speed;
  end;
end;

procedure TPlayer.Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel: TNepriatel;
  Cas: TTimer);
begin
  if (((OverVybuch(Okolie)) or (OverNpc(Nepriatel))) and not (Zomrel)) then
    //overi ci nieco hraca nezabije a ak ano tak znizi mu zivot + zastavi pohyb hraca
  begin
    if (Cas.Enabled) then //ak sa pohybuje
    begin
      Cas.Enabled := False; //zrus pohyb
      PohybujeSa := False;
    end;
    Zomrel := True; //pridaj ze zomrel a zniz mu zivot
    Faza := -1;
    Smer := 4; //nie cisto smer ,ale riadok animacie hraca v bmp subore
    Zivot := Zivot - 1;
  end;
  if (Zomrel) then //ak zomrel
    Inc(Faza); //animuj umrtie
  if (PohybujeSa) then  //ak sa pohybuje
  begin
    if (Faza = 1) then //opacne kreslenie obrazkov pohybu (zacyklovanie animacie pohybu)
      opacne := True;
    if (Faza = 32) then
      opacne := False;
    if (Opacne) then
      Inc(Faza)
    else
      Dec(Faza);
  end;
  if (Zomrel) then //bud vykreslenie pohybu hraca ci umrtia
    Obr.Draw(Round(X - 17), Round(Y - 17), HracObr[Smer][Faza div 22])
  else
    Obr.Draw(Round(X - 17), Round(Y - 17), HracObr[Smer][Faza div 11]);
end;

procedure TPlayer.VykresliBombu(Obr: TCanvas; Walli: TSteny);
var
  i, j: integer;
begin
  for j := 0 to length(Bomby) - 1 do  //cez vsetky bomby
  begin
    Bomby[j].Odpocitavaj(10);  //odpocitaj cas do vybuchnutia
    Bomby[j].Faza := (Bomby[j].Sekund div 500) mod 2; //fazovanie animacie
    if (Bomby[j].Sekund >= 0) then   // ak este ma cas ddo vybuchnutia vykresli bombu
      Obr.Draw(Bomby[j].x - 17, Bomby[j].y - 17, BombyObr[Bomby[j].Faza])
    else   //inac vybuchne bomba
    begin
      Walli.Steny[Bomby[j].y div pixel][Bomby[j].x div pixel].Typ := 0;
      //zmena policka mapy
      for i := (Bomby[j].x div pixel) downto (Bomby[j].x div pixel - Bomby[j].radius) do
        //nastavi policka na vybuchnutie
        //dolava
      begin
        if (Bomby[j].OverStenu(Walli, Bomby, Bomby[j].y div pixel, i, 2)) then
          //overuje ci nie je stena
        begin
          if ((i = (Bomby[j].x div pixel - Bomby[j].radius)) and
            (Walli.Steny[Bomby[j].y div pixel][i].Faza = 501)) then
            //ukoncuje vybuch
          begin
            Walli.Steny[Bomby[j].y div pixel][i].Obraz := Walli.BombyObr[0][0];
            //nastavi obrazok policka mapy na vybuch
            Walli.Steny[Bomby[j].y div pixel][i].BombaSmer := 0;
            //nastavi smer bomby
          end
          else if (i = (Bomby[j].x div pixel - Bomby[j].radius)) then
            Walli.Steny[Bomby[j].y div pixel][i].Faza := 500;
        end
        else   //ak najde stenu  tak zrus rozsirenie vybuchu
        begin
          break;
        end;
      end;
      //opakovanie pre vsetky smery
      for i := (Bomby[j].x div pixel) to (Bomby[j].x div pixel + Bomby[j].radius) do
        //doprava
      begin
        if (Bomby[j].OverStenu(Walli, Bomby, Bomby[j].y div pixel, i, 3)) then
        begin
          if ((i = (Bomby[j].x div pixel + Bomby[j].radius)) and
            (Walli.Steny[Bomby[j].y div pixel][i].Faza = 501)) then
          begin
            Walli.Steny[Bomby[j].y div pixel][i].Obraz := Walli.BombyObr[0][3];
            Walli.Steny[Bomby[j].y div pixel][i].BombaSmer := 3;
          end
          else
            Walli.Steny[Bomby[j].y div pixel][i].Faza := 500;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div pixel) to (Bomby[j].y div pixel + Bomby[j].radius) do
        //dole
      begin
        if (Bomby[j].OverStenu(Walli, Bomby, i, Bomby[j].x div pixel, 1)) then
        begin
          if ((i = (Bomby[j].y div pixel + Bomby[j].radius)) and
            (Walli.Steny[i][Bomby[j].x div pixel].Faza = 501)) then
          begin
            Walli.Steny[i][Bomby[j].x div pixel].Obraz := Walli.BombyObr[0][6];
            Walli.Steny[i][Bomby[j].x div pixel].BombaSmer := 6;
          end
          else
            Walli.Steny[i][Bomby[j].x div pixel].Faza := 500;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div pixel) downto (Bomby[j].y div pixel - Bomby[j].radius) do
        //hore
      begin
        if (Bomby[j].OverStenu(Walli, Bomby, i, Bomby[j].x div pixel, 0)) then
        begin
          if ((i = (Bomby[j].y div pixel - Bomby[j].radius)) and
            (Walli.Steny[i][Bomby[j].x div pixel].Faza = 501)) then
          begin
            Walli.Steny[i][Bomby[j].x div pixel].Obraz := Walli.BombyObr[0][5];
            Walli.Steny[i][Bomby[j].x div pixel].BombaSmer := 5;
          end
          else
            Walli.Steny[i][Bomby[j].x div pixel].Faza := 500;
        end
        else
        begin
          break;
        end;
      end;
      Walli.Steny[Bomby[j].y div pixel][Bomby[j].x div pixel].Obraz :=
        Walli.BombyObr[0][2];
      Walli.Steny[Bomby[j].y div pixel][Bomby[j].x div pixel].BombaSmer := 2;
    end;
  end;
  ZmazBomby; //zmaze vybuchnute bomby
end;

procedure TPlayer.ZmazBomby;
var
  i: integer;
begin
  for i := 0 to length(Bomby) - 1 do //zmazanie vybuchnutych bomb
    if (Bomby[i].Sekund < 0) then
      FreeAndNil(Bomby[i]);
  ZmazNilBomby; //vyhodime z pola bomby ktore vybuchli
end;

procedure TPlayer.ZmazNilBomby;
var
  i: integer;
  Pom: array of TBomba;
begin
  setlength(Pom, 0); //nastavime dlzku na 0
  for i := 0 to length(Bomby) - 1 do //cez pole bomb
    if (Bomby[i] <> nil) then  //ak nevybuchli
    begin
      setlength(Pom, length(Pom) + 1);
      Pom[high(Pom)] := Bomby[i]; //hodime do pomocneho pola
    end;
  setlength(Bomby, length(Pom)); //zmensime velkost pola bomb
  Bomby := Pom; //hodima naspat ktore este nevybuchli
end;

procedure TPlayer.OverUpgrade(Okolie: TSteny);
begin
  if (Okolie.Steny[GetY div pixel][GetX div pixel].Upgrade >= 0) then
    //ak na policku je upgrade
  begin
    case (Okolie.Steny[GetY div pixel][GetX div pixel].Upgrade) of
      //podla typu upgradeu zvys hodnoty (ak neprekracuje maximum povoleny upgrade)
      0: if ((PocetBomb + UpgradePocetBomb) < MaxPocetBomb) then
          Inc(UpgradePocetBomb);
      1: if ((BombRadius + UpgradeRadius) < MaxRadiusBomby) then
          Inc(UpgradeRadius);
      2: if ((Speed + UpgradeSpeed) < MaxHracSpeed) then
          UpgradeSpeed := UpgradeSpeed + UpgradeSpeedHodnota;
      3: Inc(Zivot);
    end;
    if (Okolie.Steny[GetY div pixel][GetX div pixel].Upgrade <> Brana) then
      //ak ten upgrade nie je id brany
    begin
      Okolie.Steny[GetY div pixel][GetX div pixel].Upgrade := -1;
      //zmaz upgrade policka
      Okolie.Steny[GetY div pixel][GetX div pixel].Obraz := Okolie.StenyObr[0];
      //hod obrazok volneho policka
    end;
  end;
end;

procedure TPlayer.Load(sub: string);
var
  S: TFileStream;
begin
  //overenie je v evente kliknutia na tlacitko
  S := TFileStream.Create('profil/' + Sub + '.dat', fmOpenRead); //otvor a resetni subor
  S.Position := 0;
  S.ReadBuffer(Zivot, 4); //nacitaj udaje zo suboru
  S.ReadBuffer(Skore, 4);
  S.ReadBuffer(PocetBomb, 4);
  S.ReadBuffer(BombRadius, 4);
  S.ReadBuffer(Level, 4);
  S.ReadBuffer(Speed, 8);
  S.Free; //zavri subor
end;

procedure TPlayer.Save;
var
  S: TFileStream;
begin
  if (nick <> '') then //overenie ci ma nazov profilu
  begin
    if not (DirectoryExists('profil')) then //ak neexistuje zlozka profil vytvor
      CreateDir('profil');
    S := TFileStream.Create('profil/' + nick + '.dat', fmCreate);
    //vytvor subor ci prepis
    S.Size := 0; //rewriteni ho
    S.WriteBuffer(Zivot, 4);
    S.WriteBuffer(Skore, 4);
    S.WriteBuffer(PocetBomb, 4);
    S.WriteBuffer(BombRadius, 4);
    S.WriteBuffer(Level, 4);
    S.WriteBuffer(Speed, 8);
    S.Free; //zapis informacie do suboru a zatvor ho
  end;
end;

procedure TPlayer.UlozSkore;
var
  S: TFileStream;
  PocetSkore: TPoleSkore;
  Pom: RSkore;
  i, j: integer;
begin
  setlength(PocetSkore, 0); //inicializovanie
  if fileexists('skore.dat') then //ak existuje uz ulozene skore
  begin
    S := TFileStream.Create('skore.dat', fmOpenReadWrite);
    if (S.Size > 0) then
      repeat
        setlength(PocetSkore, length(PocetSkore) + 1); //zvysime pole a precitame zo suboru
        S.ReadBuffer(PocetSkore[high(PocetSkore)], sizeOf(RSkore));
      until (S.Position = S.Size); //pokial neprideme na koniec
    setlength(PocetSkore, length(PocetSkore) + 1);
    //pridame terajsieho hraca co skoncil hru
    PocetSkore[high(pocetSkore)].body := skore;
    PocetSkore[high(pocetSkore)].nick := nick;
    Sortenie(@PocetSkore);
    //pretriedime (najvysieho po najnizsie skore, ak rovnake skore tak ,ktory ho dosiahol skorej je vysie)
    S.Size := 0; //rewrirte suboru
    if (length(pocetskore) <= 10) then //nech nemame viac ako 10 ludi v highscore
      j := length(pocetskore) - 1
    else
      j := 10;
    for i := 0 to j do //zapiseme utriedene pole
      S.WriteBuffer(pocetSkore[i], sizeOf(RSkore));
  end
  else //ak nie je subor skore.dat
  begin
    S := TFileStream.Create('skore.dat', fmCreate); //vytvorime ho a zapiseme hraca
    Pom.nick := nick;
    pom.body := skore;
    S.WriteBuffer(Pom, sizeOf(RSkore));
  end;
  S.Free; //zatvorime subor
end;

procedure TPlayer.resetMap;
begin
  X := SpawnSuradnice;
  //zresetneme premenne hraca pri jeho zabiti (poziciu, polozene bomby, ze zomrel, fazu a smer
  Y := SpawnSuradnice;
  setlength(bomby, 0);
  Zomrel := False;
  Faza := 32;
  Smer := 1;
end;

procedure TPlayer.resetNextMap;
begin
  resetMap;
  UpgradePocetBomb := 0;
  //ak sa posunieme na vyssi level zresetuj docastne upgrade a pripocitaj skore z predoslej mapy
  UpgradeRadius := 0;
  UpgradeSpeed := 0;
  Inc(Skore, LevelSkore);
  LevelSkore := 0;
end;

function TPlayer.OverNpc(Nepriatel: TNepriatel): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to length(Nepriatel.NPC) - 1 do
    //preveruje ci ziadny nepriatel nie je v okruhu 25 u hraca
    if (sqrt(((X - Nepriatel.NPC[i].X) * (X - Nepriatel.NPC[i].X)) +
      ((Y - Nepriatel.NPC[i].Y) * (Y - Nepriatel.NPC[i].Y))) < 25) then
    begin
      Result := True;  //ak hodi true tak hrac bude zabity
      exit;
    end;
end;

function TPlayer.OverPosun(Okolie: TSteny): boolean;
begin
  Result := False;
  case Smer of //overenie podla orientacie pohybu hraca
    0:
    begin
      if ((Y - UpgradeSPeed - Speed - 2) < 0) then //ak je koniec mapy
        exit;
      if ((Okolie.Steny[Round((Y - UpgradeSPeed - Speed - 2)) div
        pixel][Round((X - 10)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y - UpgradeSPeed - Speed - 2)) div
        pixel][Round((X + 7)) div pixel].Typ in PovoleneBloky)) then
        //ak sa moze posunut
        Result := True;
    end;
    //opakovanie pre vsetky smery
    1:
    begin
      if ((Round((Y + UpgradeSPeed + Speed + 16)) div pixel) >
        Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[Round((Y + Speed + UpgradeSPeed + 14)) div
        pixel][Round((X - 10)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y + UpgradeSPeed + Speed + 14)) div
        pixel][Round((X + 7)) div pixel].Typ in PovoleneBloky) then
        Result := True;
    end;
    2:
    begin
      if ((X - UpgradeSPeed - Speed - 11) < 0) then
        exit;
      if ((Okolie.Steny[Round((Y - 1)) div pixel][Round(
        (X - UpgradeSPeed - Speed - 11)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y - 1)) div pixel][Round(
        (X - UpgradeSPeed - Speed + 9)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y + 13)) div pixel][Round(
        (X - UpgradeSPeed - Speed - 11)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y + 13)) div pixel][Round(
        (X - UpgradeSPeed - Speed + 9)) div pixel].Typ in PovoleneBloky)) then
        Result := True;
    end;
    3:
    begin
      if ((Round((X + UpgradeSPeed + Speed + 11)) div pixel) >
        Length(Okolie.Steny[Round(Y) div pixel]) - 1) then
        exit;
      if ((Okolie.Steny[Round((Y - 1)) div pixel][Round(
        (X + UpgradeSPeed + Speed - 9)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y - 1)) div pixel][Round(
        (X + UpgradeSPeed + Speed + 10)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y + 13)) div pixel][Round(
        (X + UpgradeSPeed + Speed - 9)) div pixel].Typ in PovoleneBloky) and
        (Okolie.Steny[Round((Y + 13)) div pixel][Round(
        (X + UpgradeSPeed + Speed + 10)) div pixel].Typ in PovoleneBloky)) then
        Result := True;
    end;
  end;
end;

function TPlayer.OverVybuch(Okolie: TSteny): boolean;
begin
  Result := False;
  if (Okolie.Steny[Round(Y) div pixel][Round(X) div pixel].Typ = 3) then
    //ak sa hrac nachadza v policku kde je vybuch zabije ho
    Result := True;
end;

function TPlayer.OverKoniec(Okolie: TSteny; Nepriatel: TNepriatel): boolean;
begin
  Result := False;
  if ((length(Nepriatel.NPC) = 0) and
    (Okolie.Steny[GetY div pixel][GetX div pixel].Upgrade = Brana)) then
    //ak pocet nepriatelov na mape je 0 a stoji na brane
    Result := True;
end;

function TPlayer.GetX: integer;
begin
  Result := Round(X); //real -> int
end;

function TPlayer.GetY: integer;
begin
  Result := Round(Y);  //to iste
end;

constructor TPlayer.Create(Profil: string);
  //zakladne hodnoty pri vytvoreni hraca
var
  Obrazok: TBitMap;
  i, j: integer;
begin
  nick := Profil;
  PocetBomb := StartBomb;
  Skore := StartSkore;
  Zivot := StartZivot;
  Speed := StartSpeed;
  Level := StartLevel;
  LevelSkore := 0;
  X := SpawnSuradnice;
  Y := SpawnSuradnice;
  PosunX := 0;
  PosunY := 0;
  Zomrel := False;
  PohybujeSa := False;
  Opacne := False;
  Smer := 0;
  BombRadius := StartRadius;
  UpgradePocetBomb := 0;
  UpgradeRadius := 0;
  UpgradeSPeed := 0;
  setlength(Bomby, 0);
  Obrazok := TBitMap.Create;
  Obrazok.LoadFromFile('img/bomba.bmp');  //nacitavanie obrazkov bomby
  for i := 0 to 1 do
  begin
    BombyObr[i] := TBitMap.Create;
    BombyObr[i].Width := pixel;
    BombyObr[i].Height := pixel;
    BombyObr[i].PixelFormat := pf24bit;
    BombyObr[i].Canvas.Draw(-i * pixel, -0, Obrazok);
  end;
  Obrazok.LoadFromFile('img/player.bmp'); //nacotavanie obrazko hraca
  for j := 0 to 4 do
    for i := 0 to 2 do
    begin
      HracObr[j][i] := TBitMap.Create;
      HracObr[j][i].Width := pixel;
      HracObr[j][i].Height := pixel;
      HracObr[j][i].Transparent := True;
      HracObr[j][i].TransparentColor := Obrazok.Canvas.Pixels[0, 0];
      HracObr[j][i].PixelFormat := pf24bit;
      HracObr[j][i].Canvas.Draw(-i * pixel, -j * pixel, Obrazok);
    end;
  Obrazok.Free;
end;

end.
