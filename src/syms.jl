export @syms



function syms(expr, x::Symbol=gensym())
    expr
end

function syms(expr::QuoteNode, x::Symbol=gensym())
    syms(Meta.quot(expr.value), x)
end

function syms(expr::Expr, x::Symbol=gensym())
    # expand internal macro so that symbol accessor function doesn't get 
    # modified (e.g. by `@.`)
    expr = eval(:(@macroexpand $expr))

    # create new function, with data dependent accessor function
    # e.g. 
    #     :x .* 3
    #   becomes
    #     d -> sym(d, :x) .* 3
    new_expr, print_expr, syms, any_substitutions = walk_expr_for_syms(expr, 
         (e, s) -> s == :. ? :($x) : :(sym($x, $(Meta.quot(s)))))

    # wrap new expression in a quote call so it can be displayed for printing
    print_expr = Expr(:quote, print_expr)
    if syms !== missing && length(syms) > 0; syms = syms[sortperm(string.(syms))]
    else; syms = []
    end

    # build call to syms_arg_handler for keyword arg handling
    :(SymbolContext($syms, $x -> $new_expr, $print_expr))
end



"Split macro arguments into positional and keyword arguments"
function split_macro_args(args)
    args = [a isa Expr && a.head == :parameters ? a.args : [a] for a in args]
    args = reduce(vcat, args)
    has_kw = [a isa Expr && a.head in (:kw, :(=)) for a in args]
    args[(!).(has_kw)], args[has_kw]
end



"""
    @syms(expr)
    @syms(x, expr)
    @syms(kwargs..., expr)

Produce a function expecting a context for the symbols in the expression, 
evaluating symbols with calls to `sym`, which defaults to using `getindex`, but 
can be easily extended to provide other contexts for symbolic expressions.



### Arguments 

* `expr` : If a single argument is provided, it is interpretted as an expression
    to parse for symbols.
* `x` : When an object is passed as the first argument, the function returned
    when reinterpretting symbols in a symbolic context is immediately called
    with the provided object.
* `kwargs` : Named arguments can be provided in place of an object and will
    be substituted for their corresponding symbols in the expression.



### Details

The expression is walked while replacing any symbols with calls which will
dispatch to `sym(x, <symbol>)`, allowing other packages to extend this behavior
and define their own contextual behaviors.

In addition to replacing named symbols, `:.` will be replaced with the entire 
object `x`, or a named `Tuple` of keyworded arguments when `kwargs` is provided.
Symbols used as part of a expression beginning with `:.` or `^` will be ignored.

For example, expressions `:.[:x]` and `^(:x)` will not substitute the value 
of `:x`.



### Examples

Calling `@syms` with an expression produces a function expecting a context 
object

```jdoctest
julia> f = @syms(:x + :y)
#1 (generic function with 2 methods)

julia> f(Dict(:x => 1, :y => 2))
3
```

By default, symbols will be replaced with calls to `sym()` which will dispatch
to using `getindex`, allowing `@syms` to be used with `Dict`s, `Tuple`s,
`NamedTuple`s and `Array`s. `Pair`s are handled by dispatching to `getfield` with
special handling for values `:1` and `:2` as synonyms for `:first` and `:second`.

```jdoctest
julia> f = @syms(:x + :y)
#1 (generic function with 2 methods)

julia> f(x = 1, y = 2)
3

julia> f((x = 1, y = 2))
3

julia> f = @syms(:1 + :2)
#1 (generic function with 2 methods)

julia> f([2, 3])
5

julia> f(2 => 3)
5
```

If more than one argument is provided, `@syms` will interpet the last argument
as the expression to interpret and the first argument as the symbol context. 

```jdoctest
julia> @syms((x = 1, y = 2), :x + :y)
3

julia> @syms Dict(:x => 1, :y => 2) begin
           :x + :y
       end
3
```

Mulitple keyword argument can also be provided instead of a single object.

```jdoctest
julia> @syms(x = 1, y = 2, :x + :y)
3

julia> @syms x=1 y=2 begin
           :x + :y
       end
3
```
"""
macro syms(args...)
    if length(args) > 1
        args, kwargs = split_macro_args(args)
        kwargs = map(kw -> Expr(:kw, kw.args[1], kw.args[2]), kwargs)
        esc(:($(syms(args[end], gensym()))($(args[1:(end-1)]...), $(kwargs...))))
    else
        esc(:($(syms(args[1], gensym()))))
    end
end
