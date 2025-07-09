# -*- coding: utf-8 -*-
# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy,
# Environmental, and Economic Analysis Model
# By: Argonne National Laboratory
# BSD-3 OPEN SOURCE LICENSE

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

# vim: expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2024
# switches.py
# notes: creates the switch plots.
# 80############################################################################

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import colormaps
import numpy as np
import datetime
import os
import sys

__author__ = "David Thierry @dthierry"


def pltrcparams():
    plt.rcParams.update({'font.size': 26})
    rfigsize = plt.rcParams['figure.figsize']
    ratio = rfigsize[1]/rfigsize[0]
    sarang_size = 6.9444444444
    plt.rcParams['figure.figsize'] = [sarang_size, sarang_size*ratio]
    plt.rcParams['font.sans-serif'] = "Helvetica"
    plt.rcParams['figure.autolayout'] = True

def hex_to_rgb(value):
    """Return (red, green, blue) for the color given as #rrggbb."""
    value = value.lstrip('#')
    lv = len(value)
    return tuple(int(value[i:i + lv // 3], 16) for i in range(0, lv, lv // 3))

def plot_legend(folder, colors_r, colors_n, labr, labn, frmt):
    f, a = plt.subplots(dpi=300)
    for i in range(1, len(labr)):
        a.bar([0], [0],
              label=labr[i],
              edgecolor="k", lw=1.5, color=colors_r[i])
        a.bar([0], [0],
              label=labn[i],
              color=colors_n[i])
    a.bar([0], [0],
          label="Retirement",
          edgecolor="k", lw=1.5, color=colormaps["Oranges"](999))
    a.bar([0], [0],
          label="Expansion",
          edgecolor="k", lw=1.5, color=colormaps["Reds"](999))

    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + "leg_switch", frmt)

def export_legend(legend, filename, frmt):
    """Put the legend in a "fmrt" different file.
    """
    #: be sure to have  --> bbox_to_anchor=(1.0, 0.0)
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent().transformed(
        fig.dpi_scale_trans.inverted()
    )
    filename = filename + f".{frmt}"
    fig.savefig(filename, dpi=300, bbox_inches=bbox, format=frmt)

def all_switches(f0, frmt):
    pltrcparams()
    dt = datetime.datetime.now()
    folder = dt.strftime("%c")
    folder = folder.replace(" ", "-")
    folder = folder.replace(":", "-")

    os.mkdir(folder)

    folder = './' + folder
    folder += '/'

    dyof = f0 + "/dyo.csv"
    dyef = f0 + "/dye.csv"

    dyrf = f0 + "/dyr.csv"
    dynf = f0 + "/dyn.csv"
    lrnf = f0 + "/lrn_info.csv"


    dyo = pd.read_csv(dyof)
    dye = pd.read_csv(dyef)

    dyr = pd.read_csv(dyrf)
    dyn = pd.read_csv(dynf)
    dlrn = pd.read_csv(lrnf)

    colors_r = [
        "#ffffff",
        "#cec44b",
        "#b0d54b",
        "#DAEFB3",
        "#68C5DB",
        "#6adc75",
        "#68b7a7",
        "#6890ca",
        "#6a5ee6",
    ]

    colors_n = [
        "#ffffff",
        "#e7b24b",
        "#ffebee",
        "#DAEFB3",
        "#68C5DB",
        "#6adc75",
        "#68b7a7",
        "#6890ca",
        "#6a5ee6",
    ]


    rlf = f0 + "/retro_labels.csv"
    nlf = f0 + "/new_labels.csv"

    rfilter_f = f0 + "/retro_filters.csv"
    nfilter_f = f0 + "/new_filters.csv"

    drl = pd.read_csv(rlf)
    labr = drl.iloc[:,0].to_list()
    dnl = pd.read_csv(nlf)
    labn = dnl.iloc[:,0].to_list()


    rfilter = pd.read_csv(rfilter_f)
    nfilter = pd.read_csv(nfilter_f)

    rtpc = [hex_to_rgb(i) for i in colors_r]
    ntpc = [hex_to_rgb(i) for i in colors_n]
#
    nloc = dlrn.loc[0, "n_loc"]
    nper = dlrn.loc[0, "n_p"]
    nsp = dlrn.loc[0, "n_p2"]

    ntslices = nper * nsp
    ytick = [i for i in range(0,nloc)]
    ylab = [f"{i}" for i in range(1,nloc+1)]
    ly = []

    for k in range(dlrn.loc[0, "n_rtft"]):
        yr = dyr[f"k_{k+1}_l_1"]  # this one always exists
        yo_l = dyo[f"l_1"].to_numpy()
        yr = np.multiply(yr, yo_l)
        for l in range(1, dlrn.loc[0, "n_loc"]):
            if rfilter.iloc[l, k]:
                c = f"k_{k+1}_l_{l+1}"
                yr_l = dyr[c].to_numpy()
                yo_l = dyo[f"l_{l+1}"].to_numpy()
                yr_l = np.multiply(yr_l, yo_l)
            else:
                yr_l = np.zeros(dyr.shape[0])

            yr = np.vstack((yr, yr_l))

        ly.append(yr)
        #yr = np.transpose(yr)

        f, a = plt.subplots()#figsize=(5, 25))

        a.set_xticks(np.arange(0, ntslices, 1))
        a.set_yticks(ticks=ytick, labels=ylab)

        a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
        a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

        a.imshow(yr.reshape(yr.shape[0], -1),
                 cmap="Greens", aspect="equal", interpolation="nearest", vmin=0)
        a.grid(which="minor", color="w", linestyle="-", linewidth=1)
        a.tick_params(which="minor", bottom=False, left=False)

        a.set_title(f"Retrofit {k} status")
        a.set_ylabel("Plant")
        a.set_xlabel("Subperiod")
        f.tight_layout()

        f.savefig(folder + f"rf_{k}_.{frmt}", dpi=200, transparent=True,
                  format=frmt)
        plt.close(f)

    matrix = [[rtpc[0] for col in range(ly[0].shape[1])] for row in range(ly[1].shape[0])]

    skip_cols = False
    for row in range(ly[0].shape[0]):
        skip_cols = False  # we only want a single switch
        for col in range(ly[0].shape[1]):
            c = rtpc[0]
            sum_elem = 0
            for k in range(len(ly)): # retrofit
                sum_elem += ly[k][row][col]
                if ly[k][row][col] > 0:
                    c = rtpc[k]
                    #print(f"k={k}", c)
                    if k > 0: #k=0 is the non rf/nw we have to skip it
                        skip_cols = True
            if sum_elem > 1:
                print("this is an error")
            matrix[row][col] = c
            if skip_cols:
                break

    f, a = plt.subplots()#figsize=(5, 25))

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))
    a.set_yticks(ticks=ytick, labels=ylab)

    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(matrix, aspect="equal")
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)

    a.set_title(f"Retrofit switch")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"rf_agg_.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)


    # generate the legend
    f, a = plt.subplots(dpi=300)
    for i in range(dlrn.loc[0, "n_rtft"]):
        a.bar([1], [1], label=labr[i], color=colors_r[i])
    l = a.legend(bbox_to_anchor=(1,1), loc="upper left")
    f.canvas.draw()
    bbox = l.get_window_extent().transformed(f.dpi_scale_trans.inverted())
    f.savefig(folder + f"legend_rf.{frmt}", bbox_inches=bbox, format=frmt)

    print(nfilter)
    ly = []
    for k in range(dlrn.loc[0, "n_new"]):
        yn = dyn[f"k_{k+1}_l_1"]
        for l in range(1, dlrn.loc[0, "n_loc"]):
            print(f"l={l}, k={k}, filter={nfilter.iloc[l,k]}")
            if nfilter.iloc[l, k]:  # 06-30-2025 I had to correct this
                c = f"k_{k+1}_l_{l+1}"
                yn_l = dyn[c].to_numpy()
            else:
                yn_l = np.zeros(dyn.shape[0])
            yn = np.vstack((yn, yn_l))

        ly.append(yn)
        #f, a = plt.subplots(figsize=(20, 5))
        #f, a = plt.subplots(figsize=(24, 8))
        f, a = plt.subplots()#figsize=(5, 25))

        a.set_xticks(np.arange(0, ntslices, 1))
        #a.set_yticks(np.arange(1, nloc+1, 1))
        #a.set_yticks(prange)
        a.set_yticks(ticks=ytick, labels=ylab)

        a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
        a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

        a.imshow(yn.reshape(yn.shape[0], -1),
                 cmap="Blues", aspect="equal", interpolation="nearest", vmin=0)
        a.grid(which="minor", color="w", linestyle="-", linewidth=1)
        a.tick_params(which="minor", bottom=False, left=False)

        a.set_title(f"New {k} switch")
        a.set_ylabel("Plant")
        a.set_xlabel("Subperiod")
        f.tight_layout()

        f.savefig(folder + f"nw_{k}_.{frmt}", dpi=200, transparent=True,
                  format=frmt)
        plt.close(f)


    matrix = [[ntpc[0] for col in range(ly[0].shape[1])] for row in range(ly[1].shape[0])]

    for row in range(ly[0].shape[0]):
        skip_cols = False  # we only want a single switch
        for col in range(ly[0].shape[1]):
            c = ntpc[0]
            sum_elem = 0
            for k in range(len(ly)):
                sum_elem += ly[k][row][col]
                if ly[k][row][col] > 0:
                    c = ntpc[k]
                    if k > 0: #k=0 is the non rf/nw we have to skip it
                        skip_cols = True
            if sum_elem > 1:
                print("this is an error")
            matrix[row][col] = c
            if skip_cols:
                break



    f, a = plt.subplots()#figsize=(5, 25))

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))
    a.set_yticks(ticks=ytick, labels=ylab)

    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(matrix, aspect="equal")
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)

    a.set_title(f"New plant switch")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"nw_agg_.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)


    # generate the legend
    f, a = plt.subplots(dpi=300)
    for i in range(dlrn.loc[0, "n_new"]):
        a.bar([1], [1], label=labn[i], color=colors_n[i])
    l = a.legend(bbox_to_anchor=(1,1), loc="upper left")
    f.canvas.draw()
    bbox = l.get_window_extent().transformed(f.dpi_scale_trans.inverted())
    f.savefig(folder + f"legend_nw.{frmt}", bbox_inches=bbox, format=frmt)

    nloc = dlrn.loc[0, "n_loc"]
    nper = dlrn.loc[0, "n_p"]
    nsp = dlrn.loc[0, "n_p2"]

    ntslices = nper * nsp

    yo_l = dyo.iloc[:,1:].to_numpy()

    yo = np.transpose(yo_l)

    # we want retirement
    yret = np.zeros(yo.shape)

    for row in range(yo.shape[0]):
        if yo[row, 0] < 1:  # first one is retired
            yred[row, col] = 1
        else:
            for col in range(1, yo.shape[1]):
                if yo[row, col] - yo[row, col-1] < 0:
                    yret[row, col] = 1.0



    f, a = plt.subplots()#figsize=(5, 25))

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))
    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(ticks=ytick, labels=ylab)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(yret, cmap="Reds", aspect="equal", interpolation="nearest", vmin=0)
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)


    a.set_title(f"Retirement switch")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"off.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)


    f, a = plt.subplots()

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))
    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(ticks=ytick, labels=ylab)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(yo, cmap="Reds", aspect="equal", interpolation="nearest", vmin=0)
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)


    a.set_title(f"Online")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"on.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)

    ye_l = dye.iloc[:,1:].to_numpy()
    yo_l = dyo.iloc[:,1:].to_numpy()

    ye_l = np.multiply(ye_l, yo_l)
    ye = np.transpose(ye_l)


    # we want earliest expansion
    yee = np.zeros(ye.shape)

    for row in range(ye.shape[0]):
        if ye[row, 0] > 0:
            yee[row, 0] = 1
        else:
            for col in range(1, ye.shape[1]):
                if ye[row, col] - ye[row, col-1] > 0:
                    yee[row, col] = 1.0


    f, a = plt.subplots()#figsize=(5, 25))

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))

    a.set_yticks(ticks=ytick, labels=ylab)

    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(yee.reshape(yee.shape[0], -1),
             cmap="Oranges", aspect="equal", interpolation="nearest", vmin=0)
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)

    a.set_title("Expansion switch")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"exps_.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)

    # actual expansion
    f, a = plt.subplots()#figsize=(5, 25))

    a.set_xticks(np.arange(0, ntslices, 1), labels=range(1, ntslices+1))
    #a.set_yticks(np.arange(1, nloc+1, 1))
    #a.set_yticks(prange)

    a.set_yticks(ticks=ytick, labels=ylab)

    a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
    a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

    a.imshow(ye.reshape(ye.shape[0], -1),
             cmap="Oranges", aspect="equal", interpolation="nearest", vmin=0)
    a.grid(which="minor", color="w", linestyle="-", linewidth=1)
    a.tick_params(which="minor", bottom=False, left=False)

    a.set_title("Expansion (Actual)")
    a.set_ylabel("Plant")
    a.set_xlabel("Subperiod")
    f.tight_layout()

    f.savefig(folder + f"exps_actual.{frmt}", dpi=200, transparent=True, format=frmt)
    plt.close(f)

    ###

    drl = pd.read_csv(rlf)
    labr = drl.iloc[:,0].to_list()
    plot_legend(folder, colors_r, colors_n, labr, labn, frmt)

    ###
    return folder
