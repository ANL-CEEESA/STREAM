---
title: Prototype 
subject: Case-study
subtitle: Example use of the model
short_title: Prototype
authors:
  - name: David Thierry 
    affiliations:
      - Energy Systems and Infrastructure Analysis.
  - name: Sarang Supekar
    affiliations:
      - Energy Systems and Infrastructure Analysis.
license: BSD-3 

---

This section provides a description of a prototype case study. The following
script corresponds to the planning of multiple facilities each with an internal
2-node process, and a fictitious technology set. Please refer to the
`stre3am` manuscript for more details.

The script begins with the imports from `stre3am` as well as other important
packages.
```{code} julia
using stre3am
using JuMP
using HiGHS
```
Where [HiGHs](https://highs.dev) is a *open-source* MILP solver. 
Then the input data file `f0.xlsx` contains all the relevant information to
build the case study.
```{code}
# input file
f = "./f0.xlsx"
```
Please refer to the [input data](input_data.md) page for more information about
the contents of the spreadsheet file. 
Next, the parameters from the model are build from the input data file
`f`.
```{code} julia
# internal data structure
p = read_params(f);
@info "Data has been loaded.\n"
```
Where `p` contains all the data organized in `Julia` arrays. This variable is
used to initialize the model *sets*, e.g. *periods*{math}`=\mathcal{P}`,
*subperiods*{math}`=\mathcal{P}_1`, et.c, 
```{code} julia
# sets
s = sets(p)
@info "Sets have been created.\n"
```
Both `p` and `s` are used to create the *unlinked* model block. In this example
the model for the whole set of periods and locations will be built. Thus, the
function [](#createBlockMod) is invoked, and the sets {math}`\mathcal{P}` and
{math}`\mathcal{L}` (`s.P` and `s.L`, respectively) must be passed explicitly,
alongside `p` and `s`, *viz.*

```{code} julia
# model
@info "Creating model.\n"
m = createBlockMod(s.P, s.L, p, s)
```

:::{note} Model block 
:class: dropdown
The reason for the pedantic nature of having to reference `s` thrice, is that
one can create a *single* model block for a particular period and location, e.g.
calling [](#createBlockMod) with two scalars in the sets, 
```{code}
m_1_2 = createBlockMod(1, 2, p, s)
```
would create a model for the first period and the second location.
:::

The object `m` now contains the model for the case study. The next steps are
attaching the inter-period and inter-location constraints, 
% we need to have the ! notation from julia here.
```{code} julia
# linking constraints
attachPeriodBlock(m, p, s)
attachLocationBlock(m, p, s)
```
Model `m` contains all the base constraints and variables for the case study.
The final step of model building is to attach the objective function. As
discussed the [](#s:objective_function) section, NPV is minimized. 

```{code} julia
# objective function
attachFullObjectiveBlock(m, p, s)
```
:::{tip} Manipulating the model
:class: dropdown
At this point it is possible to change any aspect of the model in a similar
capacity as any `JuMP` model. For example,
```{code} julia
# Get the period ,subperiod and location objects
P=s.P
P2=s.P2
L=s.L
# new capacity variable
n_cp = m[:n_cp]
# existing capacity variable
o_cp = m[:o_cp]
# define a constraint
@constraint(m, my_constraint[i=P, j=P2],
            sum(o_cp[i, j, l, p.key_node] for l in L) + 
            sum(n_cp[i, j, l, p.key_node] for l in L) >= 2*p.demand[i, j]
           )
```
:::

The resulting model can be now solved with any MILP solver supported by `JuMP`,
As previously described, `HiGHS` is used in this case study. 

```{code} julia
set_optimizer(m, HiGHS.Optimizer)
```
And then calling the `optimize!` function.
``` {code} julia
# call solver
@info "Solve.\n"
optimize!(m)
```
Which generates the following output:
```{code}

[ Info: Solve.
Running HiGHS 1.7.2 (git hash: 5ce7a2753): Copyright (c) 2024 HiGHS under MIT licence terms
Coefficient ranges:
  Matrix [9e-05, 2e+04]
  Cost   [4e-02, 1e+00]
  Bound  [1e-03, 4e+03]
  RHS    [1e-03, 4e+03]
Assessing feasibility of MIP using primal feasibility and integrality tolerance of       1e-06

...

Solving MIP model with:
   16116 rows
   9374 cols (893 binary, 0 integer, 0 implied int., 8481 continuous)
   52846 nonzeros

        Nodes      |    B&B Tree     |            Objective Bounds              |  Dynamic Constraints |       Work      
     Proc. InQueue |  Leaves   Expl. | BestBound       BestSol              Gap |   Cuts   InLp Confl. | LpIters     Time

         0       0         0   0.00%   277.2336417     1777.928697       84.41%        0      0      0         0     0.2s
         0       0         0   0.00%   436.9122254     1777.928697       75.43%        0      0      3      7559     1.1s
         0       0         0   0.00%   557.6583504     1777.928697       68.63%     9748    999    711     30403     6.3s
         0       0         0   0.00%   594.9809109     1777.928697       66.54%    11430   1372    711     52150    12.1s
...
```

This process populates the `JuMP` variables with their respective results.
These are post-process into neat `csv` files which can be plotted with the
provides `Python` scripts.
```{code} julia
# generate result files
postprocess_d(m, p, s, f)
```

This finalizes the procedure for a typical run of a `stre3am` case study.


