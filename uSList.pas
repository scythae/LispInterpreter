unit uSList;

interface

uses
  SysUtils, Types, Generics.Collections,

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
    Functions_BuiltIn: TDictionary<string, TRealization>;
  private
//    FFunction: TSExpression;
//    FArguments: TDictionary<string, TSExpression>;
    FElements: TList<TSExpression>;
    function GetFunctionName(): string;
    procedure InitFunctionAndArguments();
    procedure CheckFunctionName();
    function FunctionIsUserDefined(): Boolean;
    function GetExpectedArgumentsNumber(): Integer;
    procedure FreeFunctionAndArguments();
    function FunctionNameIs(AText: string): Boolean;
    function DefineFunction(): Variant;
    procedure CheckFunctionArgumentsNumber();
    function FunctionIsBuiltIn(): Boolean;
    function EvaluateBuiltInFunction(): Variant;
    function EvaluateUserDefinedFunction(): Variant;
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

implementation

constructor TSList.CreateActual(Text: string);
begin
  inherited CreateActual(Text);
  InitFunctionAndArguments();
end;

destructor TSList.Destroy();
begin
  FreeFunctionAndArguments();
  inherited;
end;

procedure TSList.InitFunctionAndArguments();
var
  Elements: TStringArray;
  ElementText: string;
begin
  Elements := ToElements(Text);
  try
    FElements := TList<TSExpression>.Create();
    for ElementText in Elements do
      FElements.Add(TSExpression.CreateExp(ElementText));
  finally
    SetLength(Elements, 0);
  end;
end;

procedure TSList.FreeFunctionAndArguments();
var
  Element: TSExpression;
begin
  for Element in FElements do
    Element.Free();
  FreeAndNil(FElements);
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
  CheckFunctionArgumentsNumber();

  if FunctionIsUserDefined() then
    Result := EvaluateUserDefinedFunction()
  else if FunctionIsBuiltIn() then
    Result := EvaluateBuiltInFunction()
  else
    RaiseException('Function is not defined: ' + GetFunctionName());
end;

function TSList.FunctionIsUserDefined(): Boolean;
begin
  Result := Functions_UserDefined.ContainsKey(GetFunctionName());
end;

function TSList.FunctionIsBuiltIn(): Boolean;
begin
  Result := Functions_BuiltIn.ContainsKey(GetFunctionName());
end;

function TSList.EvaluateUserDefinedFunction(): Variant;
var
  FunctionRec: TFunctionRec;
  Elements: TStringArray;
begin
  if not Functions_UserDefined.TryGetValue(GetFunctionName(), FunctionRec) then
    Exit(-1);

//  FunctionRec.Body;
//  FArguments[]


  Elements := ToElements(FunctionRec.Arguments);
  Result := Length(Elements);
  SetLength(Elements, 0);


//  Result := FFunction.Evaluate;
end;

function TSList.EvaluateBuiltInFunction(): Variant;
begin
  if FunctionNameIs('defun') then
    DefineFunction();
end;

procedure TSList.CheckFunctionName();
begin
//  if not (FFunction is TSAtom) then
    raise Exception.Create(
      'Function name must be an Atom. Current function name is: ' + GetFunctionName()
    );
end;

procedure TSList.CheckFunctionArgumentsNumber();
var
  ArgumentsNumber: Integer;
  RegisteredArgumentsNumber: Integer;
begin
//  ArgumentsNumber := FArguments.Count;
  RegisteredArgumentsNumber := GetExpectedArgumentsNumber();


  if RegisteredArgumentsNumber <> ArgumentsNumber then
    RaiseException(
      Format(
        'Function is called with wrong number of arguments:'#13#10 +
        '%s registered with %d arguments, called with %d arguments',
        [GetFunctionName(), RegisteredArgumentsNumber, ArgumentsNumber]
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
  Result := '';//GetRefinedText(FFunction.Text);
end;

class function TSList.GetRefinedText(const AText: string): string;
begin
  Result := inherited.ToLower();
end;

function TSList.DefineFunction(): Variant;
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


initialization
  TSList.Functions_UserDefined := TDictionary<string, TFunctionRec>.Create;

finalization
  FreeAndNil(TSList.Functions_UserDefined);

end.
