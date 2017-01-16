unit uSExpression;

interface

uses
  SysUtils, Types, Variants;

type
  TSExpressionClass = class of TSExpression;
  TSExpression = class
  private
    FText: string;
    procedure SetText(AText: string); virtual;
    class function IsNil(const AText: string): Boolean; static;
    class function IsPair(const AText: string): Boolean; static;
    class function IsList(const AText: string): Boolean; static;
    class function IsNonNilAtom(AText: string): Boolean; static;
    class function FirstAndLastSymbolsAreParentheses(const AText: string): Boolean; static;
    class function TextWithoutFirstAndLastSymbols(const AText: string): string; static;
    class function ExpressionIsCorrect(const AText: string): Boolean;
  protected const
    Char_Space = ' ';
    Char_OpeningParenthesis = '(';
    Char_ClosingParenthesis = ')';
    Char_PairDelimiter = '.';
    Char_ExpressionQuote = '''';
    Char_AtomstringQuote = '"';
  protected
    constructor CreateActual(AText: string); virtual;
    class function ToElements(const AText: string): TArray<string>; static;
    class function GetTextBeforeEvaluation(const AText: string): string; virtual;
    class procedure RaiseException(ExceptionText: string);
  public
    class function DefineSubclassByText(AText: string): TSExpressionClass; static;
  public
    constructor Create();
    class function CreateExp(const AText: string): TSExpression;
    function Evaluate(): Variant; virtual;  
    property Text: string read FText write SetText;
  end;

  TSWrong = class(TSExpression)                   
  end;


implementation

uses
  uSAtom, uSPair, uSList;
    
{ TSExpression }

constructor TSExpression.Create();
begin
  RaiseException('Use "TSExpression.CreateExp" method instead of default constructor.');
end;

constructor TSExpression.CreateActual(AText: string);
begin
  inherited Create();
  Self.Text := AText;
end;

class function TSExpression.CreateExp(const AText: string): TSExpression;
var
  SExpressionClass: TSExpressionClass;
begin
  SExpressionClass := DefineSubclassByText(AText);
  if SExpressionClass = TSWrong then
    RaiseException('Incorrect S-Exression syntax: '#13#10 + AText);

  Result := SExpressionClass.CreateActual(AText);
end;

class function TSExpression.DefineSubclassByText(AText: string): TSExpressionClass;
begin
  AText := GetTextBeforeEvaluation(AText);

  if FirstAndLastSymbolsAreParentheses(AText) then
    if IsNil(AText) then
      Exit(TSAtom)
    else if IsPair(AText) then
      Exit(TSPair)
    else if IsList(AText) then
      Exit(TSList)
    else
      Exit(TSWrong)
  else if IsNonNilAtom(AText) then
    Exit(TSAtom)
  else
    Exit(TSWrong);
end;

class function TSExpression.IsNil(const AText: string): Boolean;
begin
  Result := TextWithoutFirstAndLastSymbols(AText).Trim() = '';
end;

class function TSExpression.IsPair(const AText: string): Boolean;
var
  Elements: TArray<string>;
begin
  Elements := ToElements(AText);
  try
    Result :=
      (Length(Elements) = 3)
      and ExpressionIsCorrect(Elements[0])
      and (Elements[1] = Char_PairDelimiter)
      and ExpressionIsCorrect(Elements[2]);
  finally
    SetLength(Elements, 0);
  end;
end;

class function TSExpression.ToElements(const AText: string): TArray<string>;
begin
  Result := TextWithoutFirstAndLastSymbols(AText).Split(
    [Char_Space],
    Char_OpeningParenthesis,
    Char_ClosingParenthesis,
    TStringSplitOptions.ExcludeEmpty
  );
end;

class function TSExpression.IsList(const AText: string): Boolean;
var
  Elements: TArray<string>;
  Element: string;
begin
  Result := True;

  Elements := ToElements(AText);
  try
    for Element in Elements do
      if not ExpressionIsCorrect(Element) then
      begin
        Result := False;
        Break;
      end;
  finally
    SetLength(Elements, 0);
  end;
end;

class function TSExpression.IsNonNilAtom(AText: string): Boolean;
var
  ContainsUnquotedSpecialChars: Boolean;
  InnerAtomstringQuotesAreCorrect: Boolean;
  DequotedText: string;
begin
  if AText.Trim() = Char_PairDelimiter then
    Exit(False);

  ContainsUnquotedSpecialChars := AText.IndexOfAnyUnquoted(
    [Char_Space, Char_OpeningParenthesis, Char_ClosingParenthesis, Char_ExpressionQuote],
    Char_AtomstringQuote,
    Char_AtomstringQuote
  ) <> -1;

  if ContainsUnquotedSpecialChars then
    Exit(False);

  DequotedText := AText.DeQuotedString(Char_AtomstringQuote);
  InnerAtomstringQuotesAreCorrect :=
    AText.Equals(DequotedText) or AText.Equals(DequotedText.QuotedString(Char_AtomstringQuote));

  Result := InnerAtomstringQuotesAreCorrect;
end;

class function TSExpression.ExpressionIsCorrect(const AText: string): Boolean;
begin
  Result := DefineSubclassByText(AText) <> TSWrong;
end;

class function TSExpression.FirstAndLastSymbolsAreParentheses(const AText: string): Boolean;
begin
  Result := AText.StartsWith(Char_OpeningParenthesis) and AText.EndsWith(Char_ClosingParenthesis);
end;

class function TSExpression.TextWithoutFirstAndLastSymbols(const AText: string): string;
begin
  Result := AText.Substring(1, Length(AText) - 2);
end;

class function TSExpression.GetTextBeforeEvaluation(const AText: string): string;
begin
  Result := AText.Trim();
end;

function TSExpression.Evaluate(): Variant;
begin
  RaiseException('S-Expression cannot be evaluated: ' + Text);
end;

procedure TSExpression.SetText(AText: string);
begin
  FText := AText.Trim();
end;

class procedure TSExpression.RaiseException(ExceptionText: string);
begin
  raise Exception.Create(ExceptionText);
end;

initialization

finalization

end.
