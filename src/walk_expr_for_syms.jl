"""
Check if an expression is a call to a function 
"""
is_call_to(e, f) = false

is_call_to(e::Expr, f) =
    e.head == :call && e.args[1] == f

is_call_to(e::Expr, f, nargs) =
    is_call_to(e, f) && length(e.args) == (nargs + 1) 


"""
    walk_expr_for_syms(expression, symbol_modification_function)

Walk an AST for symbols and transform them with a given function.

Returns a tuple of a new expression and a boolean indicating whether symbols
were replaced in the expression.
"""
walk_expr_for_syms(e, f) = 
    return e, e, missing, false

walk_expr_for_syms(q::QuoteNode, f) = 
    walk_expr_for_syms(Meta.quot(q.value), f)

walk_expr_for_syms(expr::Expr, symbol_dict::Dict) = 
    walk_expr_for_syms(expr, (e, s) -> get(symbol_dict, s, e))

walk_expr_for_syms(expr::Expr, symbol_func::Function, symbols::Union{Array{Symbol,1}}) = 
    walk_expr_for_syms(expr, (e, s) -> s in symbols ? symbol_func(e, s) : expr)

function walk_expr_for_syms(e::Expr, symbol_func::Function)
    # handle nested symbolic contexts
    if is_call_to(e, :SymbolContext)
        # anonymous contexts
        e, e, missing, false
    elseif e isa Expr && e.head == :call && is_call_to(e.args[1], :SymbolContext)
        # context that is provided with contextual values
        e, e, missing, false
    elseif is_call_to(e, :^, 1)
        e.args[2], e.args[2], missing, false
    elseif is_call_to(e, :sym)
        e, e, missing, false

    # handle macros
    elseif e.head == :macrocall
        e, e, missing, false

    # handle symbol nodes
    elseif e.head == :. && e.args[2] isa QuoteNode
        e, e, missing, false
    elseif e.args[1] == :(:.)
        new_expr = Expr(e.head, symbol_func(e, e.args[1].value), e.args[2:end]...)
        print_expr = Expr(e.head, Highlighted(e.args[1].value), e.args[2:end]...)
        return new_expr, print_expr, [e.args[1].value], true
    elseif e.head == :quote
        symbol_func(e, e.args[1]), Highlighted(e.args[1]), [e.args[1]], true

    # otherwise continue traversal
    else
        walks = walk_expr_for_syms.(e.args, [symbol_func])
        new_expr = Expr(e.head, getindex.(walks, [1])...)
        print_expr = Expr(e.head, getindex.(walks, [2])...)
        syms = unique(vcat(skipmissing(getindex.(walks, [3]))...))
        any_subs = any(last.(walks))
        return new_expr, print_expr, syms, any_subs
    end
end
