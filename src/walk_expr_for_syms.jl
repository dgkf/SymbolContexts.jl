"""
Check if an expression is a call to a function with only one argument
"""
is_unary_call_to(e, f) = 
    # Credit: @bramtayl, @nilimilan in DataFramesMeta.jl's onearg() 
    e.head == :call && length(e.args) == 2 && e.args[1] == f


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

walk_expr_for_syms(e::Expr, symbol_func::Function) =
    if is_unary_call_to(e, :^)
        e.args[2], e.args[2], missing, false
    elseif e.head == :macrocall
        e, e, missing, false
    elseif e.head == :. && e.args[2] isa QuoteNode
        e, e, missing, false
    elseif e.args[1] == :(:.)
        new_expr = Expr(e.head, symbol_func(e, e.args[1].value), e.args[2:end]...)
        print_expr = Expr(e.head, HighlightedSymbol(e.args[1].value), e.args[2:end]...)
        return new_expr, print_expr, [e.args[1].value], true
    elseif e.head == :quote
        symbol_func(e, e.args[1]), HighlightedSymbol(e.args[1]), [e.args[1]], true
    else
        walks = walk_expr_for_syms.(e.args, [symbol_func])
        new_expr = Expr(e.head, getindex.(walks, [1])...)
        print_expr = Expr(e.head, getindex.(walks, [2])...)
        syms = unique(vcat(skipmissing(getindex.(walks, [3]))...))
        any_substitutions = any(last.(walks))
        return new_expr, print_expr, syms, any_substitutions
    end

