import ceylon.test {
    test
}

import io.eldermael.expressions {
    ...
}

test
shared void shouldReturnProperToken() {
    // given
    {Token+} expected = { Variable("var"), EqualsSign("="), PlusSign("+"), UnsignedInteger("1") };
    value lexicalUnits = ["var", "=", "+", "1"];

    // when
    {Token+} tokens = lexicalUnits.map(Token.asToken);

    // then
    assert (tokens.containsEvery(expected));
}