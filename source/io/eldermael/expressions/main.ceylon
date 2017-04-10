import ceylon.collection {
    HashMap,
    LinkedList
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

suppressWarnings ("expressionTypeNothing")
void exitProcessWith(Integer exitCode, String? message = null) {

    if (exists message) {
        print(message);
    }

    process.exit(exitCode);

}


EquationContext evaluateFile(File file) {

    value tokensByLine = parse(file);

    EquationContext context = tokensByLine
        .map(toEquation)
        .fold(HashMap<String,Expression>())(toContext);

    return context;

}

EquationContext toContext(EquationContext partialContext,
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

{{Token+}+} parse(File file) {
    value fileLines = lines(file);

    "File must contain expressions"
    assert (nonempty fileLines);

    value equations = fileLines
        .map((line) => line.split())
        .map((lexicalUnits) => lexicalUnits.map(Token.asToken));

    return equations;
}

Expression buildExpressionFrom({Token*} rhs) {

    value postfix = asPostfix(rhs);

    value stack = postfix.fold(LinkedList<Expression>())((partial, token) {

        "RHS cannot have token type ``token.string``"
        assert (!is EqualsSign|Unknown token);

        switch (token)
        case (is Variable) {
            partial.push(Var(token.name));
        }
        case (is UnsignedInteger) {
            partial.push(Literal(token.val));
        }
        case (is PlusSign) {
            value right = partial.pop();
            value left = partial.pop();

            "Operand missing"
            assert (exists left, exists right);

            partial.push(Sum(left, right));
        }


        return partial;
    });


    value expression = stack.pop();

    "Must always have a expression resulting from RHS"
    assert (exists expression);

    return expression;

}

{Token*} asPostfix({Token*} infix) {


    value [stack, buffer] = infix.fold([LinkedList<Token>(), LinkedList<Token>()])((partial, token) {

        value [operatorStack, buffer] = partial;

        "RHS of equation cannot contain ``token.string``"
        assert (!is Unknown|EqualsSign token);

        switch (token)
        case (is UnsignedInteger|Variable) {
            buffer.add(token);
            return [operatorStack, buffer];
        }
        case (is PlusSign) {

            if (operatorStack.empty) {
                operatorStack.add(token);
                return [operatorStack, buffer];
            }

            while (exists top = operatorStack.top) {

                if (hasHigherPrecedence(top, token)) {
                    operatorStack.pop();
                    buffer.add(top);
                }

                buffer.add(token);

                break;

            }

            return [operatorStack, buffer];

        }
    });

    return buffer.chain(stack.reversed);
}

Boolean hasHigherPrecedence(Token operatorA, Token operatorB) {
    return false;
}


