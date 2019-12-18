export SymbolContext, ContextualSymbol, show

import Base.show, Base.show_unquoted
import Crayons: CrayonStack, Crayon


struct SymbolContext
    body
    syms::AbstractArray
    f::Function
end



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
    print("SymbolContext [")
    for (i, sym)=enumerate(x.syms)
        print(i == 1 ? "" : ", ")
        print(io, push!(stack, Crayon(foreground = :blue)))
        print(":")
        show_unquoted(io, sym)
        print(io, pop!(stack))
    end 
    print("]")
    println()
    Base.show_unquoted(io, x.body)
end



struct HighlightedSymbol{T<:Any} 
    e::T
end

function show(io::IO, x::HighlightedSymbol{<:Number})
    stack = CrayonStack(incremental = true)
    print(io, push!(stack, Crayon(foreground = :blue)))
    print(":")
    show(io, x.e)
    print(io, pop!(stack))
end

function show(io::IO, x::HighlightedSymbol)
    stack = CrayonStack(incremental = true)
    print(io, push!(stack, Crayon(foreground = :blue)))

    if x.e == :.; print(":.")
    else; show(io, x.e)
    end

    print(io, pop!(stack))
end

