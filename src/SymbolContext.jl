export SymbolContext, ContextualSymbol, show

import Base.show, Base.show_unquoted
import Crayons: CrayonStack, Crayon



"""
    SymbolContext(syms, function [,display_expression])

A symbol context is a special function, evaluating symbols within the body of 
the function within the context of a single argument. Generally, these are 
constructed with the `@syms` macro, which will modify an expression, replacing
any unescaped symbols in the expression with calls to `sym(<obj>, :symbol)` 
This allows contexts to be described for arbitrary objects and for better 
extension of symbols as a domain-specific abstraction to arbitrary data. 

### Arguments 

* `syms` : An `Array` of `Symbol`s, itemizing which symbols are represented
    contextually.
* `function` : A unary function which is to be called with the contextual data, 
    or alternatively with keyworded arguments for each of the symbols.
* `display_expression` : An optional argument used to store a cleaned expression
    for printing the symbolic expression that was used to generate the contextual
    function.

### Examples

Creating a symbol context from a hand-crafted function, representing symbols
as calls to `sym`. Generally, creating a context in this way is only done
by developers. 

```
julia> SymbolContext([:x, :y], x -> sym(x, :x) + sym(x, :y))
```

More commonly a symbol context is created using the `@syms` macro

```
julia> @syms begin
           :x + :y
       end
```
"""
struct SymbolContext
    syms::AbstractArray
    f::Function
    display_expr
end

SymbolContext(syms, f) = SymbolContext(syms, f, nothing)

(x::SymbolContext)(; kwargs...) = x(kwargs)
function (x::SymbolContext)(arg)
    found, miss = match_syms(arg, setdiff(x.syms, [:.]))

    @assert(length(miss) == 0,
        "Context of type `$(type_pretty(typeof(arg)))` cannot find " *
        "representation for symbol(s) " *
        join(":" .* string.(miss[1:(end-1)]), ", ") * 
        (length(miss) > 1 ? " and " : "") * 
        ":" * string(miss[end]))

    x.f(arg)
end



function show(io::IO, x::SymbolContext) 
    stack = CrayonStack(incremental = true)
    print("SymbolContext[")
    for (i, sym)=enumerate(x.syms)
        print(i == 1 ? "" : ",")
        print(io, push!(stack, Crayon(foreground = :blue)))
        print(":")
        show_unquoted(io, sym)
        print(io, pop!(stack))
    end 
    print("] ")
    if !(x.display_expr isa Expr && x.display_expr.head == :block)
        println()
    end
    Base.show_unquoted(io, x.display_expr)
end



struct Highlighted{T}
    x::T
end

function show(io::IO, x::Highlighted{<:Number})
    stack = CrayonStack(incremental = true)
    print(io, push!(stack, Crayon(foreground = :blue)))
    print(":")
    show(io, x.x)
    print(io, pop!(stack))
end

function show(io::IO, x::Highlighted{<:Symbol})
    stack = CrayonStack(incremental = true)
    print(io, push!(stack, Crayon(foreground = :blue)))

    if x.x == :.; print(":.")
    else; show(io, x.x)
    end

    print(io, pop!(stack))
end

