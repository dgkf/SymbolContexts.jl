export SymbolContext, ContextualSymbol, show

import Base.show, Base.show_unquoted
import Crayons: CrayonStack, Crayon


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

# julia> @syms begin
#            :x + :y + :z
#            @syms begin
#                ^(:x) + :z
#            end
#        end
# SymbolContext [:x, :y, :z] # col1
# begin
#     :x + :y + :z           # col1
#     SymbolContext [:z]     # col2
#     begin
#         :x + :z            # col1 + col2
#     end
# end


function show(io::IO, x::SymbolContext) 
    stack = CrayonStack(incremental = true)
    print("SymbolContext([")
    for (i, sym)=enumerate(x.syms)
        print(i == 1 ? "" : ", ")
        print(io, push!(stack, Crayon(foreground = :blue)))
        print(":")
        show_unquoted(io, sym)
        print(io, pop!(stack))
    end 
    print("], ")
    if x.display_expr isa Expr && x.display_expr.head == :block; println(); end
    Base.show_unquoted(io, x.display_expr)
    print(")")
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

