
# Model

This section provides a summary of the model `stre3am`. A more comprehensive
description can be found under the `STREAM/docs/model_d/` directory and typing
`make` in a terminal emulator[^1]. 

[^1]: A `latex` distribution must be installed, e.g. [here](https://www.latex-project.org/get/)

Let us consider a single plant or asset, and let $x_{ij} \in
\mathbb{R}^{\mathtt{nv}}$
represent a vector of *measurable* quantities at a particular period $i$,
subperiod $j$, e.g.\ the fuel consumption, or the variable O & M cost, etc.
Further, assume the *ordered* sets $\mathcal{P} \in \{1, 2, \dots\}$ and 
$\mathcal{P}_1 \in \{1,2,\dots\}$ representing the periods and subperiods. Then,
assuming every quantity of the plant is related linearly to one another, the
following system characterizes the asset,

$$ 
A_{ij} x_{ij} = b_{ij}\; \forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
$$

where $A_{ij}$ is an `nvar` by (`nv`=`nvar`+$d$) matrix ($d>0$ degrees of
freedom), and $b_{ij}$ is a `nvar` vector of coefficients.  The equation above
can be used to determine the *state* of the plant given an arbitrary value of
the $d$ degrees of freedom (e.g. the active capacity).

Therefore, a plant in `stre3am` can have varying *states* according to the
arbitrary values of the $d$ degrees of freedom over time. A change in the
technological makeup of the plant has the potential to change the relationship
between state and their degrees of freedom. This is reflected in Eq. 1 through
the adoption *characteristic* matrices/vectors $A_{ij}$ and $b_{ij}$ for each
technology adoption in the plant. Therefore, a plant with several possible
technological makeup (e.g.\ plant retrofits) has the following system,

$$ 
A_{ijk} x_{ij} = b_{ijk}\; 
\exists k \in \mathcal{K}, \forall i \in \mathcal{P}, \forall j \in \mathcal{P}_1,
$$

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
instance assumes a single index $k$ has $Y_{ijk}$ equal True, and all else set
to False. Let us assume that $k=1$ corresponds to the *incumbent* technology,
i.e. the technology given to the plant *before* the first time-slice. Then, the
possible values the Boolean variables over the whole horizon can be restricted
through the following statements:

- A transition to a non-incumbent technology is True once for the whole horizon.

$$
Y_{ijk} \implies Y_{i, j+1, k}, \;
\forall i \in \mathcal{P},
\forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
\forall k \in \mathcal{K} \setminus \left\{1\right\},
$$

and,

$$
Y_{i,|\mathcal{P}_1|,k} \implies Y_{i+1, 1, k}, \; 
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\},
\forall k \in \mathcal{K} \setminus \left\{1\right\}.
$$

- A transition from incumbent is True once for the whole horizon.

$$
Y_{i, j+1, 1} \implies Y_{i,j, 1} , \;
\forall i \in \mathcal{P},
\forall j \in \mathcal{P}_1 \setminus \left\{|\mathcal{P}_1|\right\},
$$

and,

$$
Y_{i+1, 1, 1} \implies 
Y_{i,|\mathcal{P}_1|,1} \; 
\forall i \in \mathcal{P} \setminus \left\{|\mathcal{P}|\right\}.
$$

The disjunctive constraints, alongside the logic statements define a feasible
region over which the objective function can be minimized in similar to
conventional Mixed-Integer Linear Programs (MILPs). `stre3am` considers
additional decisions for the plant.

## Objective function

The objective function has three main components, viz.,

| Term                                                    | Description            |
|---------------------------------------------------------|------------------------|
| $\mathtt{NPV} \left(\mathbf{x}, \mathbf{p}\right)$      | Net present value      |
| $\mathtt{termCost} \left(\mathbf{x}, \mathbf{p}\right)$ | Terminal cost          |
| $\mathtt{softSl}\left(\mathbf{x}, \mathbf{p}\right)$    | Soft service-life cost. |

Net present value, is composed of the overnight capital, O&M, fuel, and
retirement costs, adjusted over time. Terminal cost compensates for the myopic
results, as a consequence the fixed horizon model. Finally, soft service-life is
methodology in which assets penalized for taking part in the system past their
typical service-life.

Next is a short description of the core component of the model, but it is noted
that this section will not reference to all of the equations and variables found
in the model. Refer to the manuscript for more details.

## Core: asset balance constraints

The main component of `stre3am` is the set of variables and constraints that
represent the changes to the technology asset makeup over time. 
Any case study for `stre3am` requires a set of *initial* assets. Then, for the
specified time horizon, the model within `stre3am` would find the appropriate set
of retirements, and retrofitting decisions for the existing assets. Moreover,
it can also decide to deploy new capacity from a technology portfolio. 

Having establishing the most relevant decisions of the model, the balance terms
are contingent upon the following sets, representing time, technology, and
initial age, viz.,

|Sets|Description|
|----|-----------|
|$T$|Time set ($\left\lbrace 0, 1, \dots, \mathtt{horizon}\right\rbrace$)|
|$I$|Technology set ($\left\lbrace \text{tech 0}, \text{tech 1}, \dots\right\rbrace$)|
|$N_j$|Initial age of existing asset set ($N_j \subseteq \mathbb{Z}_{\geq 0}$)|
|$K_i$|Sub-technology for existing assets|
|$\tilde{K}_i$|Sub-technology for new assets.|

The following variables ($\in\mathbb{R}_{\geq 0}$) are thus, recognized,

|variable     |description|
lllllx|-------------|-----------|
|$w^t_{i,j}$   |existing assets, $t \in T, i \in I, j \in N_i$|
|$y^t_{i,k,j}$ |retrofitted assets transition, $t \in T, i \in I, k \in K_i, j \in N_i$|
|$u^{t}_{i,j}$|retired assets $t \in T, i \in I, j \in N_i$|
|$z^t_{i,k,j}$|retrofitted assets, $t \in T, i \in I, k \in K_i, j \in N_i$|
|$\overline{u}^t_{i,k,j}$|retired retrofitted assets, $t \in T, i \in I, k \in K_i, j \in N_i$|
|$x^{t}_{i,k,j}$|new assets, $t,j \in T, i \in I, k \in \tilde{K}_i$|
|$v^t_{i,k,j}$|retired new assets, $t,j \in T, i \in I, k \in \tilde{K}_i$|
|$\tilde{x}^t_{i,k}$|new allocated, $t,j \in T, i \in I, k \in \tilde{K}_i$.|

### Existing

From a point in time to the next, existing assets can either be retired, undergo
a number of retrofits, and remain the same. This corresponds to the decision
tree, from the following figure.

<p class="aligncenter"> <img src="../img/wuy.svg" width="40%" height="40%"
title="balance for existing assets"> </p>

<style>
.aligncenter {
    text-align: center;
}
</style>

This can be interpreted as an algebraic expression as follows, 

$$
  w^{t+1}_{i,j} = w^{t}_{i,j} - u^{t}_{i,j} - \sum_{k \in K_i} y^{t}_{i, k,j}, 
  \; \forall t \in T, i \in I, j \in N_i.
$$

### Existing-retrofitted

If an asset is subject to retrofitting, i.e. at time $t$, for asset of kind $i$,
and base age $j$, $y^t_{i,k,j} > 0$ for some $k\in K_i$, said asset
enters a separate balance for retrofitted-assets. From that point, the
retrofitted-asset can either be retired or remain unchanged at the next point.
This is shown in the following picture.

<img src="../img/zyu.svg" width="40%" height="40%" title="balance for new 
assets">

Which results in the following algebraic expression,

$$
    z^{t+1}_{i,k,j} = z^{t}_{i,k,j} - \overline{u}^t_{i,k,j} + y^t_{i,k,j},\;
    \forall 
  t \in T, i \in I, k \in K_i, j \in N_i.
$$

### New-asset 

New assets are allocated strategically, i.e. at time $t$, for kind $i$, there is
$\tilde{x}^t_{i,k}>0$ for some $k \in \tilde{K}_i$. Then, these enter their own
tally following the next equation,

$$
    x^t_{i,k,t} = \tilde{x}^t_{i,k}, \; 
    \forall t\in T, i\in I, k\in \tilde{K}_i.
$$

Moreover, the new assets can either be retired, or continue to the next point,
this is laid out in the following figure and equation.

<img src="../img/xv.svg" width="40%" height="40%" title="balance for retrofits">


$$
    x^{t+1}_{i,k,j} = x^{t}_{i,k,j} - v^t_{i,k,j}
    ,\; \forall
    t,j \in T, i \in I, k \in \tilde{K}_i.
$$


### Supporting constraints

Following the supposition of an initial amount of existing assets of different
kinds, the variables are linked by the following equation,

$$
    w^0_{i,j} = \mathtt{initCap}_{i,j}, \; \forall i\in I, j\in N_i.
$$

Also, it is assumed that no retrofitted-assets exists at the initial time.

$$
    z^0_{i,k,j} = 0, \; \forall i\in I, k \in K_i, j\in N_i.
$$

## Concluding remarks

It is encouraged to refer to the `stre3am` manuscript where the complete model is
laid out. This page is a brief summary of some core aspects of the model.

