
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