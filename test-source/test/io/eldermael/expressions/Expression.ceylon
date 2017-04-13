import ceylon.test {
    test
}

import io.eldermael.expressions {
    ...
}


test
shared void shouldReturnProperExpressionFromTokens() {
    // given
    value tokenExpressions = {
        { UnsignedInteger("1") },
        { UnsignedInteger("1"), PlusSign("+"), Variable("var") }
    };

    {Expression*} expectedExpressions = {
        Number(1),
        Sum(Number(1), Var("var"))
    };

    // when
    value actualExpressions = tokenExpressions.map(buildExpressionFrom);

    // then
    assertStreamsAreEqual(actualExpressions, expectedExpressions);

}