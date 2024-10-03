#!/usr/bin/env python
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
# description: generate the plot with the npvs
#
# log:
# 1-30-23 added some comments
#
#
#80#############################################################################

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from generalD import *
import os, fnmatch

plt.rcParams.update({ #: set the font
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Palatino"],
})


__author__ = "David Thierry"

def whichRetrofit(series) -> bool:
    """Returns a list of booleans based on the tags.
    E.g., if tag has RF then RF label = True, etc.
    """
    resRfList = []
    resClList = []
    resBaList = []
    for i in series.index:
        rRf = False
        rCl = False
        rBa = False
        l = i.split("_")
        while len(l) != 0:
            label_ = l.pop()
            if label_ == "RF":
                rRf = True
            elif label_ == "CLT":
                rCl = True
            elif label_ == "BAU":
                rBa = True
        resRfList.append(rRf)
        resClList.append(rCl)
        resBaList.append(rBa)
    return resRfList, resClList, resBaList

def getFiles(pattern, path="."):
    """Same function as in generalD. Finds the whole path of the required file.
    """
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
                print("Using file {}".format(os.path.join(root, name)))
                return os.path.join(root, name)
    return None


def plot_npv_bars():
    """Generate the NPV plots (with CO2) for the electricity
    generation problem
    """
    file = getFiles("coalesce.xlsx", path=".")
    eFile = pd.ExcelFile(file)
    df1 = eFile.parse(sheet_name="old_co2", index_col=0)
    df2 = eFile.parse(sheet_name="retro_co2", index_col=0)
    df3 = eFile.parse(sheet_name="new_co2", index_col=0)

    df1.drop(0, axis=1, inplace=True)#
    df2.drop(0, axis=1, inplace=True)#
    df3.drop(0, axis=1, inplace=True)#

    o_co2 = df1.tail(1).iloc[0, :]
    r_co2 = df2.tail(1).iloc[0, :]
    n_co2 = df3.tail(1).iloc[0, :]
    total_co2 = o_co2 + r_co2 + n_co2
    clrl = ["tomato", #"#15D666", 0
            "#15D6C7", # 1
            "#1585D6", # 2
            "#1524D6", # 3
            "#D61585", # 4
            "#C615D6", # 5
            "#D61525", # 6
            "#6615D6", # 7
            "#D66615", # 8
            "#00D659", # 9
            "#00D6C4", # 10
            "#007DD6", # 11
            "#0012D6", # 12
            "#D6007D", # 13
            "#C400D6", # 14
            "#D60012", # 15
            "#5900D6", # 16
            "#D65900" # 17
            ]
    hatches = ['/', # 0
               '\\', # 1
               '//', # 2
               '', # 3
               'o', # 4
               '|', # 5
               '.', # 6
               '//', # 7
               '\\\\', # 8
               '', # 9
               '|', # 10
               '', # 11
               '', # 12
               '**', # 13
               '..', # 14
               '***' # 15
               ]
    cost_sheets = ["cap_cost_retro", # 0
                   "cap_cost_new", # 1
                   "old_VoNm", # 2
                   "retro_VoNm", # 3
                   "new_VoNm", # 4
                   "old_FoNm", # 5
                   "retro_FoNm", # 6
                   "new_FoNm", # 7
                   "old_RetCost", # 8
                   "retro_RetCost", # 9
                   "new_RetCost", # 10
                   "old_fuel", # 11
                   "retro_fuel", # 12
                   "new_fuel" # 13]
                   ]
    labels = [
        "Cap. cost retro.", #0
        "Cap. cost new", #1
        "Exist. V O\&M c.", #2
        "Retro. V O\&M c.", #3 ##
        "New V O\&M c.", #4
        "Exist. F O\&M c.", #5
        "Retro. F O\&M c.", #6 ##
        "New F O\&M c.", #7
        "Exist. Retire. c.", #8
        "Retro. Retire. c.", #9 ##
        "New Retire. c.", #10
        "Exist. Fuel c.", #11
        "Retro. Fuel c.", #12 ##
        "New Fuel c." #13
    ]

    row = [11, #0 ##
           15, #1
           12, #2
           11, #3 ##
           15, #4
           12, #5
           11, #6 ##
           15, #7
           12, #8
           11, #9 ##
           15, #10
           7, #11
           11, #12 ##
           10 #13
           ]
    file = getFiles("coalesce.xlsx", path=".")
    eFile = pd.ExcelFile(file)
    i = 0
    x_pos = np.arange(2)
    f, a = plt.subplots(dpi=200)
    #a.grid(visible=True, which="major", axis="y")
    for cs in cost_sheets:
        df = eFile.parse(sheet_name=cs, index_col=0)
        #s = df.iloc[row[i], 1:]
        df.drop(0, axis=1, inplace=True)
        s = df.tail(1).iloc[0, :]
        lendf = s.shape[0]
        if i == 0:
            s0 = pd.Series(np.zeros(lendf))
        #print(i, cs, row[i])
        print(s)
        print(s0)
        x_pos = np.arange(lendf)
        print(x_pos)
        b = a.bar(x_pos,
                  s,
                  align="center",
                  bottom=s0,
                  label=labels[i],
                  color=clrl[i],
                  hatch=hatches[i])
        if i == 0:
            s0 = s.copy()
        else:
            s0 = s0.add(s)
        i += 1
    whichRf, whichCl, whichBa = whichRetrofit(s)
    b = a.bar(x_pos, s0, align="center", color="none")
    print("emissions")
    print(total_co2)
    ax2 = a.twinx()
    col_scat = ["r" if whichCl[i] else "k" for i in range(len(b))]
    ax2.scatter(x_pos, total_co2, marker="D", c=col_scat, alpha=0.8,
                label="CO2")
    ax2.set_ylabel("Millions ton CO2")
    ax2.set_ylim((0, max(total_co2)*1.05))
    ax2.legend(loc=0)

    for i in range(len(b)):
        if whichRf[i]:
            b[i].set_lw(1)
            color = "r" if whichCl[i] else "k"
            b[i].set_edgecolor(color)
        if whichBa[i]:
            b[i].set_hatch("/")

    ticks = a.set_xticks(x_pos, labels=s.index, rotation=90)
    for i in range(len(ticks)):
        if whichRf[i]:
            color = "r" if whichCl[i] else "k"
            ticks[i].get_children()[3].set_color(color)
            # print(ticks[i].get_children())
    a.set_ylabel("Millions \$")
    a.set_title("Overall costs \& CO2 emission")
    a.bar_label(b, padding=-50, fmt="%.2E", rotation=90)
    f.savefig("npvAndco.png", bbox_inches="tight")
    # save the legend
    legend = a.legend(loc="lower left",
        bbox_to_anchor=(1.2, 0.0)
    )
    export_legend(legend, filename="legend_npvco2.png")

if __name__ == "__main__":
   plot_npv_bars()

