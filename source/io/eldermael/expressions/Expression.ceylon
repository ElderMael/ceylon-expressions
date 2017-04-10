import ceylon.collection {
    MutableMap
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

