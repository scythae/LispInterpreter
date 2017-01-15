unit uSAtom;

interface

uses
  SysUtils, Types, uSExpression;

type
  TSAtom = class(TSExpression)
  private
    function TryToInt(const AText: string; var Value: Variant): Boolean;
    function TryToFloat(const AText: string; var Value: Variant): Boolean;
    function TryToString(const AText: string; var Value: Variant): Boolean;
    function TryToVariable(const AText: string; var Value: Variant): Boolean;
  public
    function Evaluate(): Variant; override;
  end;

implementation

function TSAtom.Evaluate(): Variant;
begin
  if not TryToInt(Text, Result) then
  if not TryToFloat(Text, Result) then
  if not TryToString(Text, Result) then
  if not TryToVariable(Text, Result) then
    RaiseException('Atom is not defined: ' + Text);
end;

function TSAtom.TryToInt(const AText: string; var Value: Variant): Boolean;
var
  AtomInt: Integer;
begin
  Result := TryStrToInt(AText, AtomInt);
  if Result then
    Value := AtomInt;
end;

function TSAtom.TryToFloat(const AText: string; var Value: Variant): Boolean;
var
  AtomExt: Extended;
begin
  Result := TryStrToFloat(AText, AtomExt);
  if Result then
    Value := AtomExt;
end;

function TSAtom.TryToString(const AText: string; var Value: Variant): Boolean;
begin
  Result := not AText.Equals(AText.DeQuotedString(Char_AtomstringQuote));
  if Result then
    Value := AText;
end;

function TSAtom.TryToVariable(const AText: string; var Value: Variant): Boolean;
begin
  Result := False;
end;

end.
