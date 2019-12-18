
type_pretty(x::UnionAll) = type_pretty(x.body)
type_pretty(x::DataType) = x.name

