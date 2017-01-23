unit uSAtom;

interface

uses
  SysUtils, Types, Variants,

  uSExpression;

type
  TAtomType = (atString, atInteger, atFloat, atTrue, atNil, atSymbol);

  TSAtom = class(TSExpression)
  private
    FValue: Variant;
    FAtomType: TAtomType;
    function TryToInt(const AText: string): Boolean;
    function TryToFloat(const AText: string): Boolean;
    function TryToString(const AText: string): Boolean;
    function TryToVariable(const AText: string; var Value: Variant): Boolean;
    function TryToNil(const AText: string): Boolean;
    function TryToTrue(const AText: string): Boolean;
  protected
    constructor CreateActual(AText: string); override;
  public
    function Evaluate(): Variant; override;
  end;

implementation

constructor TSAtom.CreateActual(AText: string);
begin
  inherited CreateActual(AText);

  AText := GetRefinedText(AText);
  if not TryToInt(Text) then
  if not TryToFloat(Text) then
  if not TryToString(Text) then
    FAtomType := atSymbol;
end;

function TSAtom.TryToNil(const AText: string): Boolean;
begin
  Result := SameText(AText, String_AtomNil);
  if Result then
  begin
    FAtomType := atNil;
    FValue := Null;
  end;
end;

function TSAtom.TryToTrue(const AText: string): Boolean;
begin
  Result := SameText(AText, String_AtomTrue);
  if Result then
  begin
    FAtomType := atTrue;
    FValue := True;
  end;
end;

function TSAtom.TryToInt(const AText: string): Boolean;
var
  AtomInt: Integer;
begin
  Result := TryStrToInt(AText, AtomInt);
  if Result then
  begin
    FAtomType := atInteger;
    FValue := AtomInt;
  end;
end;

function TSAtom.TryToFloat(const AText: string): Boolean;
var
  AtomFloat: Extended;
begin
  Result := TryStrToFloat(AText, AtomFloat);
  if Result then
  begin
    FAtomType := atFloat;
    FValue := AtomFloat;
  end;
end;

function TSAtom.TryToString(const AText: string): Boolean;
begin
  Result := not AText.Equals(AText.DeQuotedString(Char_AtomstringQuote));
  if Result then
  begin
    FAtomType := atString;
    FValue := AText;
  end;
end;

function TSAtom.Evaluate(): Variant;
begin
  if FAtomType <> atSymbol then
    Exit(FValue);

  if not TryToVariable(Text, Result) then
    RaiseException('Atom is not defined: ' + Text);
end;

function TSAtom.TryToVariable(const AText: string; var Value: Variant): Boolean;
begin
  Result := True;
  if SameText(Atext, String_AtomNil) then
    Value := Null
  else if SameText(Atext, String_AtomTrue) then
    Value := True
    
  else
    Result := False;
end;

end.
