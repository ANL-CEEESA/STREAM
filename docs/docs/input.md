# Input data

`stre3am` uses an excel file as input, Refer to the `./data/prototype.xlsx` file
for a blank protoype of the input. 

There are a number of sheets in the prototype file. Their description is given
in the following table

| sheet       | description                                |
|-------------|--------------------------------------------|
| reference   | "pointers" to the data                     |
| `timeAttr`  | quantities functions of time (*not* associated with cost) |
| `costAttr`  | quantities *exclusively* related to the system cost|
| `invrAttr`  | quantities not functions of time (*not* associated with cost) |

## Reference sheet

The *reference* sheet contains the cell location of the main components of the
data-structures in `stre3am`. 
Data inputs typically are given in matrix, vector, or scalar form. Matrices and
vectors require 2 addresses; matrices use upper-left and bottom-right corners
coordinates, whereas vectors use the first and last element coordinates. 

For instance, at the `timeAttr` section, the "initial capacity" matrix requires
2 addresses, 

|`timeAttr`|location|factor|
|:---------|--------|------|
| initial  | `X`:`Y`|  1   |

The addresses are given in the cell next to the "initial" cell, and these
represent the upper-left (`X`, e.g. B3) and bottom-right locations (`Y`, e.g.
DW13), 
separated by a colon `:`.

The *factor* column is required for floating point quantities, e.g. costs, heat
rates, etc. 

> &#x2757;
> It is the responsability of the user to ensure that there is consistency
> among all the units used within the computations.

E.g., suppose power is given in <mark>GWh</mark>, then heat rates must have a
consistent unit, for instance, MMBTU/<mark>GWh</mark>. 

## Time-variant attributes: `timeAttr`

The `timeAttr` sheet contains data that is a function of time but are not
related to cost (e.g. in USD). For instance,

- Initial capacity by vintage
- Demand by year
- Average capacity factor by vintage
- Existing capacity heat rate by vintage
- New plant heat rate by year.

### Notes on ordering

Quantities of *existing* assets must be given by *descending order of vintage*.
E.g., the initial capacities must be given as shown in the following table. 

| technology | year[T] | year[T-1] | year[T-2] | year[T-3] | ... | year[0] |
|------------|---------|-----------|-----------|-----------|-----|---------|
| tech 1     |   .     |   .       |      .    |    .      |  .  |    .    |
| tech 2     |   .     |   .       |      .    |    .      |  .  |    .    |
| .          |   .     |   .       |      .    |    .      |  .  |    .    |
| tech I-1   |   .     |   .       |      .    |    .      |  .  |    .    |
| tech I     |   .     |   .       |      .    |    .      |  .  |    .    |

Quantities for *new* assets, are given by *increasing* order, e.g. 2022, 2023,
etc. 

> &#x2757;
> Throughout the framework, the rule is, quantities must be given in 
> *increasing* order of year, except *existing*, i.e. old plants, for which they
> are given in *reverse* order.

## Cost attributes: `costAttr`

This sheet contains all attributes related to cost, viz.

- Capital cost
- Fixed O&M cost
- Variable O&M cost
- Cost of electrical power
- Cost of fuel
- Decomissioning cost.

These values must be laid-out by both technology and year.


## Time-invariant attributes `invrAttr`

These attributes that do not change over time, and information about the
abstract retrofit and new asset forms. For example, the information in this
sheet has financial and technical details, e.g.,

- Horizon
- Loan term
- Interest rate annuity factor
- New plant heat rate by year.
- Carbon intensity
- Fuel based tech
- Carbon based tech
- Retrofitted plant kinds
- New plant kinds.

Perhaps the most important information in this sheet is parameters of the
*abstract* forms of retrofits and new plants.

### Abstract forms

These parameters act as modifiers of the base technology. For example, a base
coal-fired power plant can have a carbon capture retrofit, thus inheriting some
of the base properties, while simultaneously modifying others in a substantial
way. To achieve this, a multiplier must be defined. Then the model takes the
base value, e.g.  heat rate, and multiplies it by the specified modifier.
Another way in which a base technology can be changed is by letting it switch to
a different fuel, thus affecting aspects like emission output, fuel cost, and
heat rate. Therefore, there modifiers of the base technology are defined as the
tuple of multiplier and base fuel.

So far, the current version of the model considers the following modifier pairs,

- Capital cost
- O&M costs (Fixed and Variable)
- Heat rate
- Carbon dioxide
- Fuel consumption
- Use base heat rate
- Miscellaneous.

And, these are given in the excel table as follows,


| technology     | Description | Prop. mod multiplier | Prop. mod. base fuel |  ... | 
|----------------|-------------|----------------------|----------------------|------|
|`i=0`, kind`=0` |(description)| value (*>0*)     | fuel index (e.g. 1, 2,...)|.|
|`i=0`, kind`=1` |(description)| value (*>0*)     | fuel index (e.g. 1, 2,...)|.|
|       .        |     .       |         .            |         .            |.|



> &#x2757;
> Any missing value or `-9999` would be interpreted as **non-modifying**, in
> other words, no changes will be made to the base technology.

