program Dungeon;

uses
  Forms,
  uMain in 'uMain.pas' {Form2},
  uDungeonGen in 'uDungeonGen.pas',
  uDelaunay in 'uDelaunay.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
