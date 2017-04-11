import ceylon.test {
    test
}

test
void shouldReturnProperToken() {
    // given
    value tokens = ["var", "=", "other", "+", "1"];

    // when
    tokens.map(Token.asToken);
}