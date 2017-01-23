unit uSList;

interface

uses
  SysUtils, Types, Generics.Collections, Variants,

  uSExpression, uSAtom, uSPair;

type
  TFunctionRec = record
    Name: string;
    Arguments: string;
    Body: string;
    EvaluableArguments: Boolean;
  end;

  TSList = class(TSPair)
  private type
    TRealization = function (): Variant of object;
  private class var
    Functions_UserDefined: TDictionary<string, TFunctionRec>;
  private
    FHeadElement: TSExpression;
    FTailElements: TList<TSExpression>;
    function GetFunctionName(): string;
    procedure InitListElements();
    procedure FreeListElements();
    procedure CheckFunctionName();
    function GetExpectedArgumentsNumber(): Integer;
    function FunctionNameIs(AText: string): Boolean;
    procedure CheckFunctionArgumentsNumber();
    function EvaluatedBuiltIn(var Value: Variant): Boolean;
    function EvaluatedUserDefined(var Value: Variant): Boolean;
    function Function_Defun(): Variant;
    function Function_Add(): Variant;
    function Function_Multiply: Variant;
    procedure CheckArgumentsNumber(NumberOfRegistered, NumberOfActual: Integer);
  protected
    constructor CreateActual(Text: string); override;
    class function GetRefinedText(const AText: string): string; override;
    procedure InitHeadAndTail(const AText: string); override;
  public
    function TextAsPair(): string;
  public
    function Evaluate(): Variant; override;
    destructor Destroy(); override;
  end;

  TSFunction = class(TSList)
  protected
    FArguments: TDictionary<string, TSExpression>;
    FName: string;
  public
    procedure LoadArguments(AArguments: string);
    property Name: string read FName write FName;
    destructor Destroy(); override;
  end;

implementation

constructor TSList.CreateActual(Text: string);
begin
  inherited CreateActual(Text);
  InitListElements();
end;

destructor TSList.Destroy();
begin
  FreeListElements();
  inherited;
end;

procedure TSList.InitListElements();
var
  StrElements: TStringArray;
  HeadText: string;
  I: Integer;
begin
  FTailElements := TList<TSExpression>.Create();

  StrElements := ToElements(Text);
  if Length(StrElements) = 0 then
    HeadText := String_AtomNil
  else
    HeadText := StrElements[Low(StrElements)];

  try
    FHeadElement := TSExpression.CreateExp(HeadText);
    for I := Low(StrElements) + 1 to High(StrElements) do
      FTailElements.Add(TSExpression.CreateExp(StrElements[I]));
  finally
    SetLength(StrElements, 0);
  end;
end;

procedure TSList.FreeListElements();
var
  Element: TSExpression;
begin
  for Element in FTailElements do
    Element.Free();
  FreeAndNil(FTailElements);
  FreeAndNil(FHeadElement);
end;

procedure TSList.InitHeadAndTail(const AText: string);
begin
  inherited InitHeadAndTail(TextAsPair());
end;

function TSList.TextAsPair(): string;
var
  Elements: TStringArray;

  procedure JoinHeadAndTail(const Head, Tail: string);
  begin
    Result :=
      Char_OpeningParenthesis + Head +
      Char_Space + Char_PairDelimiter + Char_Space +
      Tail + Char_ClosingParenthesis;
  end;

  function RestOfElements(): string;
  begin
    Result :=
      Char_OpeningParenthesis +
      string.Join(Char_Space, Elements, 1, Length(Elements) - 1) +
      Char_ClosingParenthesis;
  end;

  procedure CheckElementsAndJoinHeadAndTail();
  begin
    case Length(Elements) of
      0: JoinHeadAndTail(String_AtomNil, String_AtomNil);
      1: JoinHeadAndTail(Elements[0], String_AtomNil);
      else JoinHeadAndTail(Elements[0], RestOfElements());
    end;
  end;
begin
  Elements := ToElements(Text);
  try
    CheckElementsAndJoinHeadAndTail();
  finally
    SetLength(Elements, 0);
  end;
end;

function TSList.Evaluate(): Variant;
begin
  CheckFunctionName();

  if not EvaluatedUserDefined(Result) then
    if not EvaluatedBuiltIn(Result) then
      RaiseException('Function is not defined: ' + GetFunctionName());
end;

procedure TSList.CheckFunctionName();
begin
  if DefineSubclassByText(GetFunctionName()) <> TSAtom then
    raise Exception.Create(
      'Function name must be an Atom. Current function name is: ' + GetFunctionName()
    );
end;

function TSList.EvaluatedUserDefined(var Value: Variant): Boolean;
var
  FunctionRec: TFunctionRec;
  Elements: TStringArray;
  LFunction: TSFunction;
begin
  Result := Functions_UserDefined.TryGetValue(GetFunctionName(), FunctionRec);
  if not Result then
    Exit();

  LFunction := TSExpression.CreateExp(FunctionRec.Body) as TSFunction;
  try
    LFunction.LoadArguments(FunctionRec.Arguments);
    Value := LFunction.Evaluate;
  finally
    FreeAndNil(LFunction);
  end;
end;

function TSList.EvaluatedBuiltIn(var Value: Variant): Boolean;
begin
  Result := True;

  if FunctionNameIs('defun') then
    Value := Function_Defun()
  else if FunctionNameIs('+') then
    Value := Function_Add()
  else if FunctionNameIs('*') then
    Value := Function_Multiply()
  else if FunctionNameIs('Nil') then
    Value := Null

  else
    Result := False;
end;

function TSList.Function_Add(): Variant;
var
  Element: TSExpression;
begin
  Result := 0;
  for Element in FTailElements do
    Result := Result + Element.Evaluate();
end;

function TSList.Function_Multiply(): Variant;
var
  Element: TSExpression;
begin
  Result := 1;
  for Element in FTailElements do
    Result := Result * Element.Evaluate();
end;

procedure TSList.CheckFunctionArgumentsNumber();
var
  RegisteredArgumentsNumber: Integer;
  ArgumentsNumber: Integer;
begin
  RegisteredArgumentsNumber := GetExpectedArgumentsNumber();
  ArgumentsNumber := FTailElements.Count;

  CheckArgumentsNumber(RegisteredArgumentsNumber, ArgumentsNumber)
end;

procedure TSList.CheckArgumentsNumber(NumberOfRegistered, NumberOfActual: Integer);
begin
  if NumberOfRegistered <> NumberOfActual then
    RaiseException(
      Format(
        'Function is called with wrong number of arguments:'#13#10 +
        '%s registered with %d arguments, called with %d arguments',
        [GetFunctionName(), NumberOfRegistered, NumberOfActual]
      )
    );
end;

function TSList.GetExpectedArgumentsNumber(): Integer;
var
  FunctionRec: TFunctionRec;
  Elements: TStringArray;
begin
  if not Functions_UserDefined.TryGetValue(GetFunctionName(), FunctionRec) then
    Exit(-1);

  Elements := ToElements(FunctionRec.Arguments);
  Result := Length(Elements);
  SetLength(Elements, 0);
end;

function TSList.FunctionNameIs(AText: string): Boolean;
begin
  Result := SameText(GetFunctionName(), AText);
end;

function TSList.GetFunctionName(): string;
begin
  Result := FHeadElement.Text;
end;

class function TSList.GetRefinedText(const AText: string): string;
begin
  Result := inherited.ToLower();
end;

function TSList.Function_Defun(): Variant;
var
  FunctionRec: TFunctionRec;
  RefinedText: string;
begin
  RefinedText := GetRefinedText(Text);
  FunctionRec.Name := GetFunctionName();
  FunctionRec.Arguments := GetTextElementByIndex(RefinedText, 3);
  FunctionRec.Body := GetTextElementByIndex(RefinedText, 4);
  FunctionRec.EvaluableArguments := True;

  Functions_UserDefined.AddOrSetValue(FunctionRec.Name, FunctionRec);

  Result := FunctionRec.Name;
end;

{ TSFunction }

destructor TSFunction.Destroy();
var
  Argument: TSExpression;
begin
  for Argument in FArguments.Values do
    Argument.Free();
  FreeAndNil(FArguments);

  inherited;
end;

procedure TSFunction.LoadArguments(AArguments: string);
var
  Elements: TStringArray;

  procedure LoadArgumentsToFunction();
  var
    I: Integer;
  begin
    for I := Low(Elements) + 1 to High(Elements) do
      FArguments.Add(
        Elements[I],
        TSExpression.CreateExp(Elements[I])
    );
  end;
begin
  Elements := ToElements(AArguments);
  try
    LoadArgumentsToFunction();
  finally
    SetLength(Elements, 0);
  end;
end;

initialization
  TSList.Functions_UserDefined := TDictionary<string, TFunctionRec>.Create;
finalization
  FreeAndNil(TSList.Functions_UserDefined);

end.
