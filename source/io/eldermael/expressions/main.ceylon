import ceylon.collection {
    MutableMap,
    HashMap,
    LinkedList,
    Stack
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
            Integer evaluationExitCode = evaluateFile(file);
            exitProcessWith(evaluationExitCode);
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

suppressWarnings ("expressionTypeNothing")
void exitProcessWith(Integer exitCode, String? message = null) {

    if (exists message) {
        print(message);
    }

    process.exit(exitCode);

}


Integer evaluateFile(File file) {

    value equations = parse(file);

    value context = HashMap<String,Expression>();

    equations.map(({Token+} element) {
        value lhs = element.first;

        assert (is Variable lhs);

        value rhs = element.skip(2);

        value rhsExpression = buildExpressionFrom(rhs, context);

        return [lhs, rhsExpression];

    }).fold(context)((partial, equation) {

        value [lhs, rhs] = equation;
        partial.put(lhs.name, rhs);

        return partial;
    });

    context.keys.sort(byIncreasing(String.string)).each((String variableName) {

        value result = context.get(variableName);

        "Variable ``variableName``` not defined"
        assert (exists result);

        print("``variableName`` = ``result.eval().string``");

    });

    return successExitCode;
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

Expression buildExpressionFrom({Token*} rhs, MutableMap<String,Expression> context) {

    value postfix = asPostfix(rhs);

    value stack = postfix.fold<Stack<Expression>>(LinkedList<Expression>())((partial, token) {

        "RHS cannot have token type ``token.string``"
        assert (!is EqualsSign|Unknown token);

        switch (token)
        case (is Variable) {
            partial.push(Var(token.name, context));
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


    value [stack, buffer] = infix.fold<[LinkedList<Token>, LinkedList<Token>]>([LinkedList<Token>(), LinkedList<Token>()])((partial, token) {

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


