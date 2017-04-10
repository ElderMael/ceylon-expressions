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

    value context = HashMap<String,Expression>();

    print(file.path.absolutePath.uriString);

    value fileLines = lines(file);

    "File must contain expressions"
    assert (nonempty fileLines);

    value equations = fileLines
        .map((line) => line.split())
        .map((lexicalUnits) => lexicalUnits.map(Token.asToken));


    equations.each(({Token+} element) {
        value lhs = element.first;

        assert (is Variable lhs);

        value rhs = element.skip(2);

        value rhsExpression = buildExpressionFrom(rhs, context);

        context.put(lhs.name, rhsExpression);

    });

    context.keys.sort(byIncreasing(String.string)).each((String variableName) {

        value result = context.get(variableName);

        "Variable ``variableName``` not defined"
        assert (exists result);

        print("``variableName`` = ``result.eval().string``");

    });

    return successExitCode;
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


