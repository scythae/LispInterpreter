unit uHotkey;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Menus;

type
  THotkey = record
  private
    FKey: Cardinal;
    FModifiers: Cardinal;
    FCaption: string;
  public
    procedure LoadFromShortcut(Shortcut: TShortcut);
    class function Create(Caption: string): THotkey; static;
    property Key: Cardinal read FKey;
    property Modifiers: Cardinal read FModifiers;
    property Caption: string read FCaption;
  end;

implementation

class function THotkey.Create(Caption: string): THotkey;
begin
  Result.LoadFromShortcut(
    TextToShortcut(Caption)
  );
end;

procedure THotkey.LoadFromShortcut(Shortcut: TShortcut);
var
  Vk: Word;
  ShiftState: TShiftState;
begin
  ShortcutToKey(Shortcut, Vk, ShiftState);

  FKey := Vk;
  FModifiers := 0;
  if ssShift in ShiftState then
    Inc(FModifiers, MOD_SHIFT);
  if ssAlt in ShiftState then
    Inc(FModifiers, MOD_ALT);
  if ssCtrl in ShiftState then
    Inc(FModifiers, MOD_CONTROL);

  FCaption := ShortcutToText(Shortcut);
end;

end.
