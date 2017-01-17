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
    FFunction: TSExpression;
    FArguments: TDictionary<string, TSExpression>;
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

  procedure InitFunction();
  begin
    FFunction := TSExpression.CreateExp(Elements[0]);
  end;

  procedure InitArguments();
  var
    I: Integer;
  begin
    FArguments := TDictionary<string, TSExpression>.Create();
    for I := 1 to Length(Elements) - 1 do
      FArguments.Add(Elements[I], TSExpression.CreateExp(Elements[I]));
  end;
begin
  Elements := ToElements(Text);

  if Length(Elements) = 0  then

  try
    InitFunction();
    InitArguments();
  finally
    SetLength(Elements, 0);
  end;
end;

procedure TSList.FreeFunctionAndArguments();
var
  Argument: TSExpression;
begin
  FreeAndNil(FFunction);

  for Argument in FArguments.Values do
    Argument.Free();
  FreeAndNil(FArguments);
end;

procedure TSList.InitHeadAndTail(const AText: string);
begin
  inherited InitHeadAndTail(TextAsPair());
end;

function TSList.TextAsPair(): string;
var
  Elements: TStringArray;

  procedure CompileHeadAndTail();
  var
    Head: string;
    Tail: string;
  begin
    Head := Elements[0];
    Tail :=
      Char_OpeningParenthesis +
      string.Join(Char_Space, Elements, 1, Length(Elements) - 1) +
      Char_ClosingParenthesis;

    Result :=
      Char_OpeningParenthesis +
      Head +
      Char_Space + Char_PairDelimiter + Char_Space +
      Tail +
      Char_ClosingParenthesis;
  end;
begin
  Elements := ToElements(Text);
  try
    CompileHeadAndTail();
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
    RaiseException('Function is not defined: ' + FFunction.Text);
end;

function TSList.FunctionIsUserDefined(): Boolean;
begin
  Result := Functions_UserDefined.ContainsKey(GetRefinedText(FFunction.Text));
end;

function TSList.FunctionIsBuiltIn(): Boolean;
begin
  Result := Functions_BuiltIn.ContainsKey(GetRefinedText(FFunction.Text));
end;

function TSList.EvaluateUserDefinedFunction(): Variant;
var
  FunctionRec: TFunctionRec;
  Elements: TStringArray;
begin
  if not Functions_UserDefined.TryGetValue(FFunction.Text, FunctionRec) then
    Exit(-1);

//  FunctionRec.Body;
//  FArguments[]


  Elements := ToElements(FunctionRec.Arguments);
  Result := Length(Elements);
  SetLength(Elements, 0);


  Result := FFunction.Evaluate;
end;

function TSList.EvaluateBuiltInFunction(): Variant;
begin
  if FunctionNameIs('defun') then
    DefineFunction();
end;

procedure TSList.CheckFunctionName();
begin
  if not (FFunction is TSAtom) then
    raise Exception.Create(
      'Function name must be an Atom. Current function name is: ' + FFunction.Text
    );
end;

procedure TSList.CheckFunctionArgumentsNumber();
var
  ArgumentsNumber: Integer;
  RegisteredArgumentsNumber: Integer;
begin
  ArgumentsNumber := FArguments.Count;
  RegisteredArgumentsNumber := GetExpectedArgumentsNumber();


  if RegisteredArgumentsNumber <> ArgumentsNumber then
    RaiseException(
      Format(
        'Function is called with wrong number of arguments:'#13#10 +
        '%s registered with %d arguments, called with %d arguments',
        [FFunction.Text, RegisteredArgumentsNumber, ArgumentsNumber]
      )
    );
end;

function TSList.GetExpectedArgumentsNumber(): Integer;
var
  FunctionRec: TFunctionRec;
  Elements: TStringArray;
begin
  if not Functions_UserDefined.TryGetValue(FFunction.Text, FunctionRec) then
    Exit(-1);

  Elements := ToElements(FunctionRec.Arguments);
  Result := Length(Elements);
  SetLength(Elements, 0);
end;

function TSList.FunctionNameIs(AText: string): Boolean;
begin
  Result := SameText(GetRefinedText(FFunction.Text), AText);
end;

function TSList.GetFunctionName(): string;
begin
  Result := GetRefinedText(FFunction.Text);
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
