
# STRE{sup}`3`AM

## Introduction

STRE<sup>3</sup>AM or `stre3am` is a framework for analyzing the technological
makeup of a sector, e.g. manufacturing. This considers a set of technologies
alongside its cost and performance descriptors, and a set of plants or assets
each with its unique descriptors. The decision to adopt a technology in a
particular plant is currently framed two contexts, (i) a plant retrofit, and
(ii) a "new plant"[^1]. These decisions are possible over a number of periods in
such a way that an objective is minimized, typically Net Present Value (NPV).

The current framework is encoded into a *mixed-integer linear program* (MILP).
It has been formulated using [`JuMP`](https://github.com/jump-dev/JuMP.jl),
which enables the use of several solvers, included open-source solvers. 

`stre3am` is open-source and is subject to the terms of the [3-Clause BSD
License](https://opensource.org/license/BSD-3-clause/).

## Installation

At the Julia REPL press `]` mode, then `stre3am` can be obtained directly from
the repository as follows,

    add https://github.com/ANL-CEEESA/STREAM

## The `stre3am` layout

The source is organized as follows,

    .
    ├── LICENSE
    ├── Manifest.toml   # julia record of pakages
    ├── Project.toml    # julia dependencies
    ├── README.md   # project readme
    ├── data    # data folder
    │   ├── aeoCFs.jl
    │   ├── egridproc.jl
    │   └── prototype
    │       └── prototype_0.xlsx
    ├── docs
    │   ├── docs
    │   │   ├── about.md
    │   │   ├── img
    │   │   │   ├── 2025_logo.png
    │   │   │   ├── dre4m.svg
    │   │   │   ├── dre4mnoback.svg
    │   │   │   ├── wuy.svg
    │   │   │   ├── xv.svg
    │   │   │   ├── zyu.eps
    │   │   │   └── zyu.svg
    │   │   ├── index.md
    │   │   ├── input.md
    │   │   ├── javascripts
    │   │   │   └── mathjax.js
    │   │   ├── license.md
    │   │   └── model.md
    │   ├── mkdocs.yml
    │   ├── model_c # continuous model description
    │   │   ├── Makefile
    │   │   ├── bibl.bib
    │   │   └── stre3am_c.tex
    │   └── model_d # discrete model description
    │       ├── Makefile
    │       ├── stre3am_d.aux
    │       ├── stre3am_d.log
    │       ├── stre3am_d.out
    │       ├── stre3am_d.pdf
    │       └── stre3am_d.tex
    ├── instance    # case studies folder
    │   └── prototypes  # example prototypes
    │       ├── prototype.jl -> prototype_310123.jl
    │       └── prototype_310123.jl
    ├── src
    │   ├── stre3am.jl
    │   ├── stre3am_c
    │   │   ├── coef
    │   │   │   └── coef_custom.jl
    │   │   ├── kern
    │   │   │   └── modKern.jl
    │   │   ├── matrix  # data structures
    │   │   │   └── mat_struct.jl
    │   │   ├── mods    # models
    │   │   │   └── model.jl
    │   │   ├── post    # results postprocessing
    │   │   │   └── postprocess.jl
    │   │   ├── stre3am_c.jl
    │   │   └── utils   # this generates some useful plots
    │   │       ├── coalesce_py
    │   │       │   └── coalesce.py
    │   │       └── plot_py
    │   │           ├── generalD.py
    │   │           ├── pltBar.py
    │   │           ├── pltBars.py
    │   │           ├── pltEm.py
    │   │           ├── pltNpvAug.py
    │   │           ├── pltPerTech.py
    │   │           └── readExcelResults.py
    │   ├── stre3am_d
    │   │   ├── kern
    │   │   │   └── kern.jl
    │   │   ├── mod
    │   │   │   └── bm.jl
    │   │   ├── post
    │   │   │   └── postprocess.jl
    │   │   ├── stre3am_d.jl
    │   │   └── util
    │   │       ├── plot_py
    │   │       │   ├── bars.py
    │   │       │   ├── fuels.py
    │   │       │   ├── map_pie.py
    │   │       │   └── switches.py
    │   │       └── toy
    │   │           ├── bars.py
    │   │           ├── fuels.py
    │   │           ├── map_pie.py
    │   │           └── switches.py
    │   └── utils
    │       └── journalist.jl
    └── test
        ├── gestalt
        │   └── test_modKern.jl
        ├── matrix
        │   └── test_matrix.jl
        ├── mods
        │   └── test_mods.jl
        └── runtests.jl

    33 directories, 64 files

## Data requirements 

Before running a problem, please consult the data requirements from the
[input](input.md) page.

## Contributors

- David Thierry, Argonne National Laboratory, *ESIA division*
- Sarang Supekar, Argonne National Laboratory, *ESIA division*

## License
 

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)


`stre3am` is licensed under the 3-Clause BSD [license](license.md). 

Additionally, `stre3am` utilizes several dependencies, which have their own
licences. Refer to their respective repositories for more information about the
licenses.

[^1]: A new plant is constrained by several aspcects, including the availability
  of *empty location*. Please refer to the model document.
