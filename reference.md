---
title: Reference
description: List of Julia functions
---


(createBlockMod)=
#### `createBlockMod`

```{code} julia
createBlockMod(p::Union{Int, UnitRange}, l::Union{Int, UnitRange}, p::params, s:sets)
```
Generates a model for the specified range of time-periods and locations.
Returns a `JuMP::Model`

(attachPeriodBlock)=
#### `attachPeriodBlock`

```{code} julia
attachPeriodBlock(m::JuMP::Model, p::params, s::sets)
```
Links the model with the period to period constrains.

(attachLocationBlock)=
#### `attachLocationBlock`

```{code} julia
attachLocationBlock(m::JuMP::Model, p::params, s::sets)
```
Links the model with the location to location constraints. E.g. demand.


(attachFullObjectiveBlock)=
#### `attachFullObjectiveBlock`
```{code} julia
attachFullObjectiveBlock(m::JuMP::Model, p::params, s::sets)
```
Creates the objective function for the model, e.g. Net Present Value (NPV).





