program LispInterpreter;

uses
  SysUtils,
  Vcl.Forms,
  uMain in 'uMain.pas' {frMain},
  uHotkey in 'uHotkey.pas',
  Utils in '..\Common\Utils.pas',
  uSExpression in 'uSExpression.pas',
  uSList in 'uSList.pas',
  uSPair in 'uSPair.pas',
  uSAtom in 'uSAtom.pas',
  uTest in 'uTest.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  FormatSettings.DecimalSeparator := '.';

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrMain, frMain);
  Application.Run;
end.
