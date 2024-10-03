# -*- coding: utf-8 -*-

# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: DRE4M: Decarbonization Roadmapping and Energy, Environmental,
# Economic, and Equity Analysis Model
# By: Argonne National Laboratory
# BSD OPEN SOURCE LICENSE

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.

# ******************************************************************************
# DISCLAIMER
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ******************************************************************************

# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

# created @dthierry 2022
# description: initialize some of the parameters that are used to generate the
# plots from the manuscript.
#
# log:
# 1-30-23 added some comments
#
#
#80#############################################################################

import os, fnmatch
from typing import Tuple


# number of technologies
I = 11
# kinds for existing assets
kinds_w = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

# fuel based boolean
fuelKind = [True, True, True, True, True, False, False, False, False, False,
            False]

# colormap
CMAP0 = "tab20c"

# key names
tName = ["pc", "ct", "cc" ,"p" ,"b" ,"n" ,"h" ,"w" ,"spv" ,"sth" ,"g"]

# swap case
tName = [n.swapcase() for n in tName]

# dictionary for label
dName = {"w": "Existing", "z": "Retrofit", "x": "New",
        "uw": "Ret. old", "uz": "Ret. retrof.", "ux": "Ret. new"}

# gray scale colours
greyes = ["dark grey", "battleship grey", "blue grey",
        "cement", "charcoal grey", "brown grey",
        "cool grey", "dark blue grey", "green grey",
        "grey teal"]

# normal colour list
colList = ["berry", "blood", "blueberry", "blurple",
        "dark sky blue", "deep lavender", "butterscotch",
        "primary blue", "cool blue", "cobalt"]

# default colour list
colL = greyes

# base type of tech, e.g. existing (w), rf (z), and new (x)
names = ["w", "uw", "z", "uz", "x", "ux"]
namesW = ["w", "z", "x"]

# filling patterns
for i in range(len(colL)):
    colL[i] = "xkcd:" + colL[i]
hatches = ['/', '\\', '|', '-', '+', 'x', 'o', 'O', '.', '*']


def getFiles(pattern: str, path: str="."):
    """Walk through the current directory to find the required files.
    """
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
                print("Using file {}".format(os.path.join(root, name)))
                return os.path.join(root, name)
    return None



def loadKinds() -> Tuple[list, list]:
    """Open the _kinds.txt file and check for the kinds of existing plant
    retrofits and new plants.
    """
    filename = getFiles("*_kinds.txt")
    kinds_z = list()
    kinds_x = list()

    with open(filename, "r") as f:
        lines = f.readlines()
        d = list()
        for l in lines:
            l = l.split()[0]
            if l == "kinds_z":
                d = kinds_z
            elif l == "kinds_x":
                d = kinds_x
            else:
                d.append(int(l))
    return (kinds_z, kinds_x)

# generate the rf and new kinds lists
(kinds_z, kinds_x) = loadKinds()

# kinds dictionary
kinds = {}
kinds = {"z": kinds_z, "x": kinds_x, "uz": kinds_z, "ux": kinds_x, "w": kinds_w,
         "uw": kinds_w}


def export_legend(legend, filename="legend.png"):
    """Put the legend in a png different file.
    """
    #: be sure to have  --> bbox_to_anchor=(1.0, 0.0)
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent().transformed(
        fig.dpi_scale_trans.inverted()
    )
    fig.savefig(filename, dpi=300, bbox_inches=bbox)

