import ceylon.test {
    test
}

import io.eldermael.expressions {
    ...
}

test
shared void shouldReturnProperToken() {
    // given
    value lexicalUnitsWithMatchingToken = {
        ["var", Variable("var")],
        ["=", EqualsSign("=")],
        ["+", PlusSign("+")],
        ["1", UnsignedInteger("1")],
        ["!", Unknown("!")]
    };

    // when
    value tokenPairs = lexicalUnitsWithMatchingToken.map((tuple) {
        value [lexicalUnit, token] = tuple;
        return [Token.asToken(lexicalUnit), token];
    });

    // then
    tokenPairs.each(([Token, Token] pair) {
        value [actual, expected] = pair;

        "Lexical unit not matching token "
        assert (actual == expected);
    });
}