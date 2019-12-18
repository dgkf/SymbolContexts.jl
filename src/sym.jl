export sym

"""
    sym(x, s)

Evaluate a symbol within the context of an object, `x`. By default uses 
`getindex`, which allows for use with `Dict`s, `NamedTuple`s, `Tuple`s, and 
`Array`s. `Pair`s are handled as a special case, calling `getfield` instead.
`Pair`s also include handling for use of `:1` and `:2` as shorthands for 
`:first` and `:second`.

### Examples

```jdoctext
julia> sym(Dict(:x => 1), :x)
1

julia> sym(3 => 4, :1 + :second)
7

julia> sym((x = 1, y = 2), :x + :y)
3
"""
sym(x, s) = getindex(x, s)

# Pair 
sym(x::Pair, s::Symbol) = getfield(x, s)
sym(x::Pair, s::Int) = getfield(x, [:first, :second][s])

# Dict
sym(x::Dict{String,}, s::Symbol) = getindex(x, string(s))



"""
"""
function match_syms(x, ss)
    s_in_x = syms_in_context(x, ss)
    ss[s_in_x], ss[.! s_in_x]
end

syms_in_context(x, ss) = 
    repeat([true], length(ss))

syms_in_context(x::Union{Dict,NamedTuple,Base.Iterators.Pairs}, ss) =
    in.(ss, [keys(x)])

syms_in_context(x::Pair, ss) = 
    in.(ss, [[:first, :second, :1, :2]])

syms_in_context(x::Array, ss) = 
    indexin.(ss, [x]) .!== nothing

syms_in_context(x::Tuple, ss) =
    1 .<= ss .<= length(x)

