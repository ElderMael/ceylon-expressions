import ceylon.collection {
    HashMap
}
import ceylon.test {
    test,
    assertThatException
}

import io.eldermael.expressions {
    ...
}


test
shared void shouldReturnProperExpressionFromTokens() {
    // given
    value tokenExpressions = {
        { UnsignedInteger("1") },
        { UnsignedInteger("1"), PlusSign("+"), Variable("var") },
        { Variable("var"), PlusSign("+"), Variable("var"), PlusSign("+"), UnsignedInteger("1") }
    };

    {Expression*} expectedExpressions = {
        Number(1),
        Sum(Number(1), Var("var")),
        Sum(Sum(Var("var"), Var("var")), Number(1))
    };

    // when
    value actualExpressions = tokenExpressions.map(buildExpressionFrom);

    // then
    assertStreamsAreEqual(actualExpressions, expectedExpressions);

}

test
shared void shouldThrowExceptionIfEquationIsNotBalanced() {
    // given
    value unbalanced = { UnsignedInteger("1"), PlusSign("+") };

    // when
    value assertException = assertThatException(() => buildExpressionFrom(unbalanced));

    // then
    assertException.hasType(`AssertionError`);
}

test
shared void shouldEvaluateNumberToItsValue() {
    // given
    value context = HashMap<String, Expression>();

    // when
    value val = Number(1).eval(context);

    // then
    assert (val == 1);

}

test
shared void shouldEvaluateVariableToItsValueFromContext() {
    // given
    value context = HashMap<String, Expression>();
    context.put("var", Number(1));

    // when
    value val = Var("var").eval(context);

    // then
    assert (val == 1);

}

test
shared void shouldThrowExceptionIfVariableDoesNotExistsInContext() {
    // given
    value context = HashMap<String, Expression>();
    value varName = "iamnothere";

    // when
    value assertException = assertThatException(() {
        return Var(varName).eval(context);
    });

    // then
    assertException
        .hasType(`AssertionError`);
}

test
shared void shouldEvaluateSumToTheSumOfLeftAndRightExpressions() {
    // given
    value context = HashMap<String, Expression>();
    context.put("var", Number(2));

    // when
    value val = Sum(Number(1), Var("var")).eval(context);

    // then
    assert (val == 3);
}

