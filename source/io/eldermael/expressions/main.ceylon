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

Boolean precedenceIsLessOrEqual(Token o1, Token o2) {
    return true;
}


abstract class Expression() of Sum | Literal | Var {

    shared variable Integer? cachedResult = null;

    shared Integer eval() {

        if (exists result = cachedResult) {
            return result;
        }

        switch (expression = this)
        case (is Literal) {
            return this.cachedResult = expression.number;
        }
        case (is Sum) {
            return this.cachedResult = (expression.left.eval() + expression.right.eval());
        }
        case (is Var) {
            value val = expression.context.get(expression.name);

            "Variable ``expression.name`` does not exists in context"
            assert (exists val);

            return this.cachedResult = val.eval();

        }
    }

}

class Literal(shared Integer number) extends Expression() {
    string => number.string;
}

class Sum(shared Expression left, shared Expression right) extends Expression() {
    string => "``left.string`` + ``right.string``";
}

class Var(shared String name, shared MutableMap<String,Expression> context) extends Expression() {
    string => this.name;
}


alias TokenStrategy => [Boolean(String), Token(String)];

abstract class Token of PlusSign | EqualsSign | Variable | UnsignedInteger | Unknown {

    static {TokenStrategy+} tokenStrategies = {
        [PlusSign.canBeBuiltFrom, PlusSign],
        [EqualsSign.canBeBuiltFrom, EqualsSign],
        [UnsignedInteger.canBeBuiltFrom, UnsignedInteger],
        [Variable.canBeBuiltFrom, Variable]
    };

    shared static Token asToken(String lexicalUnit) {

        value strategy = tokenStrategies.find((TokenStrategy element) {
            value [predicate, _] = element;
            return predicate(lexicalUnit);
        });

        if (exists strategy) {
            value [_, buildTokenFrom] = strategy;

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

    shared static Boolean canBeBuiltFrom(String lexicalUnit) => lexicalUnit == "+";

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

        assert (is Integer val = Integer.parse(lexicalUnit));

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