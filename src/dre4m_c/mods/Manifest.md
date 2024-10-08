# Manifest `mods`

- `m0.jl`
First version fo the model where the data is loaded in a rather clunky way, some
of the equations are more "densely" stated, and there is no difference between
kind for `x` and kind for `z`
- `m1.jl`
Second verion of the model, where there is kind for `x` and kind for `z`.
Moreover, the data is loaded in a block, there is sparsification of some of the
constraints. And, we use SCIP as the main solver.
- `m2.jl`
Follow up of `m1.jl` where we use Clp with relaxed dual tolerance to solve the
model.
- `m3.jl`
Third version of the model where we introduce the effective capacity indicator,
`effCapInd[time, kind, kind_, age]` $\in \[0, 1\]$
- `m3-10-a.jl`
Base file for the March presentation
- `m4.jl`
New analysis and features.
- `m4-2.jl`
Implemented the additional retrofits to PC.
- `m5_pre.jl`
Removed age as dimension, new schemes.
- `m4-3.jl`
Change from MWh to MW, add capacity factors. 
