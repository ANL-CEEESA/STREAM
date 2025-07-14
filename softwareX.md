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
julia --project=.
```

Which opens to:

```{code}
              _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.11.6 (2025-07-09)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> 
```

Then, pressing the {kbd}`]` opens the package manager,

```
(@v1.8) pkg> 
```

Then typing the following will install `stre3am`.

```{code} julia
activate .
```

This will activate the local project for `str3am`. Then, the dependencies need
to be resolved. For this (while in `pkg` mode), the following has to be typed:

```{code}
instantiate
```

To summarize, this would look like as follows,

```{code}
# In your terminal, navigate to the root STREAM package
cd /path/to/STREAM

# Starting Julia
julia

# In Julia REPL:
julia> ] # Pkg mode
pkg> activate . # Activate the environment
(stre3am) pkg> instantiate # Install dependencies
(stre3am) pkg> # Press Backspace to exit Pkg mode
julia> using stre3am # Load stre3am
```

A final (optional) step, we need to use conda to create a new environment using
the `environment.yml` file at the root `STREAM` folder. 

For this the following commands have to be typed. 

```{code} command
conda env create --name stre3am --file environment.yml
```
With this one can activate via `conda activate stre3am`, this is in case one
wants to generate the plots.

## Case study

To run the example case study, one must navigate to the `instances/softwareX`,
where the `run_sweep.jl` is the relevant `stre3am` script to consider.

The case study can be run with the following command:

```
julia --project=../.. run_sweep.jl
```

Which will run the *nominal* case study from the paper.

Finally to generate the plots, activate the `stre3am` conda environment through
`conda activate stre3am`, and 

```
python gen_plots.py
```

Which will generate the plots in folders within the directory.
