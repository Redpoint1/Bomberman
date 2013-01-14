unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, LCLType;

type

  { TStena }

  TStena = class //trieda policka mapy
    X, Y, Typ, Faza, BombaSmer: integer;
    //pozicia policka, typ policka, smer vybuchu a faza vybuchu
    Obraz: TBitMap; //obrazok policka
    constructor Create(XX, YY, TypSteny: integer);
  end;

  { TSteny }

  TSteny = class   //trieda celej mapy
    Steny: array of array of TStena;  //mapa z policok v poli
    StenyObr: array[0..5] of TBitMap; //obrazky roznych stien
    BombyObr: array[0..4] of array[0..6] of TBitMap; //obrazky a fazy vybuchov bomby
    procedure Vykresli(Obr: TCanvas); //vykreslenie celej mapy na obrazok
    procedure ZmenFazu;  //zmena fazy vybuchu
    procedure VykresliFazu; //vykreslenie vybuchu (samostatne od mapy)
    procedure Nacitaj(Subor: string; Vyska, Sirka: integer); //nacitanie mapy zo suboru
    procedure PriradObraz; //po nacitani zo subor prirad obrazok podla typu policka
    constructor Create();
  end;

const //zdielane konstanty v hre
  pixel: integer = 33; //kolko pixelov ma jedna kocka 33x33
  PovoleneBloky = [0, 2];
  //povolene bloky ,cez ktore moze hrac prechadzat (volne policko a bomba)
  KlavesnicePohybu = [VK_UP, VK_LEFT, VK_DOWN, VK_RIGHT]; //klavesy pohybu hraca

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
      if ((Steny[yokolie][xokolie].Typ = 3) and (Steny[yokolie][xokolie].Faza = 0)) then
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

procedure TSteny.Nacitaj(Subor: string; Vyska, Sirka: integer);
var
  t, x, y: integer;
  Sub: TextFile;
begin
  if fileexists(Subor + '.txt') then  //overenie ci existuje vobec ten subor
  begin
    AssignFile(Sub, Subor + '.txt');
    Reset(Sub);
    Read(Sub, Y);
    Readln(Sub, X);   //definovanie a otvorenie suboru
    Readln(Sub);
    repeat    //nacvita policka podla velkosti a vysky mapy ,ktore su definovane v subore (riadku)
      begin
        if (Length(Steny) <= ((Vyska div pixel) - 5)) then
          //osetrenie aby nenacitalo viacej od velkosti mapy
        begin
          SetLength(Steny, Length(Steny) + 1);
          repeat  //nacitavanie stplce
            begin
              Read(Sub, t);
              if (Length(Steny[high(Steny)]) <= ((Sirka div pixel) - 8)) then
                //osetrenie aby nenacitalo viacej policok od toho kolko je definovanych
              begin
                SetLength(Steny[high(Steny)], Length(Steny[high(Steny)]) + 1);
                //zvysenie pola policok mapy
                Steny[high(Steny)][high(Steny[high(Steny)])] :=
                  TStena.Create(high(Steny[high(Steny)]) * pixel +
                  17 + 2 * pixel, high(Steny) * pixel + 17 + 2 * pixel, t);
                //vytvorenie s poziciami
              end;
            end;
          until Length(Steny[high(Steny)]) = X;
          //pokial bolo definovane v subore nacita stplce
        end;
        readln(Sub);
      end;
    until Length(Steny) = Y; //nacita riadky pokial bolo definovane v subore
    CloseFile(Sub); //zatvori subor
  end;
  PriradObraz; //prirady obrazy podla nacitanych typov policok mapy
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
  for i := 0 to 4 do
    for j := 0 to 6 do  //vsetky smery a fazy
    begin
      BombyObr[i][j] := TBitMap.Create;
      BombyObr[i][j].Width := pixel;
      BombyObr[i][j].Height := pixel;
      BombyObr[i][j].PixelFormat := pf24bit;
      BombyObr[i][j].Canvas.Draw(-j * pixel, (-i - 1) * pixel, Obrazok);
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
  Typ := TypSteny;
  BombaSmer := 0;
end;

end.
