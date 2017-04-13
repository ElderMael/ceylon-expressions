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
shared void shouldCreateEquationFromTokens() {
    // given
    value context = HashMap<String, Expression>();
    context.put("x", Number(1));
    value tokens = {
        Variable("var"),
        EqualsSign("="),
        UnsignedInteger("1"),
        PlusSign("+"),
        Variable("x")
    };

    // when
    value [variable, expression] = toEquation(tokens);

    // then
    assert (variable == "var");
    assert (expression.eval(context) == 2);

}

test
shared void shouldThrowExceptionIfTokenSequenceIsInvalid() {
    // given
    value tokens = {
        Variable("var"),
        EqualsSign("="),
        UnsignedInteger("1"),
        Variable("x")
    };

    // when
    value assertException = assertThatException(() => toEquation(tokens));

    // when
    assertException.hasType(`AssertionError`);
}
