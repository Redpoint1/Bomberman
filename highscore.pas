unit highscore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, share;

type

  { THiSc }

  THiSc = class(TForm)
    HS: TStringGrid;
    procedure FormClose(Sender: TObject; {%H-}var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  HiSc: THiSc;

implementation

uses zaklad;

{$R *.lfm}

{ THiSc }

procedure THiSc.FormShow(Sender: TObject);  //pri zbrazeni formulara
var
  S: TFileStream;
  Pomocnik: TPoleSkore;
  i: integer;
begin
  if fileexists('skore.dat') then //osetrenie aby to nepadlo
  begin
    S := TFileStream.Create('skore.dat', fmOpenRead); //nacitaj subor a zacni od zaciatku
    S.Position := 0;
    setlength(Pomocnik, 0); //premenna kam budeme nacitavat ludi
    if (S.Size > 0) then
      repeat
        setlength(Pomocnik, length(Pomocnik) + 1);
        S.ReadBuffer(Pomocnik[high(POmocnik)], sizeOf(RSkore));
      until (S.Position = S.Size); //nacitaj vsetkych ,ktory su v subore
    S.Free; //zavri subor
    HS.RowCount := length(Pomocnik) + 2;
    //zvacsime velkost tabulky o dany pocet ludi v skore subore
    for i := 0 to length(pomocnik) - 1 do
      //postupne ich vypisuje do tabulky (uz su automaticky zoradeny zo suboru)
    begin
      HS.Cells[0, i + 1] := Pomocnik[i].Nick;
      HS.Cells[1, i + 1] := IntToStr(Pomocnik[i].body);
    end;
  end;
end;

procedure THiSc.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  HiSc.hide; //ukru skore
  Form1.Show;
end;

procedure THiSc.FormCreate(Sender: TObject);
var
  c: TTextStyle;
begin
  c := HS.DefaultTextStyle; //aby tabulka mala texty v strede
  c.Alignment := taCenter;
  HS.DefaultTextStyle := c;
  HS.GridLineStyle := psClear;
  HS.RowCount := 2;
  HS.Cells[0, 0] := 'Nick'; //co bude v fix bunkach
  HS.Cells[1, 0] := 'Skóre';
  HS.Cells[0, 1] := 'Žiadny'; //keby nebol nikto v tbulke este
  HS.Cells[1, 1] := 'Žiadny';

end;

end.
