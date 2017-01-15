unit uSPair;

interface

uses
  SysUtils, Types, uSExpression;

type
  TSPair = class(TSExpression)
  private
    FHead: TSExpression;
    FTail: TSExpression;
    constructor CreateActual(AText: string);
    destructor Destroy();
  protected
    procedure InitHeadAndTail(const AText: string); virtual;
    function GetTextElementByIndex(const AText: string; const Index: Integer): string;
  public
    property Head: TSExpression read FHead;
    property Tail: TSExpression read FTail;
  end;

implementation

constructor TSPair.CreateActual(AText: string);
begin
  inherited CreateActual(Text);

  try
    InitHeadAndTail(AText);
  except
    Free();
    raise;
  end;
end;

procedure TSPair.InitHeadAndTail(const AText: string);
begin
  FHead := TSExpression.CreateExp(GetTextElementByIndex(AText, 0));
  FTail := TSExpression.CreateExp(GetTextElementByIndex(AText, 2));
end;

destructor TSPair.Destroy;
begin
  FHead.Free();
  FTail.Free();
end;

function TSPair.GetTextElementByIndex(const AText: string;
  const Index: Integer): string;
var
  Elements: TArray<string>;
begin
  Elements := ToElements(AText);
  try
    Result := Elements[Index];
  finally
    SetLength(Elements, 0);
  end;
end;

end.
