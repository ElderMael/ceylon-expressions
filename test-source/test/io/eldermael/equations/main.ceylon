import ceylon.collection {
    HashMap
}
import ceylon.test {
    test,
    assertThatException
}

import io.eldermael.equations {
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

test
shared void shouldReduceOutputToSingleStringSorted() {
    // given
    value context = HashMap<String, Expression>();
    context.put("a", Number(1));
    context.put("b", Number(2));
    context.put("z", Number(3));
    value expected = """a = 1
                        b = 2
                        z = 3
                        """;

    // when
    value actual = generateOutputFrom(context);

    // then
    assert (exists actual);
    assert (actual == expected);
}

shared void shouldReturnNullIfContextIsEmpty() {
    // given
    value context = HashMap<String, Expression>();

    // when
    value actual = generateOutputFrom(context);

    // then
    assert (!exists actual);
}
