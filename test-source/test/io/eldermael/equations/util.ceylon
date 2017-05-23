void assertStreamsAreEqual({Identifiable*} actualStream, {Identifiable*} expectedStream) {

    // This is because with ceylon.language.zipPairs:
    // "The length of the resulting stream is the length of
    // the shorter of the two given streams."

    "Streams have different sizes"
    assert (actualStream.size == expectedStream.size);

    zipPairs(actualStream, expectedStream)
        .each(([Identifiable, Identifiable] pair) {
        value [actual, expected] = pair;

        "Actual '``actual``' is different from expected '``expected``'"
        assert (actual == expected);
    });
}