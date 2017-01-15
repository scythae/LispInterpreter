unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.UITypes,
  Vcl.Menus, Clipbrd, Generics.Collections,

  uHotkey,
  uTest;

type
  TfrMain = class(TForm)
    chbHookRegistered: TCheckBox;
    lbHotkeys: TListBox;
    mInfo: TMemo;
    procedure chbHookRegisteredClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private type
    THotkeyName = (hnInterpret);
  private
    Hotkeys: TDictionary<THotkeyName, THotkey>;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure FillHotkeysListbox;
    function CurrentShortcut(): TShortcut;
    procedure AddInfo(Text: string);
    procedure AddLine(const Text: string);
    procedure RegHotkey(HotkeyName: THotkeyName);
    procedure UnregHotkey(HotkeyName: THotkeyName);
  end;

var
  frMain: TfrMain;

implementation

uses
  DateUtils, Utils, uSExpression, uSList;

{$R *.dfm}

procedure TfrMain.FormCreate(Sender: TObject);
begin
  Application.OnMessage := OnAppMessage;

  Hotkeys := TDictionary<THotkeyName, THotkey>.Create();
  Hotkeys.AddOrSetValue(hnInterpret, THotkey.Create('Scroll Lock'));
  RegHotkey(hnInterpret);

  lbHotkeys.MultiSelect := False;
  mInfo.Clear();

  with  TMainTest.Create() do
  try
    OnTextOut := AddLine;
    Test();
  finally
    Free();
  end;
end;

procedure TfrMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Hotkeys);
end;

procedure TfrMain.chbHookRegisteredClick(Sender: TObject);
begin
  if chbHookRegistered.Checked then
    RegHotkey(hnInterpret)
  else
    UnregHotkey(hnInterpret);
end;

procedure TfrMain.RegHotkey(HotkeyName: THotkeyName);
var
  H: THotkey;
begin
  H := Hotkeys[HotkeyName];
  if RegisterHotkey(Handle, Integer(HotkeyName), H.Modifiers or MOD_NOREPEAT, H.Key) then
    Exit();

  ShowMessage(
    Format(
      'Unsuccessful registration of hotkey "%s". Error code: %d',
      [H.Caption, GetLastError()]
    )
  );
end;

procedure TfrMain.UnregHotkey(HotkeyName: THotkeyName);
begin
  UnregisterHotkey(Handle, Integer(HotkeyName));
end;

function TfrMain.CurrentShortcut(): TShortcut;
begin
  Result := TextToShortcut(lbHotkeys.Items[lbHotkeys.ItemIndex]);
end;

procedure TfrMain.FillHotkeysListbox();
var
  Shortcut: TShortcut;
  ShortcutName: string;
begin
  for Shortcut := Low(TShortcut) to High(TShortcut) do
  begin
    ShortcutName := ShortcutToText(Shortcut);
    if (ShortcutName <> '')
    and (lbHotkeys.Items.IndexOf(ShortcutName) = -1)
    then
      lbHotkeys.Items.Add(ShortcutName);
  end;

  lbHotkeys.ItemIndex := 0;
end;

procedure TfrMain.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_HOTKEY then
    AddInfo(GetSelectedTextFromForegroundWindow());
end;

procedure TfrMain.AddInfo(Text: string);
begin
  AddLine('--' + TimeToStr(TimeOf(Now)) + '--');
  AddLine('');
  AddLine(Text);
  AddLine('');
end;

procedure TfrMain.AddLine(const Text: string);
begin
  mInfo.Lines.Add(Text);
end;

end.
