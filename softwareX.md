---
title: SoftwareX case study 
subject: Case-study
short_title: SoftwareX 
authors:
  - name: David Thierry 
    affiliations:
      - Energy Systems and Infrastructure Analysis.
  - name: Sarang Supekar
    affiliations:
      - Energy Systems and Infrastructure Analysis.
license: BSD-3-Clause 
---

This page presents instructions for the SoftwareX reviewers. 

## Installation

Make sure the following programs have been installed.
- [Julia](https://julialang.org/downloads/)
- [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Julia is the main engine behind the `stre3am` code. Conda will be used to fetch
and run the python scripts associated with the plotting of results. And git is
used to fecth the `stre3am` code.

After installing the three dependencies, in a terminal one must type:

```{code} command
git clone https://github.com/ANL-CEEESA/STREAM.git
```

Which will download the code from Github. Then, **at** the `STREAM` directory. One
must invoke julia which will open the `REPL`, e.g.

```{code} command
julia
```

Which opens to:

```
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.8.5 (2023-01-08)
 _/ |\__'_|_|_|\__'_|  |  
|__/                   |

julia> 
```

Then, pressing the {kbd}`]` opens the package manager,

```
(@v1.8) pkg> 
```

Then typing the following will install `stre3am`.

```{code} julia
add .
```

This will install stream. 

Then we need to use conda to create a new environment using the `environment.yml`
file at the root `STREAM` folder. 

For this the following commands have to be typed. 

```{code} command
conda env create --name stre3am --file environment.yml
```
With this one can activate via `conda activate stre3am`, this is in case one
wants to generate the plots.

## Case study

To run the example case study, one must navigate to the `instances/softwareX`,
where the `gen_data_toy.jl` and `prototype.jl` are the two main `stre3am`
scripts to consider.

First, run the `gen_data_toy.jl`

```
julia --project=../.. gen_data_toy.jl 
```

Which will generate the `f0.xlsx` that contains the input data. Then the case
study can be run through

```
julia --project=../.. prototype.jl
```

Which will run the case study from the paper.

Finally to generate the plots, activate the `stre3am` conda environment through
`conda activate stre3am`, and 

```
python gen_plots.py
```

Which will generate the plots in folders within the directory.
