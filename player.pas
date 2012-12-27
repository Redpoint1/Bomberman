unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Dialogs, game, npc;

type

  { Player }

  { TBomba }

  TBomba = class  //objekt bomby
    X, Y, Sekund, Radius, Faza: integer;
    //pozicia bomby, cas vybuchnutia, velkost vybuchu, faza animacie bomby
    constructor Create(XX, YY, Sec, Rad: integer);  //vytvorenie bomby
    procedure Odpocitavaj(Cas: integer);  //odpocitavanie casu bomby do vybuchnutia
    function OverStenu(Walle: TSteny; PosY, PosX, Smer: integer): boolean;
    //overenie vybuchov aby nebucha aj kde je stena
  end;

  { TPlayer }

  TPlayer = class
    Zivot, X, Y, SpawnX, SpawnY, Smer, Faza, Skore: integer;
    //pozicia hraca, suradnice ozivenia pri zabiti, orientacia pohy a fazy animacie
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
    function OverNpc(Nepriatel: TNepriatel): boolean;
    //zabitie hraca ked je nepriatel blizko
    function OverPosun(Okolie: TSteny): boolean;
    //overenie policka ci sa hrac moze presunut
    function OverVybuch(Okolie: TSteny): boolean; //zabitie hraca ak ho zasiahla bomba
    constructor Create(XX, YY: integer);  //vytvorenie hraca
  end;


implementation

{ TBomba }

constructor TBomba.Create(XX, YY, Sec, Rad: integer);
  //nastavenie premennych pri vytvoreni hraca
begin
  X := XX;
  Y := YY;
  Sekund := Sec * 1000;
  Radius := Rad;
  Faza := 0;
end;

procedure TBomba.Odpocitavaj(Cas: integer); //odpocitavanie casu do vybuchu
begin
  Sekund := Sekund - cas;
end;

function TBomba.OverStenu(Walle: TSteny; PosY, PosX, Smer: integer): boolean;
  //overenie ci nie je stena pri vybuchu
begin
  Result := False;
  if ((PosX < 0) or (PosY < 0) or (PosY >= length(Walle.Steny)) or
    //ak vybuch siaha za okaj mapy nevykresli vybuch
    (PosX >= length(Walle.Steny[PosY]))) then
    exit;
  if (Walle.Steny[PosY][PosX].Typ = 4) then
    //ak je znicitelna stena znic ju a dalej nechod s vybuchom
  begin
    Walle.Steny[PosY][PosX].Typ := 0;
    Walle.Steny[PosY][PosX].Obraz := Walle.StenyObr[0];
    Result := False;
    exit;
  end;
  if (Walle.Steny[PosY][PosX].Typ = 0) then
    //ak je volne policko nastavi policky na vybuch
  begin
    Walle.Steny[PosY][PosX].Typ := 3;
    Walle.Steny[PosY][PosX].Faza := 500;
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
    0: Y := Y - 1;
    1: Y := Y + 1;
    2: X := X - 1;
    3: X := X + 1;
  end;
end;

procedure TPlayer.Vykresli(Obr: TCanvas; Okolie: TSteny; Nepriatel: TNepriatel;
  Cas: TTimer);
begin
  if (((OverVybuch(Okolie)) or (OverNpc(Nepriatel))) and not (Zomrel)) then
    //overi ci nieco hraca nezabije a ak ano tak ho hodi na spaw a znizi mu zivot + zastavi pohyb hraca ak neprebieha animacia umrtia
  begin
    if (Cas.Enabled) then
    begin
      Cas.Enabled := False;
      PohybujeSa := False;
    end;
    Zomrel := True;
    Faza := -1;
    Smer := 4;
    Zivot := Zivot - 1;
  end;
  if (Zomrel) then
    if (Faza = 65) then
    begin
      Zomrel := False;
      Faza := 32;
      X := SpawnX;
      Y := SpawnY;
      Smer := 1;
    end
    else
    begin
      Inc(Faza);
    end;
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
  if (Zomrel) then
     Obr.Draw(X - 17, Y - 17, HracObr[Smer][Faza div 22])
  else
     Obr.Draw(X - 17, Y - 17, HracObr[Smer][Faza div 11]);
  //vykreslenie daneho obrazku pohybu hraca
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
      Walli.Steny[Bomby[j].y div pixel - 2][Bomby[j].x div pixel - 2].Typ := 0;
      //zmena policka mapy
      for i := (Bomby[j].x div pixel) downto (Bomby[j].x div pixel - Bomby[j].radius) do
        //nastavi policka na vybuchnutie
        //dolava
      begin
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div pixel - 2, i - 2, 2)) then
          //overuje ci nie je stena
        begin
          if (i = (Bomby[j].x div pixel - Bomby[j].radius)) then
            //zvacsuje radius vybuchu
          begin
            Walli.Steny[Bomby[j].y div pixel - 2][i - 2].Obraz := Walli.BombyObr[0][0];
            //nastavi obrazok policka mapy na vybuch
            Walli.Steny[Bomby[j].y div pixel - 2][i - 2].BombaSmer := 0;
            //nastavi smer bomby
          end;
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
        if (Bomby[j].OverStenu(Walli, Bomby[j].y div pixel - 2, i - 2, 3)) then
        begin
          if (i = (Bomby[j].x div pixel + Bomby[j].radius)) then
          begin
            Walli.Steny[Bomby[j].y div pixel - 2][i - 2].Obraz := Walli.BombyObr[0][3];
            Walli.Steny[Bomby[j].y div pixel - 2][i - 2].BombaSmer := 3;
          end;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div pixel) to (Bomby[j].y div pixel + Bomby[j].radius) do
        //dole
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div pixel - 2, 1)) then
        begin
          if (i = (Bomby[j].y div pixel + Bomby[j].radius)) then
          begin
            Walli.Steny[i - 2][Bomby[j].x div pixel - 2].Obraz := Walli.BombyObr[0][6];
            Walli.Steny[i - 2][Bomby[j].x div pixel - 2].BombaSmer := 6;
          end;
        end
        else
        begin
          break;
        end;
      end;
      for i := (Bomby[j].y div pixel) downto (Bomby[j].y div pixel - Bomby[j].radius) do
        //hore
      begin
        if (Bomby[j].OverStenu(Walli, i - 2, Bomby[j].x div pixel - 2, 0)) then
        begin
          if (i = (Bomby[j].y div pixel - Bomby[j].radius)) then
          begin
            Walli.Steny[i - 2][Bomby[j].x div pixel - 2].Obraz := Walli.BombyObr[0][5];
            Walli.Steny[i - 2][Bomby[j].x div pixel - 2].BombaSmer := 5;
          end;
        end
        else
        begin
          break;
        end;
      end;
      Walli.Steny[Bomby[j].y div pixel - 2][Bomby[j].x div pixel - 2].Obraz :=
        Walli.BombyObr[0][2];
      Walli.Steny[Bomby[j].y div pixel - 2][Bomby[j].x div pixel - 2].BombaSmer := 2;
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
  i, velkost: integer;
begin
  velkost := 0;
  for i := 0 to length(Bomby) - 1 do //cez pole bomb
    if (Bomby[i] = nil) then  //ak vybuchli
    begin
      Bomby[i] := Bomby[high(Bomby) - velkost];
      //prehodime bomby ,ktore este nevybuchli z konca
      Inc(velkost);
    end;
  setlength(Bomby, length(Bomby) - velkost); //zmensime velkost pola bomb
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
      if ((Y - 2) < 66) then //ak je koniec mapy
        exit;
      if ((Okolie.Steny[(Y - 2) div pixel - 2][(X - 10) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y - 2) div pixel - 2][(X + 7) div
        pixel - 2].Typ in PovoleneBloky)) then //ak sa moze posunut
        Result := True;
    end;
    //opakovanie pre vsetky smery
    1:
    begin
      if (((Y + 16) div pixel - 2) > Length(Okolie.Steny) - 1) then
        exit;
      if (Okolie.Steny[(Y + 12) div pixel - 2][(X - 10) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y + 12) div pixel -
        2][(X + 7) div pixel - 2].Typ in PovoleneBloky) then
        Result := True;
    end;
    2:
    begin
      if ((X - 11) < 66) then
        exit;
      if ((Okolie.Steny[(Y - 1) div pixel - 2][(X - 11) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y - 1) div pixel - 2][(X + 9) div
        pixel - 2].Typ in PovoleneBloky) and
        (Okolie.Steny[(Y + 11) div pixel - 2][(X - 11) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y + 11) div pixel -
        2][(X + 9) div pixel - 2].Typ in PovoleneBloky)) then
        Result := True;
    end;
    3:
    begin
      if (((X + 11) div pixel - 2) > Length(Okolie.Steny[Y div pixel - 2]) - 1) then
        exit;
      if ((Okolie.Steny[(Y - 1) div pixel - 2][(X - 9) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y - 1) div pixel - 2][(X + 10) div
        pixel - 2].Typ in PovoleneBloky) and
        (Okolie.Steny[(Y + 11) div pixel - 2][(X - 9) div pixel - 2].Typ in
        PovoleneBloky) and (Okolie.Steny[(Y + 11) div pixel -
        2][(X + 10) div pixel - 2].Typ in PovoleneBloky)) then
        Result := True;
    end;
  end;
end;

function TPlayer.OverVybuch(Okolie: TSteny): boolean;
begin
  Result := False;
  if (Okolie.Steny[Y div pixel - 2][X div pixel - 2].Typ = 3) then
    //ak sa hrac nachadza v policku kde je vybuch zabije ho
    Result := True;
end;

constructor TPlayer.Create(XX, YY: integer); //zakladne hodnoty pri vytvoreni hraca
var
  Obrazok: TBitMap;
  i, j: integer;
begin
  Skore := 0;
  Zivot := 3;
  X := XX;
  Y := YY;
  SpawnX := XX;
  SpawnY := YY;
  Zomrel := False;
  PohybujeSa := False;
  Opacne := False;
  Smer := 0;
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
