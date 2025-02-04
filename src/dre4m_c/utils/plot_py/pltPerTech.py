#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy,
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

# written by David Thierry @dthierry 2022
# pltPerTech.py
# description: Generate plots of the results from the capacities.
#
# log:
# 1-30-23 added some comments
#
#
#80#############################################################################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize as nrm
from matplotlib.cm import ScalarMappable as smb
from matplotlib.colors import ListedColormap
from generalD import *

# the list names comes from generalID

__author__ = "David Thierry"
plt.rcParams['hatch.linewidth'] = 0.2

# number 1
def singleBars(tech: int, kindStr: str):
    """ Generates the plots for the capacities individually for each
    technology and kind, e.g. w_1, w_2, ..., z_1_1, z_1_2, ..., etc.
    Output files are named bars_{}_{}_{}.png
    """

    excelFileName = getFiles("*_effective.xlsx")
    if kindStr not in namesW:
        raise Exception("kindStr has to be w, z, or x")
    realName = tName[tech]
    nameK = []
    for name in [kindStr, "u" + kindStr]:
        kind = kinds[name]
        for k in range(kind[tech]):
            if name in ["w", "uw"]:
                sheet0 = name + "_" + str(tech)
            else:
                sheet0 = name + "_" + str(tech) + "_" + str(k)
            nameK.append(sheet0)
    dfs = {}
    #print(nameK)
    for name in nameK:
        d = pd.read_excel(excelFileName, sheet_name=name, index_col=0)
        d = d.drop(columns="Unnamed: 1")
        dfs[name] = d
    if len(nameK) == 0:
        print("Empty kind")
        return
    f, a = plt.subplots(dpi=50)
    df0 = pd.Series([0 for i in d.index])
    cmap = plt.get_cmap(CMAP0)
    dfu = pd.Series([0 for i in d.index])

    kind = kinds[kindStr]
    yu = 1
    yl = -1
    for k in range(kind[tech]):
        if kindStr == "w":
            name = kindStr + "_" + str(tech)
        else:
            name = kindStr + "_" + str(tech) + "_" + str(k)
        d = dfs[name]
        # create cmap nrm
        list_of_columns = d.columns
        for i in list_of_columns:
            print(i.split("="))
        # if kindStr == "z":
        #    list_of_columns = [c.replace("-", "=") for c in d.columns]
        l = [int(c.split("=")[1]) for c in list_of_columns]
        n = nrm(vmin=min(l), vmax=max(l))
        for c in d.columns:
            if kindStr == "z":
                c_val = c.replace("-", "=")
            else:
                c_val = c
            colour = cmap(n(int(c_val.split("=")[1])))
            bC = a.bar(d.index + 2016, d[c],
                    bottom=df0,
                    #label=c,
                    color=colour,
                    # alpha=0.1,
                    linewidth=0.3,
                    edgecolor="k")
            df0 += d[c]
        yu = max(yu, df0.max())
        #a.legend(loc=0, ncol=2)
        cb = f.colorbar(smb(norm=n, cmap=cmap), ax=a, fraction=0.05)
        cbar_label = "Age"
        cb.set_label(cbar_label)


        # decomission
        if kindStr == "w":
            name = "u" + kindStr + "_" + str(tech)
        else:
            name = "u" + kindStr + "_" + str(tech) + "_" + str(k)

        d = dfs[name]
        d = d.mul(-1)
        for c in d.columns:
            if kindStr == "z":
                c_val = c.replace("-", "=")
            else:
                c_val = c
            colour = cmap(n(int(c_val.split("=")[1])))
            a.bar(d.index + 2015, d[c],
                    bottom=dfu,
                    color=colour,
                    #edgecolor="k", lw=0.3
                    )
            dfu += d[c]
        yl = min(yl, dfu.min())
    yl = round(int(yl*1.01), -3)
    print(yu)
    yu = round(int(yu*1.01), -3) + 1e3
    print(yu)
    yl = yl if yl <= (yu-1e3) else yu-1e3
    yl -= 1e3
    print(yl, yu, kindStr, tech)
    #a.set_ylim([yl, yu])
    a.set_xlabel("Year")
    a.set_ylabel("GW")
    a.hlines(0, min(d.index)+2015-1, max(d.index)+2015+1, color="k",
             linestyle="dotted")
    a.spines["top"].set_visible(False)
    a.spines["right"].set_visible(False)
    a.spines["bottom"].set_visible(False)
    a.set_title(realName)
    ##
    efn = excelFileName.split(".")[1].replace("/", "")
    f.savefig("bars_{}_{}_{}.png".format(tech, kindStr, efn),
            format="png")
    plt.close(f)
    print("saved!")
    return d

# number 2
def wAndXandZbars(tech: int):
    """ This one plots the distribution of ages for existing and new.
    It also plots retrofits, but it only uses a single colour"""
    excelFileName = getFiles("*_effective.xlsx")
    realName = tName[tech]
    #name0 = [name + "_" + str(tech) for name in names]
    name0 = []
    for name in names:
        kind = kinds[name]
        for k in range(kind[tech]):
            if name in ["w", "uw"]:
                sheet0 = name + "_" + str(tech)
            else:
                sheet0 = name + "_" + str(tech) + "_" + str(k)
            name0.append(sheet0)
    # name1 = [name + "_" + str(tech) for name in namesW]
    name1 = []
    for name in namesW:
        kind = kinds[name]
        for k in range(kind[tech]):
            if name in ["w", "uw"]:
                sheet0 = name + "_" + str(tech)
            else:
                sheet0 = name + "_" + str(tech) + "_" + str(k)
            name1.append(sheet0)
    doesItHaveZ = True if len(name1) == 3 else False
    dfs = {}
    for name in name1:
        d = pd.read_excel(excelFileName, sheet_name=name, index_col=0)
        d = d.drop(columns="Unnamed: 1")
        dfs[name] = d
        if doesItHaveZ:
            if name == name[1]:
                dfs[name] = pd.DataFrame(d.sum(axis=1)) # retrofit is sum
    #
    f, a = plt.subplots(dpi=50)

    cmap = plt.get_cmap("tab20c")
    # create the alphaed cmap
    my_cmap = cmap(np.arange(cmap.N))
    my_cmap[:,-1] = 0.3  #0.2 alpha
    my_cmap = ListedColormap(my_cmap)

    l = [int(c.split("=")[1]) for c in dfs[name1[0]].columns]
    n = nrm(vmin=min(l), vmax=max(l))
    d = dfs[name1[2]] if doesItHaveZ else dfs[name1[1]]
    lx = [int(c.split("=")[1]) for c in d.columns]
    nx = nrm(vmin=min(lx), vmax=max(lx))
    yuw = 1e3
    yux = 1e3
    yuz = 1e3
    yu = 1e3
    df0 = pd.Series([0 for i in d.index])
    # w
    d = dfs[name1[0]]
    for c in d.columns:
        colour = cmap(n(int(c.split("=")[1])))
        bC = a.bar(d.index+2015+1, d[c],
                bottom=df0,
                #label="w",
                color=colour,
                alpha=1,
                linewidth=0.1,
                edgecolor="black")
        df0 += d[c]
        yu = max(yu, df0.max())
    # z (with a single colour)
    # d = dfs[name1[1]].shift(fill_value=0)
    if doesItHaveZ:
        d = dfs[name1[1]]
        for c in d.columns:
            colour = "ghostwhite"
            bC= a.bar(d.index+2015+1, d[c],
                    bottom=df0,
                    label="z",
                    color=colour,
                    linewidth=0.8,
                    #alpha=0.5,
                    hatch="\\",
                    edgecolor="black")
            df0 += d[c]
            yu = max(yu, df0.max())
    # x
    d = dfs[name1[2]] if doesItHaveZ else dfs[name1[1]]
    for c in d.columns:
        colour = my_cmap(nx(int(c.split("=")[1])))
        bC = a.bar(d.index+2015+1, d[c],
                bottom=df0,
                #label=c,
                color=colour,
                linewidth=0.1,
                edgecolor="k",
                hatch=3*"o")
        df0 += d[c]
        yu = max(yu, df0.max())
    #a.legend(loc=0, ncol=2)
    cbw = f.colorbar(smb(norm=n, cmap=cmap), ax=a, fraction=0.05)
    cbx = f.colorbar(smb(norm=nx, cmap=my_cmap), ax=a, fraction=0.05)
    #cbw.set_label("existing")
    #cbw.set_ticks([0, 25])
    #cbx.set_label("new")
    #cbx.set_ticks([0, 25])
    #a.legend(loc=0)
    a.set_xlabel("Year")
    a.set_ylabel("GWh")
    #yu = yuw + yux + yuz

    yu = round(int(yu*1.01), -3) + 1e3
    #a.set_ylim(0, yu)

    a.set_title(realName)
    efn = excelFileName.split(".")[1].replace("/", "")
    f.savefig("wAndzAndx_{}_{}.png".format(tech, efn), format="png")
    plt.close(f)
    print("saved!")

# number 3
def wAndZbars(tech: int):
    """This one plots only existing + retrofits with age distribution with
    colours. Though, typically retrofits are very skewed to the end."""
    excelFileName = getFiles("*_effective.xlsx")
    realName = tName[tech]
    name1 = []
    for name in namesW:
        kind = kinds[name]
        for k in range(kind[tech]):
            if name in ["w", "uw"]:
                sheet0 = name + "_" + str(tech)
            else:
                sheet0 = name + "_" + str(tech) + "_" + str(k)
            name1.append(sheet0)

    dfs = {}
    for name in name1:
        d = pd.read_excel(excelFileName, sheet_name=name, index_col=0)
        d = d.drop(columns="Unnamed: 1")
        dfs[name] = d

    f, a = plt.subplots(dpi=50)
    cmap = plt.get_cmap("tab20c")

    l = [int(c.split("=")[1]) for c in dfs[name1[0]].columns]
    n = nrm(vmin=min(l), vmax=max(l))
    nz = n

    yu = 1e3
    df0 = pd.Series([0 for i in d.index])
    # w
    d = dfs[name1[0]]
    for c in d.columns:
        colour = cmap(n(int(c.split("=")[1])))
        bC = a.bar(d.index, d[c],
                bottom=df0,
                # label="w",
                color=colour,
                linewidth=0.1,
                edgecolor="k")
        df0 += d[c]

    # z
    d = dfs[name1[1]]
    d = d.shift(fill_value=0)
    k = 0
    for c in d.columns:
        zstr = c.replace("-", "=")
        zn = int(zstr.split("=")[1])
        print(zstr, zn)
        colour = cmap(nz(zn))
        bC = a.bar(d.index, d[c],
                bottom=df0,
                color=colour)
        df0 += d[c]
        k += 1
    yu = max(yu, df0.max())
    yu = round(int(yu*1.01), -3)
    #a.legend(loc=0, ncol=2)
    #a.set_ylim(top=yu)
    cbw = f.colorbar(smb(norm=n, cmap=cmap), ax=a, fraction=0.05)
    # cbz = f.colorbar(smb(norm=nz, cmap=cmap), ax=a, fraction=0.05)
    cbw.set_label("existing")
    cbw.set_ticks([0, 25])
    a.set_xlabel("year")
    a.set_ylabel("GWh")
    a.set_title(realName)
    f.savefig("wAndz_{}.png".format(tech), format="png")
    plt.close(f)
    print("saved!")



if __name__ == "__main__":
    for i in range(I):
        singleBars(i, "w")
    for i in range(3):
        singleBars(i, "x")
    for i in range(3):
        singleBars(i, "z")
    for i in range(I):
        wAndXandZbars(i)
    for i in range(I):
        wAndZbars(i)

