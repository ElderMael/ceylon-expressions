import ceylon.collection {
    LinkedList
}

"Factory function to create [[Expression]]s from a stream of [[Token]]s.

 First it takes the tokens in infix notation and converts them to postfix notation so we can
 evaluate the Expression in the required precedence of operators."
shared Expression buildExpressionFrom({Token*} rhs) {

    value postfix = asPostfix(rhs);

    value stack = postfix.fold(LinkedList<Expression>())((partial, token) {

        "RHS expression cannot have token type ``token.string``"
        assert (!is EqualsSign|Unknown token);

        switch (token)
        case (is Variable) {
            partial.push(Var(token.name));
        }
        case (is UnsignedInteger) {
            partial.push(Number(token.val));
        }
        case (is PlusSign) {
            value right = partial.pop();
            value left = partial.pop();

            "Operand missing in RHS ``rhs.string``"
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

"""This class represents a finite combination of numbers, operators and variables
   well-formed and that can be evaluated depending on a context that contains references
   to other expressions.
   """
shared abstract class Expression() of Sum | Number | Var {

    shared variable Integer? cachedResult = null;

    """This method evaluates the [[Expression]] using the given context by determining
       its type. If the result is resolvable, it is cached for future computations.
       """
    shared Integer eval(EquationContext context) {

        if (exists result = cachedResult) {
            return result;
        }

        switch (expression = this)
        case (is Number) {
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

"An expression that evaluates to its given integer numeral."
shared class Number(shared Integer number) extends Expression() {

    assert (number>=0);

    string => number.string;

    shared actual Boolean equals(Object that) {
        if (is Number that) {
            return number == that.number;
        }

        return false;

    }

    shared actual Integer hash => number;

}

"An expression that represents the sum of two expressions."
shared class Sum(shared Expression left, shared Expression right) extends Expression() {

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

"A context-dependant expression that evaluates to another expression within the context."
shared class Var(shared String name) extends Expression() {

    assert (!name.empty);

    string => this.name;

    shared actual Boolean equals(Object that) {
        if (is Var that) {
            return name == that.name;
        }

        return false;

    }

    shared actual Integer hash => name.hash;

}

