unit nastaveniahry;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, player;

type

  { TNastavPop }

  TNastavPop = class(TForm)
    Button1: TButton;
    AutoSave: TCheckBox;
    RadioGroup1: TRadioGroup;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; {%H-}var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  NastavPop: TNastavPop;
  NastavHraca: TPlayer;

implementation

uses zaklad;

{$R *.lfm}

{ TNastavPop }

procedure TNastavPop.Button1Click(Sender: TObject); //ak chceme ulozit zmeny
begin
  NastavHraca.Obtiaznost := RadioGroup1.ItemIndex;  //nastavime vybranu obtiaznost
  if not (NastavHraca.CustomMapa) then //ak nie je docastny profil tak uloz nastavenia
  begin
    NastavHraca.AutoSave := AutoSave.Checked;
    //nastav automaticke ulozenie (automaticky ulozi profil po prejdeni mapy)
    NastavHraca.Save;
  end;
  NastavPop.Hide;//skry a ukaz hlavny form
  Form1.Show;
end;

procedure TNastavPop.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  NastavPop.Hide; //ked nechceme ulozit nastavenia
  Form1.Show;
end;

end.
