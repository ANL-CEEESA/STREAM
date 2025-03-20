---
title: Reference
description: List of julia functions
---

:::{glossary}
`createBlockMod`
: Generates a model for the specified range of time-periods and locations.
Returns a `JuMP::Model`
```{code} julia
createBlockMod(p::Union{Int, UnitRange}, l::Union{Int, UnitRange}, p::params, s:sets)
```
`attachPeriodBlock`
: Links the model with the period to period constrains.
```{code} julia
attachPeriodBlock(m::JuMP::Model, p::params, s::sets)
```

`attachLocationBlock`
: Links the model with the location to location constraints. E.g. demand.
```{code} julia
attachLocationBlock(m::JuMP::Model, p::params, s::sets)
```

`attachFullObjectiveBlock`
: Creates the objective function for the model, e.g. Net Present Value (NPV).
```{code} julia
attachFullObjectiveBlock(m::JuMP::Model, p::params, s::sets)
```
:::



Here we reference {term}`createBlockMod`.


```{show-index}
```

