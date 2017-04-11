import ceylon.collection {
    HashMap
}
import ceylon.file {
    ...
}

Integer successExitCode = 0;

Integer noArgumentsExitCode = 1;

Integer pathIsDirectoryExitCode = 2;

Integer fileDoesNotExistsExitCode = 3;

Integer unknownErrorExitCode = 4;

String usage = """
                  Usage: expression file
                  """;

alias Equation => [String, Expression];
alias EquationContext => HashMap<String,Expression>;

shared void run() {

    try {

        value fileName = process.arguments.first;

        if (!exists fileName) {
            exitProcessWith(noArgumentsExitCode, usage);
            return;
        }

        value file = parsePath(fileName).resource.linkedResource;

        switch (file)
        case (is File) {

            value context = evaluateFile(file);

            value output = generateOutputFrom(context);

            exitProcessWith(successExitCode, output);
        }
        case (is Directory) {
            exitProcessWith(pathIsDirectoryExitCode, "``file.string``: is a Directory ");
        }
        case (is Nil) {
            exitProcessWith(fileDoesNotExistsExitCode, "``file.string``: no such file.");
        }

    } catch (Exception|AssertionError error) {
        exitProcessWith(unknownErrorExitCode, "Error: ``error.message``");
    }

}

String? generateOutputFrom(EquationContext context) {

    value outputs = context.keys.sort(byIncreasing(String.string)).map((String variableName) {

        value result = context.get(variableName);

        "Variable ``variableName``` not defined"
        assert (exists result);

        return "``variableName`` = ``result.eval(context).string``\n";

    });


    return outputs.reduce(plus);
}


EquationContext evaluateFile(File file) {

    value tokensByLine = parse(file);

    value initialContext = HashMap<String,Expression>();

    EquationContext context = tokensByLine
        .map(toEquation)
        .fold(initialContext)(intoContext);

    return context;

}

EquationContext intoContext(EquationContext partialContext,
        [String, Expression] equation) {
    value [lhs, rhs] = equation;

    partialContext.put(lhs, rhs);

    return partialContext;
}


Equation toEquation({Token+} lineTokens) {
    value lhs = lineTokens.first;

    assert (is Variable lhs);

    value rhsTokens = lineTokens.skip(2);

    value rhsExpression = buildExpressionFrom(rhsTokens);

    return [lhs.name, rhsExpression];

}


suppressWarnings ("expressionTypeNothing")
void exitProcessWith(Integer exitCode, String? message = null) {

    if (exists message) {
        print(message);
    }

    process.exit(exitCode);

}