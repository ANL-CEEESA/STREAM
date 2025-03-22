---
title: Reference
description: List of julia functions
---

(my-section)=
#### Header _Targets_

We can do a little test for example this and that.
```{code} python
import numpy as np

def main():
    print("this is main")

if __name__ == "__main__":
    main()

```

(createBlockMod)=
#### `createBlockMod`

```{code} julia
createBlockMod(p::Union{Int, UnitRange}, l::Union{Int, UnitRange}, p::params, s:sets)
```
Generates a model for the specified range of time-periods and locations.
Returns a `JuMP::Model`



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

Here we reference [](#my-section)

```{show-index}
```

