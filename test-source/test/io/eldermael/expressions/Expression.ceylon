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

