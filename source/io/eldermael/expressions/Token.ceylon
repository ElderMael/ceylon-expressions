import ceylon.collection {
    LinkedList
}

shared {{Token+}+} parse(String[] fileLines) {

    "File must contain expressions"
    assert (nonempty fileLines);

    value equations = fileLines
        .map((line) => line.split())
        .map((lexicalUnits) => lexicalUnits.map(Token.asToken));

    return equations;
}

alias TokenStrategy => [Boolean(String), Token(String)];

shared abstract class Token of PlusSign | EqualsSign | Variable | UnsignedInteger | Unknown {

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

    shared new () {
    }

}

shared interface Operator {

    shared formal Integer precedence;

    shared Boolean hasHigherPrecedence(Operator operatorB) {
        return this.precedence>operatorB.precedence;
    }

}


shared class PlusSign extends Token satisfies Operator {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) => lexicalUnit == "+";

    shared new (String lexicalUnit) extends Token() {
        assert (lexicalUnit == "+");
    }

    shared actual Integer precedence => 4;

    string => "Plus(+)";

    shared actual Boolean equals(Object that) {
        if (is PlusSign that) {
            return true;
        }

        return false;

    }

    shared actual Integer hash => "+".hash;


}

shared class EqualsSign extends Token satisfies Operator {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) => lexicalUnit == "=";

    shared new (String lexicalUnit) extends Token() {}

    shared actual Integer precedence => 14; // From Wikipedia as in C

    string => "Equals(=)";

    shared actual Boolean equals(Object that) {
        if (is EqualsSign that) {
            return true;
        }

        return false;

    }

    shared actual Integer hash => "=".hash;


}

shared class UnsignedInteger extends Token {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) =>
            Integer.parse(lexicalUnit) is Integer;

    shared Integer val;

    shared new (String lexicalUnit) extends Token() {

        assert (is Integer val = Integer.parse(lexicalUnit));

        this.val = val;

    }

    string => "UnsignedInteger(``val.string``)";

    shared actual Boolean equals(Object that) {
        if (is UnsignedInteger that) {
            return val == that.val;
        }

        return false;

    }

    shared actual Integer hash => val;


}

shared class Variable extends Token {

    shared static Boolean canBeBuiltFrom(String lexicalUnit) =>
            lexicalUnit.every(Character.letter);

    shared String name;

    shared new (String name)
            extends Token() {
        this.name = name;
    }


    string => "Variable(``name``)";

    shared actual Boolean equals(Object that) {
        if (is Variable that) {
            return name == that.name;
        }

        return false;
    }

    shared actual Integer hash => name.hash;

}

shared class Unknown(String lexicalUnit) extends Token() {

    string => "Unknown(``lexicalUnit``)";

    shared actual Boolean equals(Object that) {
        if (is Unknown that) {
            return lexicalUnit == that.lexicalUnit;
        }

        return false;

    }

    shared actual Integer hash => lexicalUnit.hash;

}

shared {Token*} asPostfix({Token*} infix) {


    value initialStackAndBuffer = [LinkedList<Operator&Token>(), LinkedList<Token>()];

    value [stack, buffer] = infix
        .fold(initialStackAndBuffer)((stackAndBuffer, token) {

        value [operatorStack, buffer] = stackAndBuffer;

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

                if (top.hasHigherPrecedence(token)) {
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

