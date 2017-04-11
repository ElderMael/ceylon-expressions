import ceylon.collection {
    LinkedList
}

Expression buildExpressionFrom({Token*} rhs) {

    value postfix = asPostfix(rhs);

    value stack = postfix.fold(LinkedList<Expression>())((partial, token) {

        "RHS expression cannot have token type ``token.string``"
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

    "Expression ``rhs`` is not balanced"
    assert (stack.empty);

    "Must always have a expression resulting from RHS"
    assert (exists expression);

    return expression;

}

abstract class Expression() of Sum | Literal | Var {

    shared variable Integer? cachedResult = null;

    shared Integer eval(Map<String, Expression> context) {

        if (exists result = cachedResult) {
            return result;
        }

        switch (expression = this)
        case (is Literal) {
            return this.cachedResult = expression.number;
        }
        case (is Sum) {
            return this.cachedResult = (expression.left.eval(context) +
                expression.right.eval(context));
        }
        case (is Var) {
            value val = context.get(expression.name);

            "Variable ``expression.name`` does not exists in context"
            assert (exists val);

            return this.cachedResult =val.eval(context);

        }
    }

}

class Literal(shared Integer number) extends Expression() {
    string => number.string;


    shared actual Boolean equals(Object that) {
        if (is Literal that) {
            return number == that.number;
        }

        return false;

    }

    shared actual Integer hash => number;

}

class Sum(shared Expression left, shared Expression right) extends Expression() {
    string => "``left.string`` + ``right.string``";

    shared actual Boolean equals(Object that) {
        if (is Sum that) {
            return left == that.left &&
            right == that.right;
        }

        return false;

    }

    shared actual Integer hash {
        variable value hash = 1;
        hash = 31 * hash + left.hash;
        hash = 31 * hash + right.hash;
        return hash;
    }

}

class Var(shared String name) extends Expression() {
    string => this.name;

    shared actual Boolean equals(Object that) {
        if (is Var that) {
            return name == that.name;
        }

        return false;

    }

    shared actual Integer hash => name.hash;

}

