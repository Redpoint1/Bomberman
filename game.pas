unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, share;

type

  { TStena }

  TStena = class //trieda policka mapy
    X, Y, Typ, Faza, BombaSmer, Upgrade: integer;
    //pozicia policka, typ policka, smer vybuchu a faza vybuchu
    Obraz: TBitMap; //obrazok policka
    constructor Create(XX, YY, TypSteny: integer);
  end;

  { TSteny }

  TSteny = class   //trieda celej mapy
    Steny: array of array of TStena;  //mapa z policok v poli
    BranaSteny: array of integer;
    StenyObr: array[0..5] of TBitMap; //obrazky roznych stien
    BombyObr: array[0..4] of array[0..6] of TBitMap; //obrazky a fazy vybuchov bomby
    UpgradeObr: array[0..4] of TBitMap; //obrazky upgradeov
    procedure Vykresli(Obr: TCanvas); //vykreslenie celej mapy na obrazok
    procedure ZmenFazu;  //zmena fazy vybuchu
    procedure VykresliFazu; //vykreslenie vybuchu (samostatne od mapy)
    procedure Nacitaj(Subor: string); //nacitanie mapy zo suboru
    procedure PriradObraz; //po nacitani zo subor prirad obrazok podla typu policka
    procedure PriradUpgrade; //priradi upgrade-y do policok
    procedure PriradBranu; //prirady branu do policka
    constructor Create();
  end;

implementation

{ TSteny }
procedure TSteny.Vykresli(Obr: TCanvas);
var
  i, j: integer;
begin
  for i := 0 to length(Steny) - 1 do   //vykresli vsetky policka
    for j := 0 to length(Steny[i]) - 1 do
      Obr.Draw(Steny[i][j].X - 17, Steny[i][j].Y - 17, Steny[i][j].Obraz);
  VykresliFazu;  //vykresli vybuch
end;

procedure TSteny.ZmenFazu;
var
  xokolie, yokolie: integer;
begin
  for yokolie := 0 to length(Steny) - 1 do
    for xokolie := 0 to length(Steny[yokolie]) - 1 do //cez vsetky policka
      if ((Steny[yokolie][xokolie].Typ = 3) and (Steny[yokolie][xokolie].Faza <= 0)) then
        //ak je koniec vybuchu
      begin
        Steny[yokolie][xokolie].Typ := 0;  //nastav typ policka na povodny
        Steny[yokolie][xokolie].Obraz := StenyObr[0];  //aj obrazok
        Steny[yokolie][xokolie].BombaSmer := 0;
        Steny[yokolie][xokolie].Faza := Steny[yokolie][xokolie].Faza - 1;
        //hod fazu policka na -1 aby sa neanimovalo (kedze uz vybuch skoncil)
      end
      else if (Steny[yokolie][xokolie].Faza > 0) then
        //ak este trva vybuch odpocitavaj cas ukoncenia (co je faza)
      begin
        Steny[yokolie][xokolie].Faza := Steny[yokolie][xokolie].Faza - 10;
      end;
end;

procedure TSteny.VykresliFazu;
var
  i, j: integer;
begin
  ZmenFazu;
  for i := 0 to length(Steny) - 1 do
    for j := 0 to length(Steny[i]) - 1 do  //cez vsetky policka
    begin
      if (Steny[i][j].Typ = 3) then //ked sa v policku vybuchuje
      begin
        case (Steny[i][j].Faza div 100) of
          //prirad dotycny obrazok vybuchu podla smeru a fazy
          4: Steny[i][j].Obraz := BombyObr[0][Steny[i][j].BombaSmer];
          3: Steny[i][j].Obraz := BombyObr[1][Steny[i][j].BombaSmer];
          2: Steny[i][j].Obraz := BombyObr[2][Steny[i][j].BombaSmer];
          1: Steny[i][j].Obraz := BombyObr[3][Steny[i][j].BombaSmer];
          0: Steny[i][j].Obraz := BombyObr[4][Steny[i][j].BombaSmer];
        end;
      end;
    end;
end;

procedure TSteny.Nacitaj(Subor: string);
var
  t, x, y: integer;
  Sub: TFileStream;
begin
  if fileexists('mapy/' + Subor + '.dat') then  //overenie ci existuje vobec ten subor
  begin
    Sub := TFileStream.Create('mapy/' + Subor + '.dat', fmOpenRead);
    Sub.ReadBuffer(y, 4); //kolko vlastne policok je
    Sub.ReadBuffer(x, 4);
    repeat    //nacvita policka podla velkosti a vysky mapy ,ktore su definovane v subore (riadku)
      begin
        SetLength(Steny, Length(Steny) + 1);
        repeat  //nacitavanie stplce
          begin
            Sub.ReadBuffer(t, 4);
            SetLength(Steny[high(Steny)], Length(Steny[high(Steny)]) + 1);
            //zvysenie pola policok mapy
            Steny[high(Steny)][high(Steny[high(Steny)])] :=
              TStena.Create(high(Steny[high(Steny)]) * pixel +
              17 + 2 * pixel, high(Steny) * pixel + 17 + 2 * pixel, t);
            //vytvorenie s poziciami
          end;
        until Length(Steny[high(Steny)]) = X;
      end;
    until Length(Steny) = Y; //nacita riadky
    Sub.Free; //zatvori subor
    PriradObraz; //prirady obrazy podla nacitanych typov policok mapy
    PriradUpgrade; //priradi upgrade-y
    PriradBranu; //priradi branu
  end;
end;

procedure TSteny.PriradObraz;
var
  i, j: integer;
begin
  for i := 0 to length(Steny) - 1 do
    for j := 0 to length(Steny[i]) - 1 do //pre vsetky policka
    begin
      if ((Steny[i][j].Typ < 2) or (Steny[i][j].Typ > 3)) then
        //pokial typ steny nie je vybuch a bomba priradi obrazok
        Steny[i][j].Obraz := StenyObr[Steny[i][j].Typ];
    end;
end;

procedure TSteny.PriradUpgrade;
var
  i, j, sanca: integer;
begin
  for i := 0 to length(steny) - 1 do
    for j := 0 to length(steny[i]) - 1 do //cez vsetky policka
    begin
      if (Steny[i][j].Typ in BlokUpgrade) then //ak je v mnozine kde moze byt upgrade
      begin
        sanca := random(100); //z 100%
        if ((sanca > 94) and (sanca < 99)) then  //4% sanca na normlane upgrade-y
          Steny[i][j].Upgrade := UncommonUpgrade[random(length(UncommonUpgrade))]
        //nahodny jeden z nich
        else if (sanca = 99) then //1% sanca na cenen upgrade-y
          Steny[i][j].Upgrade := RareUpgrade[random(length(RareUpgrade))];
      end;
    end;
end;

procedure TSteny.PriradBranu;
var
  x, y, j: integer;
begin
  setlength(branasteny, 0);
  for y := 0 to length(steny) - 1 do
    for x := 0 to length(steny[y]) - 1 do //cez vsetky policka
      if (steny[y][x].Typ in BranaMoznost) then
        //ak je to typ policka kde sa moze nachadzat
      begin
        setlength(branasteny, length(branasteny) + 1); //vloz do pomocneho pola
        branasteny[high(branasteny)] := y * length(steny[y]) + x;
      end;
  if (length(branasteny) > 0) then  //ak sa take policko naslo
  begin
    j := random(length(branasteny));
    y := branasteny[j] div length(steny[0]);
    x := branasteny[j] - y * length(steny[0]);
    Steny[Y][X].Upgrade := Brana;  //vyber nahodny z nich a prirad ho
  end
  else //ak nie je take policko (pre istotu)
  begin
    repeat
      y := random(length(steny) - 2) + 1;  //-2 aby to neboli okraje
      x := random(length(steny[y]) - 2) + 1;
    until not ((x = 1) and (y = 1)); //a pokial to nie je na spawne hraca
    steny[y][x].upgrade := brana;   //hod na nahodne policko
    Steny[y][x].Obraz := upgradeobr[brana - 1];
  end;
  setlength(branasteny, 0);
end;

constructor TSteny.Create;
var
  Obrazok: TBitMap;
  i, j: integer;
begin
  SetLength(Steny, 0);
  Obrazok := TBitMap.Create;
  Obrazok.LoadFromFile('img/steny.bmp'); //nacitanie typ stien z obrazku
  for i := 0 to length(StenyObr) - 1 do
  begin
    StenyObr[i] := TBitMap.Create;
    StenyObr[i].Width := pixel;
    StenyObr[i].Height := pixel;
    StenyObr[i].PixelFormat := pf24bit;
    StenyObr[i].Canvas.Draw(-(i mod 5) * pixel, -(i div 5) * pixel, Obrazok);
  end;
  Obrazok.LoadFromFile('img/bomba.bmp'); //nacitanie vybuchov
  for i := 0 to length(bombyobr) - 1 do
    for j := 0 to length(bombyobr[i]) - 1 do  //vsetky smery a fazy
    begin
      BombyObr[i][j] := TBitMap.Create;
      BombyObr[i][j].Width := pixel;
      BombyObr[i][j].Height := pixel;
      BombyObr[i][j].PixelFormat := pf24bit;
      BombyObr[i][j].Canvas.Draw(-j * pixel, (-i - 1) * pixel, Obrazok);
    end;
  Obrazok.LoadFromFile('img/upgrade.bmp');
  for i := 0 to length(upgradeobr) - 1 do
  begin
    UpgradeObr[i] := TBitMap.Create;
    UpgradeObr[i].Width := pixel;
    UpgradeObr[i].Height := pixel;
    UpgradeObr[i].PixelFormat := pf24bit;
    UpgradeObr[i].Canvas.Draw(-i * pixel, 0, Obrazok);
  end;
  Obrazok.Free;
end;

{ TStena }

constructor TStena.Create(XX, YY, TypSteny: integer);
  //definovanie premennych objektu pri vytvoreni
begin
  X := XX;
  Y := YY;
  Faza := 0;
  Upgrade := -1;
  Typ := TypSteny;
  BombaSmer := 0;
end;

end.
