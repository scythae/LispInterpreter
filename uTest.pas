unit uTest;

interface

uses
  SysUtils, Variants,

  uSExpression, uSAtom, uSPair, uSList;

type
  TOnTextOutNotify = procedure(const Text: string) of object;

  TMainTest = class
  private
    FOnTextOut: TOnTextOutNotify;
    function TextIsClass(const Text: string;
      ExpressionClass: TSExpressionClass): Boolean;
    procedure TryCreateAndFreeExpression(const Atext: string);
    procedure Test_CheckExpressionsSyntax();
    procedure Test_ListToPair();
    procedure Test_EvaluateExpressions();
  protected
    procedure Log(const Text: string);
  public
    property OnTextOut: TOnTextOutNotify read FOnTextOut write FOnTextOut;
    procedure Test();
  end;

implementation



{ TMainTest }

procedure TMainTest.Log(const Text: string);
begin
  if Assigned(FOnTextOut) then
    FOnTextOut(Text);
end;

procedure TMainTest.Test;
begin
  Test_CheckExpressionsSyntax();
  Test_ListToPair();
  Test_EvaluateExpressions();
end;

procedure TMainTest.Test_CheckExpressionsSyntax();
  procedure CheckExpression(const Text: string; ExpressionClass: TSExpressionClass);
  begin
    Assert(
      TextIsClass(Text, ExpressionClass),
      Format('SExpression %s is not %s', [Text, ExpressionClass.ClassName])
    );
    TryCreateAndFreeExpression(Text);

    Log(ExpressionClass.ClassName.PadRight(10) + ': ' + Text);
  end;

begin
  Log('---Testing expressions syntax (taken from http://homelisp.ru/help/lisp.html)---');
  CheckExpression('Abc', TSAtom);
  CheckExpression('1Abc', TSAtom);
  CheckExpression('Q$W', TSAtom);
  CheckExpression('123', TSAtom);
  CheckExpression('-12.3', TSAtom);
  CheckExpression('6.02E+23', TSAtom);
  CheckExpression('A.A', TSAtom);
  CheckExpression('A A', TSWrong);
  CheckExpression('A(', TSWrong);
  CheckExpression('A''B', TSWrong);
  CheckExpression('"Проба пера"', TSAtom);
  CheckExpression('"Проба "пера""', TSWrong);
  CheckExpression('"Проба ""пера"""', TSAtom);
  CheckExpression('"Проба ''пера''"', TSAtom);
  CheckExpression('&HFFFFFF', TSAtom);
  CheckExpression('&H1122334455667788', TSAtom);

  CheckExpression('(a . b)', TSPair);
  CheckExpression('((1 . 2) . b)', TSPair);
  CheckExpression('((1 . 2) . (3 . 4))', TSPair);
  CheckExpression('(x . (y . z))', TSPair);
  CheckExpression('(1 .)', TSWrong);
  CheckExpression('( . 2)', TSWrong);
  CheckExpression('(1 . 2', TSWrong);
  CheckExpression('(name . "Анатолий")', TSPair);

  CheckExpression('()', TSList);
  CheckExpression('(1 2)', TSList);
  CheckExpression('((1 2) (2))', TSList);
  CheckExpression('( (1.) (2.3 4 5 () 2))', TSList);
  CheckExpression('(defun sum (a b) (+ a b))', TSList);
  CheckExpression('(defun sum(a b)(+ a b))', TSWrong);
end;

procedure TMainTest.Test_ListToPair();
  procedure CheckListToPair(const GivenList, ExpectedPair: string);
  var
    EvaluatedPair: string;
  begin
    Assert(TextIsClass(GivenList, TSList), 'Expression is not List: ' + GivenList);
    TryCreateAndFreeExpression(GivenList);

    with TSList.CreateExp(GivenList) as TSList do
    try
      EvaluatedPair := TextAsPair;
    finally
      Free();
    end;

    Assert(
      TextIsClass(EvaluatedPair, TSPair),
      'Expression cannot be converted to Pair: ' + GivenList
    );
    TryCreateAndFreeExpression(EvaluatedPair);

    Assert(
      EvaluatedPair = ExpectedPair,
      Format(
        'Result of conversion doesn''t match to expected Pair.'#13#10 +
        'GivenList: %s'#13#10 +
        'EvaluatedPair: %s'#13#10 +
        'ExpectedPair: %s'#13#10,
        [GivenList, EvaluatedPair, ExpectedPair]
      )
    );

    Log(GivenList + '->' + EvaluatedPair);
  end;
begin
  Log('---Testing List to Pair---');
  CheckListToPair('(a b c)', '(a . (b c))');
  CheckListToPair(' ( a  b    c )  ', '(a . (b c))');
  CheckListToPair('( ( a  b )    c (d e) )  ', '(( a  b ) . (c (d e)))');;
  CheckListToPair('(a )','(a . Nil)');
  CheckListToPair('()', '(Nil . Nil)');
end;

procedure TMainTest.Test_EvaluateExpressions;
  procedure CheckExpressionValue(const AText: string; Expected: Variant);
  var
    Expression: TSExpression;
    Evaluated: Variant;
  begin
    Expression := TSExpression.CreateExp(AText);
    try
      Evaluated := Expression.Evaluate;
      Assert(
        Evaluated = Expected,
        Format(
          'Expression evaluation does not match expected value.'#13#10 +
          'Expression: %s'#13#10 +
          'Evaluated: %s'#13#10 +
          'Expected: %s'#13#10,
          [Expression.Text, VarToStr(Evaluated), VarToStr(Expected)]
        )
      );
      Log(AText + '->' + VarToStr(Evaluated));
    finally
      FreeAndNil(Expression);
    end;
  end;
begin
  Log('---Testing expressions evaluation---');
  CheckExpressionValue('1', 1);
  CheckExpressionValue('"1"', '"1"');
  CheckExpressionValue('2.12', 2.12);
  CheckExpressionValue('6.02E+23', VarAsType(6.02e23, varDouble));
end;

function TMainTest.TextIsClass(const Text: string;
  ExpressionClass: TSExpressionClass): Boolean;
begin
  Result := TSExpression.DefineSubclassByText(Text) = ExpressionClass;
end;

procedure TMainTest.TryCreateAndFreeExpression(const Atext: string);
var
  Expression: TSExpression;
begin
  if not TextIsClass(AText, TSWrong) then
  begin
    Expression := TSExpression.CreateExp(AText);
    FreeAndNil(Expression);
  end;
end;

end.
