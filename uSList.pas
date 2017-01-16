unit uSList;

interface

uses
  SysUtils, Types, Generics.Collections,

  uSExpression, uSPair;

type
  TFunctionRec = record
    Name: string;
    Arguments: string;
    Body: string;
  end;

  TSList = class(TSPair)
  private class var
    RegisteredFunctions: TDictionary<string, TFunctionRec>;
  private
    FFunction: TSExpression;
    FArguments: TArray<TSExpression>;
    function GetFunctionName(): string;
    procedure InitFunctionAndArguments();
    procedure CheckFunctionNameAndArgumentsNumber(const AFunctionName: string;
      const ArgumentsNumber: Integer);
    function FunctionNameIsRegistered(const AFunctionName: string): Boolean;
    function GetArgumentsNumberForRegisteredFunction(const AFunctionName: string): Integer;
    procedure FreeFunctionAndArguments;
    function FunctionNameIs(AText: string): Boolean;
    procedure DefineFunction;
  protected
    constructor CreateActual(Text: string); override;
    class function GetTextBeforeEvaluation(const AText: string): string; override;
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
  Elements: TArray<string>;

  procedure InitFunction();
  begin
    if not Testing then
      CheckFunctionNameAndArgumentsNumber(Elements[0], Length(Elements) - 1);
    FFunction := TSExpression.CreateExp(Elements[0]);
  end;

  procedure InitArguments();
  var
    I: Integer;
  begin
    SetLength(FArguments, Length(Elements) - 1);
    for I := 0 to Length(FArguments) - 1 do
      FArguments[I] := TSExpression.CreateExp(Elements[I + 1]);
  end;
begin
  Elements := ToElements(Text);
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
  FFunction.Free();

  for Argument in FArguments do
    Argument.Free();
  SetLength(FArguments, 0);
end;

procedure TSList.InitHeadAndTail(const AText: string);
begin
  inherited InitHeadAndTail(TextAsPair());
end;

function TSList.TextAsPair(): string;
var
  Elements: TArray<string>;

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

function TSList.Evaluate: Variant;
begin
  if FunctionNameIs('defun') then
    DefineFunction();
end;

procedure TSList.DefineFunction();
var
  FunctionRec: TFunctionRec;
begin
  FunctionRec.Name := GetFunctionName();
  FunctionRec.Arguments := GetTextElementByIndex(Text, 3);
  FunctionRec.Body := GetTextElementByIndex(Text, 4);

  RegisteredFunctions.AddOrSetValue(FunctionRec.Name, FunctionRec);
end;

procedure TSList.CheckFunctionNameAndArgumentsNumber(const AFunctionName: string;
  const ArgumentsNumber: Integer);
var
  RegisteredArgumentsNumber: Integer;
begin
  if not FunctionNameIsRegistered(AFunctionName) then
    RaiseException('Function is not defined: ' + AFunctionName);

  RegisteredArgumentsNumber := GetArgumentsNumberForRegisteredFunction(AFunctionName);
  if RegisteredArgumentsNumber <> ArgumentsNumber then
    RaiseException(
      Format(
        'Function is called with wrong number of arguments:'#13#10 +
        '%s registered with %d arguments, called with %d arguments',
        [AFunctionName, RegisteredArgumentsNumber, ArgumentsNumber]
      )
    );
end;

function TSList.FunctionNameIsRegistered(const AFunctionName: string): Boolean;
begin
  Result := RegisteredFunctions.ContainsKey(GetTextBeforeEvaluation(AFunctionName));
end;

function TSList.GetArgumentsNumberForRegisteredFunction(const AFunctionName: string): Integer;
begin
  Result := 0;
end;

function TSList.FunctionNameIs(AText: string): Boolean;
begin
  Result := SameText(GetTextBeforeEvaluation(FFunction.Text), AText);
end;

function TSList.GetFunctionName(): string;
begin
  Result := GetTextBeforeEvaluation(FFunction.Text);
end;

class function TSList.GetTextBeforeEvaluation(const AText: string): string;
begin
  Result := inherited.ToLower();
end;

initialization
  TSList.RegisteredFunctions := TDictionary<string, TFunctionRec>.Create;

finalization
  FreeAndNil(TSList.RegisteredFunctions);

end.
