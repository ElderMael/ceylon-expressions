import ceylon.file {
    ...
}

Integer successExitCode = 0;

Integer noArgumentsExitCode = 1;

Integer fileNameIsDirectoryExitCode = 2;

Integer fileDoesNotExistsExitCode = 3;

Integer unknownErrorExitCode = 4;

String usage = """
                  Usage: expression file
                  """;


shared void run() {

    try {

        value [exitCode, message] = processFile(process.arguments);
        exitProcess(exitCode, message);

    } catch (Exception|AssertionError error) {
        exitProcess(unknownErrorExitCode, "Error: ``error.message``");
    }

}

[Integer, String?] processFile(String[] arguments) {

    if (is Empty arguments) {
        return [noArgumentsExitCode, usage];
    }

    value fileName = arguments.first;

    value file = parsePath(fileName).resource.linkedResource;

    switch (file)
    case (is File) {
        Integer exitCode = evaluateFile(file);
        return [exitCode, null];
    }
    case (is Directory) {
        return [fileNameIsDirectoryExitCode, "``file.string``: is a Directory "];
    }
    case (is Nil) {
        return [fileDoesNotExistsExitCode, "``file.string``: no such file."];
    }

}

suppressWarnings ("expressionTypeNothing")
void exitProcess(Integer exitCode, String? message = null) {

    if (exists message) {
        print(message);
    }

    process.exit(exitCode);

}


Integer evaluateFile(File file) {

    print(file.path.absolutePath.uriString);


    value fileLines = lines(file);

    "File must contain expressions"
    assert (nonempty fileLines);

    value equations = fileLines
        .map((line) => line.split())
        .map((lexicalUnits) => lexicalUnits.map(Token.asToken));

    print(equations);

    return successExitCode;

}

alias TokenStrategy => [Boolean(String), Token(String)];

abstract class Token of PlusSign | EqualsSign | Variable | UnsignedInteger | Unknown {

    shared static {TokenStrategy+} tokenStrategies = {
        [PlusSign.canBeBuildFrom, PlusSign],
        [EqualsSign.canBeBuiltFrom, EqualsSign],
        [UnsignedInteger.canBeBuiltFrom, UnsignedInteger],
        [Variable.canBeBuiltFrom, Variable]
    };

    shared static Token asToken(String lexicalUnit) {

        value strategy = tokenStrategies.find((TokenStrategy element) {
            value predicate = element.first;

            return predicate(lexicalUnit);
        });

        if (exists strategy) {
            value [predicate, buildTokenFrom] = strategy;

            return buildTokenFrom(lexicalUnit);
        }

        return Unknown(lexicalUnit);
    }

    shared String lexicalUnit;

    shared new (String lexicalUnit) {
        this.lexicalUnit = lexicalUnit;
    }

}

class PlusSign extends Token {

    shared static Boolean canBeBuildFrom(String lexicalUnit) => lexicalUnit == "+";

    shared new (String lexicalUnit) extends Token(lexicalUnit) {}

    string => "Plus(+)";

}

class EqualsSign extends Token {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) => lexicalUnit == "=";

    shared new (String lexicalUnit) extends Token(lexicalUnit) {}

    string => "Equals(=)";

}

class UnsignedInteger extends Token {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) =>
            Integer.parse(lexicalUnit) is Integer;

    shared Integer val;

    shared new (String lexicalUnit) extends Token(lexicalUnit) {

        assert (UnsignedInteger.canBeBuiltFrom(lexicalUnit),
            is Integer val = Integer.parse(lexicalUnit));

        this.val = val;

    }

    string => "UnsignedInteger(``val.string``)";


}

class Variable extends Token {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) =>
            lexicalUnit.every(Character.letter);

    shared String name;

    shared new (String name)
            extends Token(name) {
        this.name = name;
    }


    string => "Variable(``name``)";
}

class Unknown(String lexicalUnit) extends Token(lexicalUnit) {

    string => "Unknown(``lexicalUnit``)";

}