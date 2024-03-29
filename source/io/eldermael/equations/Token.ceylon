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

"A tuple containing a predicate that signals if the string can be converted to
 a Token and containing a factory function for such token."
alias TokenStrategy => [Boolean(String), Token(String)];

"Tokens represent atomic parsing elements in [[Equation]]s and [[Expression]]s.

 These represent the plus sign, equals sign, variables, unsigned integers. There
 is also a special token [[Unknown]] that represents a token that could not fit a
 category."
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

"An interface that represents operations applied to operands.

 It contains the notion of precedence to represent the order/convention
 used to evaluate a [[Expression]].

 See Order of operations: https://en.wikipedia.org/wiki/Order_of_operations#Programming_languages

 "
shared interface Operator {

    "The precedence of this operator represented as a numeric value."
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

    shared static Boolean canBeBuiltFrom(String lexicalUnit) {
        return lexicalUnit.every(Character.letter) && !lexicalUnit.empty;
    }

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

    assert (!lexicalUnit.empty);

    string => "Unknown(``lexicalUnit``)";

    shared actual Boolean equals(Object that) {
        if (is Unknown that) {
            return lexicalUnit == that.lexicalUnit;
        }

        return false;

    }

    shared actual Integer hash => lexicalUnit.hash;

}

"Simplified implementation of Shunting-yard algorithm by Dijkstra to create
 postfix notation ordered collection of [[Token]]s.


 See: https://en.wikipedia.org/wiki/Shunting-yard_algorithm
 "
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

