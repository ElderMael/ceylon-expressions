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


    value expressions = lines(file)
        .map((line) => line.split())
        .map((lexicalUnits) => lexicalUnits.map(Token.asToken));

    print(expressions);

    return successExitCode;

}

abstract class Token of PlusSign | EqualsSign | Variable | UnsignedInteger | Unknown {

    shared static {[Boolean(String), Token(String)]+} predicatesAndConstructors = {
        [PlusSign.isInstanceOf, PlusSign],
        [EqualsSign.isInstanceOf, EqualsSign],
        [UnsignedInteger.isInstanceOf, UnsignedInteger],
        [Variable.isInstanceOf, Variable]
    };

    shared static Token asToken(String lexicalUnit) {

        value predicateAndConstructor = predicatesAndConstructors.find(([Boolean(String), Token(String)] element) {
            return element.first(lexicalUnit);
        });

        if (exists predicateAndConstructor) {
            value [tokenPredicate, tokenConstructor] = predicateAndConstructor;

            return tokenConstructor(lexicalUnit);
        }

        return Unknown(lexicalUnit);
    }

    shared String lexicalUnit;

    shared new (String lexicalUnit) {
        this.lexicalUnit = lexicalUnit;
    }

}

class PlusSign extends Token {

    shared static Boolean isInstanceOf(String lexicalUnit) => lexicalUnit == "+";

    shared new (String lexicalUnit) extends Token(lexicalUnit) {}

    string => "Plus(+)";

}

class EqualsSign extends Token {

    shared static Boolean isInstanceOf(String lexicalUnit) => lexicalUnit == "=";

    shared new (String lexicalUnit) extends Token(lexicalUnit) {}

    string => "Equals(=)";

}

class UnsignedInteger extends Token {

    shared static Boolean isInstanceOf(String lexicalUnit) =>
            Integer.parse(lexicalUnit) is Integer;

    shared Integer val;

    shared new (String lexicalUnit) extends Token(lexicalUnit) {

        assert (UnsignedInteger.isInstanceOf(lexicalUnit),
            is Integer val = Integer.parse(lexicalUnit));

        this.val = val;

    }

    string => "UnsignedInteger(``val.string``)";


}

class Variable extends Token {

    shared static Boolean isInstanceOf(String lexicalUnit) =>
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