#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy,
# Environmental, and Economic Analysis Model
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
# pltBar.py
# description: generate the plots with the big rectangles.
#
# log:
# 1-31-23 added some comments
#
#
#80#############################################################################

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize as nrm
from matplotlib.cm import ScalarMappable as smb
import sys, getopt

__author__ = "David Thierry"

plt.rcParams.update({
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Palatino"],
})


def main(argv):
    """generate the whole plot. This file needs command line arguments:
    `-i xxxx`
    """
    file = ""
    try:
        opts, args = getopt.getopt(argv, "hi:o:", ["ifile="])
    except getopt.GetoptError:
        print("pltBar.py -i <inputfolder>")
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            print("pltBar.py -i <inputfolder>")
            sys.exit()
        elif opt in ("-i", "--file"):
            file = arg
            print("file")
            print(file)
    print(f"Input folder : {file}")
    CMAP0 = "tab20c"
    cmap = plt.get_cmap("Greens")
    norm = nrm(vmin=0.0, vmax=1.)


    dfCost = pd.read_excel(file + "_ret_rel_t.xlsx")
    dfUret = pd.read_excel(file + "_ret_t_ucap.xlsx")
    dfProc = pd.DataFrame(0., index=[0, 1], columns=dfCost.columns)
    dfProc.iloc[0, :] = dfCost.sum(0)
    dfProc.iloc[1, :] = dfUret.sum(0)

    # f, a = plt.subplots()
    # base = 0.
    # for t in np.linspace(0.1, 1., 10):
    #     c = cmap(norm(t))
    #     t = round(t, 2)
    #     for i in range(dfCost.shape[0]):
    #         if dfCost.loc[i, t] < 1e-08:
    #             continue
    #         a.bar(0, dfCost.loc[i, t],
    #                 width=dfUret.loc[i, t],
    #                 bottom=base,
    #                 align="edge",
    #                 color=c,
    #                 edgecolor="k",
    #                 linewidth=1.,
    #                 label=dfCost.loc[i, "t"]
    #                 )
    #         base += dfCost.loc[i, t]
    # a.set_xlabel("Retired Capacity (GW)")
    # a.set_ylabel("Retired Capacity Cost (Millions \$)")
    # a.legend()
    #f.savefig("myfig.png", format="png")

    # f, a = plt.subplots()
    # base = 0.
    # for t in np.linspace(0.1, 1., 10):
    #     c = cmap(norm(t))
    #     t = round(t, 2)
    #     a.bar(0, dfProc.loc[0, t],
    #             width=dfProc.loc[1, t],
    #             bottom=base,
    #             align="edge",
    #             color=c,
    #             edgecolor="k",
    #             linewidth=1.,
    #             label=t)
    #     base += dfProc.loc[0, t]
    # a.legend(title="Relative retirement time")
    # a.set_xlabel("Capacity (GWh)")
    # a.set_ylabel("Cost (M\$)")
    # f.savefig("myfig2.png", format="png")

    #: plot array
    f, a = plt.subplots(nrows=1, ncols=2,
                        sharex="all", sharey="all",
                        constrained_layout=True, dpi=200)
    #: read some dataframes
    df_xCost = pd.read_excel(file + "_stats.xlsx", sheet_name="cap_cost_new")
    df_xCap = pd.read_excel(file + "_stats.xlsx", sheet_name="new_alloc")
    df_xCost.drop(df_xCost.tail(1).index, inplace=True) # drop the sum bit
    df_xCap.drop(df_xCap.tail(1).index, inplace=True) # drop the sum bit
    xcost = df_xCost.sum(0)[1]
    xcap = df_xCap.sum(0)[1]

    print("cost {}".format(xcost), "cap {}".format(xcap))
    base = 0.
    for t in np.linspace(0.1, 1., 10):
        c = cmap(norm(t))
        t = round(t, 2)
        a[0].bar(0, dfProc.loc[0, t],
                width=dfProc.loc[1, t],
                bottom=base,
                align="edge",
                color=c,
                edgecolor="k",
                linewidth=1.,
                label=t,
                 hatch="/")
        base += dfProc.loc[0, t]
    #a[0].legend(title="Relative retirement time")
    a[0].set_xlabel("(GW)")
    a[0].set_ylabel("Cost (Millions \$)")
    a[0].ticklabel_format(axis="y", style="sci", scilimits=(-1, 4))
    a[0].set_title("Existing Cap. Retirement", y=1.0, pad=-10)
    #a[0].grid(visible=True, which="major", axis="y")

    #a[0].set_yscale("log")
    #a[0].set_xscale("log")
    #a[0].ticklabel_format(axis="both", style="sci", scilimits=(-1,1))
    ax1 = a[0].inset_axes([0.25, 0.25, 0.5, 0.5])
    cb = f.colorbar(smb(norm=norm, cmap=cmap), ax=a[0],
                    fraction=0.05, ticks=[0, 1])
    cb.set_label("Relative Age")
    cb.ax.locator_params(nbins=4)
    cb.ax.set_yticklabels(["Newer", "Older"], rotation=90)
    base = 0.
    for t in np.linspace(0.1, 1., 10):
        c = cmap(norm(t))
        t = round(t, 2)
        ax1.bar(0, dfProc.loc[0, t],
                width=dfProc.loc[1, t],
                bottom=base,
                align="edge",
                color=c,
                edgecolor="k",
                linewidth=1.,
                label=t,
                hatch="/")
        base += dfProc.loc[0, t]
    x1, x2, y1, y2 = 0., dfProc.iloc[1,1:].max()*1.02, 0., base * 1.02
    ax1.set_xlim(x1, x2)
    ax1.set_ylim(y1, y2)
    ax1.locator_params(nbins=3)
    #ax1.set_xticklabels([])
    #ax1.set_yticklabels([])
    ax1.ticklabel_format(axis="y", style="sci", scilimits=(-1, 4))
    ax1.set_facecolor("#ebebeb")
    r, lines = a[0].indicate_inset_zoom(ax1, edgecolor="r")
    for l in lines:
        l.set(linewidth=1.0, visible=True)
    ax1.set_title("Detailed", loc="right")
    print(l)
    a[1].bar(0, xcost, width=xcap, align="edge", color="tomato",
             label="new cost", hatch=".")
    a[1].set_xlabel("(GW)")
    a[1].set_ylabel("Cost (Millions \$)")
    a[1].set_title("New Alloc.", y=1.0, pad=-10)
    #a[1].ticklabel_format(axis="both", style="sci", scilimits=(-1,1))
    #a[1].set_yscale("log")
    #a[1].set_xscale("log")
    f.savefig("blocks_V1.png", format="png")


if __name__ == "__main__":
    main(sys.argv[1:])


