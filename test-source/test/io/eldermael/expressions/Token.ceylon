import ceylon.test {
    test
}

import io.eldermael.expressions {
    ...
}

test
shared void shouldReturnProperToken() {
    // given
    value lexicalUnits = { "var", "=", "+", "1", "!" };
    value expected = { Variable("var"), EqualsSign("="), PlusSign("+"),
        UnsignedInteger("1"), Unknown("!")
    };

    // when
    value actual = lexicalUnits.map(Token.asToken);

    // then
    assertStreamsAreEqual(actual, expected);
}

test
shared void shouldParseCompleteLine() {
    // given
    value lines = ["const = 1 + !"];
    {Token+} expectedTokens = {
        Variable("const"), EqualsSign("="), UnsignedInteger("1"),
        PlusSign("+"), Unknown("!")
    };
    // when
    value actualTokens = parse(lines).first;

    // then
    assertStreamsAreEqual(actualTokens, expectedTokens);

}

test
shared void shouldReturnTokensAsPostfixNotation() {
    // given
    value infix = { UnsignedInteger("1"), PlusSign("+"), UnsignedInteger("1") };
    value expectedPostfix = { UnsignedInteger("1"), UnsignedInteger("1"), PlusSign("+") };

    // when
    value postfix = asPostfix(infix);

    // then
    assertStreamsAreEqual(postfix, expectedPostfix);
}

test
shared void shouldReturnSingleTokenIfInfixHasOnlyOneOperand() {
    // given
    value expected = UnsignedInteger("1");

    // when
    value postfix = asPostfix({ expected });

    // then
    assert (postfix.size == 1);
    value actual = postfix.first;
    assert (exists actual);
    assert (actual == expected);
}

test
shared void shouldReturnEmptyStreamWhenProvidedAnEmptyStream() {
    // when
    value postfix = asPostfix({});

    // then
    assert (postfix.empty);
}

test
shared void shouldRejectNotAllowedStrings() {

    assert (Variable.canBeBuiltFrom("var"));
    assert (!Variable.canBeBuiltFrom(""));
    assert (!Variable.canBeBuiltFrom("var1"));
    assert (!Variable.canBeBuiltFrom("123"));
    assert (!Variable.canBeBuiltFrom("chars    "));
    assert (!Variable.canBeBuiltFrom(" 123 vars"));

    assert (EqualsSign.canBeBuiltFrom("="));
    assert (!EqualsSign.canBeBuiltFrom("+"));
    assert (!EqualsSign.canBeBuiltFrom("a"));
    assert (!EqualsSign.canBeBuiltFrom("+="));
    assert (!EqualsSign.canBeBuiltFrom(" "));

    assert (PlusSign.canBeBuiltFrom("+"));
    assert (!PlusSign.canBeBuiltFrom("="));
    assert (!PlusSign.canBeBuiltFrom("++"));
    assert (!PlusSign.canBeBuiltFrom("a"));
    assert (!PlusSign.canBeBuiltFrom("1"));
    assert (!PlusSign.canBeBuiltFrom(" "));

    assert (UnsignedInteger.canBeBuiltFrom("1"));
    assert (!UnsignedInteger.canBeBuiltFrom("/"));
    assert (!UnsignedInteger.canBeBuiltFrom("3b"));
    assert (!UnsignedInteger.canBeBuiltFrom("="));
    assert (!UnsignedInteger.canBeBuiltFrom("+"));
    assert (!UnsignedInteger.canBeBuiltFrom(" "));


}

