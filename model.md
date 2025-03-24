---
title: Model 
subject: Documentation 
subtitle: A short description of the model.
short_title: Model
authors:
  - name: David Thierry 
    affiliations:
      - Energy Systems and Infrastructure Analysis.
  - name: Sarang Supekar
    affiliations:
      - Energy Systems and Infrastructure Analysis.
license: BSD-3 
abbreviations:
  MILP: Mixed-Integer Linear Programming
  NPV: Net Present Value
---


This section provides a summary of the model `stre3am`. A more comprehensive
description can be found under the `STREAM/docs/model_d/` directory and typing
`make` in a terminal emulator[^1]. 

[^1]: A `latex` distribution must be installed, e.g. [here](https://www.latex-project.org/get/)

## Model basic idea

Let us consider a single plant or asset, and let $x_{ij} \in
\mathbb{R}^{\mathtt{nv}}$ represent a vector of *measurable* quantities at a
particular period $i$, subperiod $j$, e.g.\ the fuel consumption, or the
variable O & M cost, etc.  Further, assume the *ordered* sets $\mathcal{P} =
\{1, 2, \dots, \mathtt{n\_periods}\}$ and $\mathcal{P}_1 =
\{1,2,\dots,\mathtt{n\_subperiods}\}$ representing the periods and subperiods.
Then, assuming every quantity of the plant is related linearly to one another,
the following system characterizes the asset,

```{math} 
:label: eq:char
A_{ij} x_{ij} = b_{ij}\; \forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
```

where $A_{ij}$ is an `nvar` by (`nv`=`nvar`+$d$) matrix ($d>0$ degrees of
freedom), and $b_{ij}$ is a `nvar` vector of coefficients.  The equation above
can be used to determine the *state* of the plant given an arbitrary value of
the $d$ degrees of freedom (e.g. the active capacity).

Therefore, a plant in `stre3am` can have varying *states* according to the
arbitrary values of the $d$ degrees of freedom over time. A change in the
technological makeup of the plant has the potential to change the relationship
between state and their degrees of freedom. This is reflected in Equation
[](#eq:char) through the adoption *characteristic* matrices/vectors $A_{ij}$ and
$b_{ij}$ for each technology adoption in the plant. Therefore, a plant with
several possible technological makeup (e.g.\ plant retrofits) has the following
system,

```{math}
:label: eq:char_k
A_{ijk} x_{ij} = b_{ijk}\; 
\exists k \in \mathcal{K}, \forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
```

where $\mathcal{K}$ represents the (generic) technology ordered set,
which in the current implementation of `stre3am` can refer to retrofits or new
plants. The key aspect of the problem behind `stre3am` is that for the plant *at
most* one technological makeup must be true (e.g. selected) at a given time.
This decision is different from the other measurable quantities insofar as its
*discrete* nature. Let $y_{ijk} \in \{0,1\}$ be 1 if technology $k$ is *active*
and 0 otherwise. This binary variable is used to present the decision of a
particular technology at a particular time in the following form,

$$ 
A_{ijk} \nu_{ijk} = b_{ijk} y_{ijk} \; 
\forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
$$

$$
\sum_{k\in\mathcal{K}} \nu_{ijk} = x_{ij}, \, \sum_{k\in\mathcal{K}}y_{ijk}
= 1\; 
\forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
$$

and, 

$$
x^\text{lb} y_{ijk} \leq \nu_{ijk} \leq x^\text{ub} y_{ijk} \;
\forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
$$

where $\nu_{ijk}$ is the *disaggregated* state variable for technology $k$, and
$x^{\text{lb}}$ and $x^{\text{ub}}$ are the lower- and upper-bound of the state
vector. These equations link the value of $y_{ijk}$ to the state vector and the
 respective matrix and vector $A_{ijk}$ and $b_{ijk}$. An alternative view of
 this system can be obtained by introducing a *Boolean* variable $Y_{ijk} \in
 \{\text{True, False} \}$ analogous to $y_{ijk}$, and the following equation,

$$
\underline{\vee}_{k\in \mathcal{K}} 
\begin{pmatrix} Y_{ijk} \\
A_{ijk} x_{ij} = b_{ijk} 
\end{pmatrix}\;
\forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
$$

where $\underline{\vee}$ represents the *exclusive OR* (XOR) operator. The
previous equation are known as *disjunctive* constraints, and this particular
instance assumes a single index $k$ has $Y_{ijk}$ equal `True`, and all else set
to False. Let us assume that $k=1$ corresponds to the *incumbent* technology,
i.e. the technology given to the plant *before* the first time-slice. Then, the
possible values the Boolean variables over the whole horizon can be restricted
through the following statements:

- A transition to a non-incumbent technology is `True` once for the whole horizon.

    ```{math}
    :label: eq:prop1
    Y_{ijk} \implies Y_{i, j+1, k} \;
    \forall i \in \mathcal{P},
    \forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
    \forall k \in \mathcal{K} \setminus \left\{1\right\},
    ```

and,

$$
Y_{i,|\mathcal{P}_1|,k} \implies Y_{i+1, 1, k} \; 
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\},
\forall k \in \mathcal{K} \setminus \left\{1\right\}.
$$

- A transition from incumbent is `True` once for the whole horizon.

$$
Y_{i, j+1, 1} \implies Y_{i,j, 1} \;
\forall i \in \mathcal{P},
\forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
$$

and,

```{math}
:label: eq:prop4
Y_{i+1, 1, 1} \implies 
Y_{i,|\mathcal{P}_1|,1} \; 
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\}.
```

These logic propositions collectively written here as $\Omega(Y) =
\text{True}$. These propositions can also be written in terms of binary
variables and algebraic equations, viz.,

$$
y_{ijk} - y_{i,j+1,k} \leq 0 \; 
\forall i \in \mathcal{P},
\forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
\forall k \in \mathcal{K} \setminus \left\{1\right\},
$$

$$
y_{i,|\mathcal{P}_1|,k} - y_{i+1,1,k} \leq 0 \; 
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\},
\forall k \in \mathcal{K} \setminus \left\{1\right\},
$$

$$
y_{i,j+1,1} - y_{ij,1} \leq 0 \;
\forall i \in \mathcal{P},
\forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
$$

$$
y_{i+1,1,1} - y_{i,|\mathcal{P}_1|,1} \leq 0 \;
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\}.
$$

Which collectively are written here as:

```{math}
:label: eq:alg_bin
H y_{ijk} \geq h \; \forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
\forall k \in \mathcal{K}.
```

The decisions expressed in the previous set of equations can either have binary
($\{0, 1\}$), or Boolean ($\{\text{True, False}\}$), as well as continuous.
Similar methodology can be applied to the following decisions within `stre3am`,

```{list-table} Key decisions
:header-rows: 1
:label: tab:key_dec
* - Decision
  - Description
* - Expansion
  - A single increase of the *installed capacity* of the plant over the whole
    horizon. The capital required must be financed with debt.
* - Plant retirement
  - Switch off the plant, active capacity is set to zero. All other quantities
  are also set to zero. Plant must pay accrued loans at the time of this
  decision.
* - Plant retrofit
  - Change the state of the *existing* plant by picking an alternative matrix and
  right-hand-side vector from Equation [](#eq:char_k). As a consequence the
  plant/asset changes its performance, e.g., fuel, electricity, etc. Capital
  cost is debt financed.
* - New plant
  - Contingent upon plant retirement. Once a *cleared* location is available, a
  new plant of alternative technology can be put in place with arbitraty
  capacity. Similarly to retrofit, the new plant will have a matrix/rhs from
  Equation [](#eq:char_k) which changes the performance accordingly.
```
(s:objective_function)=
## Objective function

The model uses the minimization of the _Net Present Value_ (NPV) as objective
function. Nevertheless, users can define custom objective functions in the same
way as any `JuMP` model. The NPV in `stre3am` has several components, most
noticeable the *discount* factor $\delta_{ij}$, which can be calculated from the
assumed interest rate and year. The objective function considers the following
items for every period and subperiod tuple
($(i,j)\in\mathcal{P}\times\mathcal{P}_1$),

1. Capital cost installments (CI)
2. Fixed operations and maintenance (fO&M)
3. Variable operations and maintenance (vO&M)
4. Fuel cost (FC)
5. Electricity cost (EC)
6. Feedstock cost (FdC)
7. CCS cost (CCSC)
8. Plant retirement (PR)
9. Last period loan factor (LLF).

```{math}
:label: eq:obf
\min \sum_{i\in\mathcal{P}} \sum_{j\in\mathcal{P}_1}  &
\delta_{ij} \text{CI}_{ij} + \delta_{ij} \text{fO\&M}_{ij} + \delta_{ij}\text{vO\&M}_{ij} 
  + \delta_{ij}\text{FC}_{ij} \\ + & \delta_{ij}\text{EC}_{ij} + \delta_{ij}\text{FdC}_{ij} + \delta_{ij}\text{CCSC}_{ij}  + 
\delta_{ij}\text{PR}_{ij} \\
+ & \text{LLF}.
```

The terms in the previous equation are related to the rest of variables from the
model linearly. 

## Constraints

As mentioned in the model basis section, the model can be expressed either with
disjunctions, logic statements, and Boolean (and continuous) variables[^gdp], or with
algebraic equations and binary variables, i.e. [MILP](https://en.wikipedia.org/wiki/Integer_programming).

[^gdp]: A.k.a Generalized Disjunctive Program (GDP) [Trespalacios and Grossmann, 2014](
https://doi.org/10.1002/cite.201400037)

Either case, the decisions mentioned in [](#tab:key_dec), have their own
set of Boolean/binary variables. 
Let {math}`Y_{ij}^e, Y_{ij}^r, Y_{ij}^o, Y_{ij}^n \in \{\text{True, False}\}`[^bool]
represent the Boolean variables for expansion, retrofit, online, and new plant.
Thus, the constraints of the model can be laid out as follows,

[^bool]: On the space of binary variables $y_{ij}^e, y_{ij}^r, y_{ij}^o,
  y_{ij}^n \in \{0, 1\}$

  {term}`Expansion`

```{math}
:label: eq:exp
\begin{pmatrix} Y^e_{ij} \\ 
x^0_{ij} = \mathtt{x0} + \Delta_{ij} 
\end{pmatrix}
\underline{\vee}
\begin{pmatrix} \neg Y^e_{ij} \\ 
x^0_{ij} = \mathtt{x0}
\end{pmatrix}
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
```

  {term}`Plant retrofit`

```{math}
\underline{\vee}_{k\in \mathcal{K}_r} \begin{pmatrix} Y^r_{ijk} \\ 
A^r_{ijk} x_{ij}^0 = b^r_{ijk} \end{pmatrix}\; \forall i \in\mathcal{P}, 
\forall j \in\mathcal{P}_1.
```


  {term}`Plant retirement`

```{math}
\begin{pmatrix} Y^o_{ij} \\ 
x^o_{ij} = x^0_{ij} 
\end{pmatrix}
\underline{\vee}
\begin{pmatrix} \neg Y^e_{ij} \\ 
x^o_{ij} = 0 
\end{pmatrix}
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
```

  {term}`New plant`[^newp]

  [^newp]: For $k\in\mathcal{K}_n=\{1,2,...\}$, we assume that for $k=1$ $x_{ij} = 0$

```{math}
\underline{\vee}_{k\in \mathcal{K}_n} \begin{pmatrix} Y^n_{ijk} \\ 
A^n_{ijk} x_{ij} = b^n_{ijk} \end{pmatrix}\
; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
```

{term}`Logic propositions`

```{math}
:label: eq:logic_prop
\Omega \left(Y_{ij}^e, Y_{ij}^r, Y_{ij}^o, Y_{ij}^n\right) = \text{True}
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
```

The previous equations describe the changes on the plant through technological,
capacity, and operational decisions. It is also possible to have continuous
variables constrained on temporal basis, for example demand at every period and
subperiod pair. This can be represented through the following equation,

```{math}
 B_{ij} \left(x^0_{ij}+x_{ij}\right) \leq p_{ij} \;
\forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
``` 
[^exist_v_new]

[^exist_v_new]: In the current model construction {math}`x^0_{ij}` and
  {math}`x_{ij}` are orthogonal of one another for some period and subperiod
  pair, in other words, either {math}`x^0` or {math}`x` is non-negative, an
  existing plant or a new plant operates, but not both. 

for some matrix and right-hand-side {math}`B_{ij}` and {math}`p_ij`.

Finally, it is noted that Equations [](#eq:exp) through [](#eq:logic_prop) can
be represented using binary variables and algebraic equations as follows,

```{math}
\nu^e_{ij,1} &= \mathtt{x0} y_{ij,1}^e + \Delta^e_{ij},  \\
\nu^e_{ij,2} &= \mathtt{x0} y_{ij,2}^e, \\
x_{ij}^0 &= \nu_{ij,1}^e + \nu_{ij,2}^e, \\
\Delta_{ij} &= \Delta_{ij}^e, \\
 \nu^e_{ij,1} & \leq x^\text{ub} y_{ij,1}^e, \\
 \nu^e_{ij,2} & \leq x^\text{ub} y_{ij,2}^e, \\
\Delta_{ij}^e & \leq \Delta^\text{ub} y_{ij,1}^e, \\
1 &= y_{ij,1}^e + y_{ij,2}^e
\; 
\forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
```
```{math}
A^r_{ijk} \nu_{ijk}^r &= b^r_{ijk} y_{ijk}^r, \\
x_{ij}^0 &= \sum_{k\in\mathcal{K}_n} \nu_{ijk}^r, \\
\nu_{ijk}^r &\leq x^\text{ub} y_{ijk}^r\; \forall k\in\mathcal{K}_r, \\
\sum_{k\in\mathcal{K}_r} y_{ijk}^r &= 1 
\; \forall i \in\mathcal{P}, 
\forall j \in\mathcal{P}_1,
```

```{math}
\nu^o_{ij,1} &= \nu^0_{ij,1} \\
x_{ij}^o &= \nu_{ij,1}^o + \nu_{ij,2}^o \\
x_{ij}^0 &= \nu_{ij,1}^0 + \nu_{ij,2}^0 \\
\nu^o_{ij,1} & \leq x^\text{ub} y_{ij}^o, \\
\nu^0_{ij,1} & \leq x^\text{ub} y_{ij}^o, \\
\nu^o_{ij,2} & \leq x^\text{ub} \left(1 - y_{ij}^o\right), \\
\nu^0_{ij,2} & \leq x^\text{ub} \left(1 - y_{ij}^o\right)
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
```

```{math}
A^n_{ijk} \nu_{ijk}^n &= b^n_{ijk} y_{ijk}^n, \\ 
x_{ijk} &= \sum_{k\in\mathcal{K}_n} \nu_{ijk}^n, \\
\nu_{ijk}^n & \leq x^\text{ub} y_{ijk}^n \; \forall k\in\mathcal{K}_n, \\
\sum_{k\in\mathcal{K}_n} y_{ijk}^n &= 1
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1,
```

```{math}
:label: eq:logic_prop_bin
H_{ij} \left[y_{ij}^e, y_{ij}^r, y_{ij}^o, y_{ij}^n\right]^T \leq h_{ij}
\; \forall i \in\mathcal{P}, \forall j \in\mathcal{P}_1.
```
So far these equations describe the model for a *single* plant/asset. Typically,
one might find that industries have several plants/assets, each with their
unique characteristics, i.e. `A_{ij}`, `b_{ij}`, costs, etc.
Let 
{math}`\mathcal{L}\in\left\{1, 2, 3, ..., \mathtt{n\_loc}\right\}` represent the
set of locations. The multi-plant location problem is a natural extension of the
single location problem shown thus far. 


## Model building actions

Given the input sets and data for a particular instance, building the model is
done through a series of function calls that first build an *unlinked* model for
each period, subperiod, and location. This is done through the following
function,

```{code} julia
m = createBlockMod(s.P, s.L, p, s)
```

Through this call the model `m` is generated. This call however, does not
create either inter-period or inter-location constraints.

:::{note} Inter-period/inter-location constraints 
:class: dropdown
Typically, the model has several periods, subperiods, and locations. Most
constraints of the model reference variables within the same period, subperiod
and location. Furthermore, let us consider a block of variables that share the
same period and location (but may have different subperiod). Then, the model
that results from considering *only* constraints within period and location is
*decoupled* insofar as each block could be solved independendly of the other
blocks. The model blocks have a collective feasible region different from the
full *linked* problem, and this solution is a lower-bound of the full problem at
best. Nevertheless, it possesses useful properties for potential algorithmic
strategies. 
:::

The linking with inter-period and inter-location is done as follows:

```{code} Julia
attachPeriodBlock(m, p, s)
attachLocationBlock(m, p, s)
```

This creates a linked model, which can be completed with the objective function
(NPV minimization) creation:

```{code} Julia
attachFullObjectiveBlock(m, p, s)
```

The resulting `m` is an instance of a `JuMP` object with objective and
constraints

## Concluding remarks

It is encouraged to refer to the `stre3am` manuscript where the complete model
is laid out. This page is a brief summary of some core aspects of the model.



:::{glossary}
Expansion
: Increase *installed capacity* of the existing plant once through the whole
horizon.

Plant retrofit
: Change of characteristic coefficient matrix and right-hand-side. Acts on the
existing plant.

Plant retirement
: Set existing plant off. All associated quantities are set to zero. Retirement
cost must be paid. Can be used *once* through the horizon. Results in an *empty*
location.

New plant
: If an empty location is available, creates a plant of arbitrary capacity, and
characteristic coefficient matrix/right-hand-side.

Logic propositions
: Provides the space of acceptable combinations of Boolean variables. 
:::





