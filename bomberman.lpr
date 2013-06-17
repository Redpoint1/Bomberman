program bomberman;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, zaklad, player, game, npc, upgradeform, share, highscore, nastaveniahry
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TUpgrade, Upgrade);
  Application.CreateForm(THiSc, HiSc);
  Application.CreateForm(TNastavPop, NastavPop);
  Application.Run;
end.

