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
# bars.py
# notes: creates output analysis plots.
# 80############################################################################

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import datetime
import os
import sys

__author__ = "David Thierry @dthierry"


# 80############################################################################
def pltrcparams():
    #plt.rcParams.update({'font.size': 26})
    plt.rcParams.update({'font.size': 16})
    rfigsize = plt.rcParams['figure.figsize']
    ratio = rfigsize[1]/rfigsize[0]
    #sarang_size = 6.9444444444
    #plt.rcParams['figure.figsize'] = [sarang_size, sarang_size*ratio]
    plt.rcParams['font.sans-serif'] = "Helvetica"
    plt.rcParams['figure.autolayout'] = True


# 80############################################################################
def main():
    try:
        arg = sys.argv[1]
    except IndexError:
        raise SystemExit(f"Usage: {sys.argv[0]} <string>")
    pltrcparams()
    #reference folder
    rf = arg

    y0 = 2020
    yend = 2026
    p_scale = 6

    plt.style.use("seaborn-v0_8-colorblind")
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    dt = datetime.datetime.now()
    folder = dt.strftime("%c")
    folder = folder.replace(" ", "-")
    folder = folder.replace(":", "-")

    os.mkdir(folder)
    print(f"Folder = {folder}")
    folder = './' + folder
    folder += '/'


    colors = [
        "#e7b24b",
        "#cec44b",
        "#b0d54b",
        "#DAEFB3",
        "#68C5DB",
        "#6adc75",
        "#68b7a7",
        "#6890ca",
        "#6a5ee6",
    ]

    rlf = "retro_labels.csv"
    nlf = "new_labels.csv"

    drl = pd.read_csv(rlf)
    labr = drl.iloc[:,0].to_list()
    dnl = pd.read_csv(nlf)
    labn = dnl.iloc[:,0].to_list()

    # plot_legend(rf, folder, colors, labr, labn)

    # plot_capacities(rf, folder, colors, labr, labn, xaxislabel="year")
    # plot_cumulative_expansion(rf, folder, colors, xaxislabel="year")
    # plot_ep1(rf, folder, colors, labr, labn, xaxislabel="year")
    # plot_elec_by_tech(rf, folder, colors, labr, labn, xaxislabel="year")
    # plot_emisions(rf, folder, xaxislabel="year")
    # plot_bar_by_loc(rf, folder, colors, labr, labn, xaxislabel="year")
    # # plot_pie_by_loc(rf, folder, colors, labr, labn)
    # plot_em_bar_v2(rf, folder, colors, labr, labn, xaxislabel="year")
    # plot_co2_cap_bar(rf, folder, colors, labr, labn, xaxislabel="year")

    plot_capf(rf, folder, colors, labr, labn, xaxislabel="year")

# 80############################################################################
def plot_emisions(rf, folder, xaxislabel=None):
    emf = rf +"/em.csv"
    df = pd.read_csv(emf)

    infof = rf + "/s_info.csv"
    df = rescale_stre3am(df, infof, "em")

    #x = np.linspace(y0, yend, num=(p_scale+1))
    #x = x[0:p_scale]

    if xaxislabel == "year":
        xvals = df.iloc[:, 0]
        w = (df.iloc[1, 0] - df.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(df.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    a.bar(xvals, df.iloc[:, 1], width=w, label="Exist+RF+Exp(On-site)",
          edgecolor="k", align="edge", lw=1.5)
    b = df.iloc[:, 1]

    a.bar(xvals, df.iloc[:, 2], width=w, label="Exist+RF+Exp(Grid)",
          bottom=b, edgecolor="k", align="edge", lw=1.5)

    b += df.iloc[:, 2]

    a.bar(xvals, df.iloc[:, 3], width=w, label="New(On-site)",
          bottom=b, edgecolor="k", align="edge", lw=1.5)

    b += df.iloc[:, 3]

    a.bar(xvals, df.iloc[:, 4], width=w, label="New(Grid)",
          bottom=b, edgecolor="k", align="edge", lw=1.5)

    b += df.iloc[:, 4]
    # a.plot(xvals, df.iloc[:, 5], label="CO2Budget",
    #        lw=2, color="r", ls="--", marker="*")

    ymax = b.max().max()
    a.set_title("CO2 Emissions")
    a.set_xlabel("Year")
    a.set_ylabel("tonneCO2/yr")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "co2b.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_co2.png")


# 80############################################################################
def plot_capacities(rf, folder, colors, labr, labn, xaxislabel=None):
    cprf = rf + "/drcp.csv"
    cpnf = rf + "/dncp.csv"
    demf = rf + "/demand.csv"
    infof = rf + "/s_info.csv"

    dfr = pd.read_csv(cprf)
    dfr = rescale_stre3am(dfr, infof, "cap")

    dfn = pd.read_csv(cpnf)
    dfn = rescale_stre3am(dfn, infof, "cap")

    dfd = pd.read_csv(demf)
    dfd = rescale_stre3am(dfd, infof, "cap")

    if xaxislabel == "year":
        xvals = dfr.iloc[:, 0]
        w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dfr.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    b = pd.DataFrame([0.0 for i in range(dfr.shape[0])])
    for i in range(1, dfr.shape[1]):
        a.bar(xvals, dfr.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1])
        b.iloc[:, 0] += dfr.iloc[:, i]

    for i in range(1, dfn.shape[1]):
        a.bar(xvals, dfn.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1],
              hatch="//")
        b.iloc[:, 0] += dfn.iloc[:, i]

    ymax = b.max().max()
    a.plot(xvals, dfd.iloc[:, 0],
           label="Demand", lw=2, color="blue", ls="--", marker="*")

    a.set_title("(a) (STREAM) Cement Production/Demand")
    a.set_xlabel("Year")
    a.set_ylabel("tonne/yr")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "demand-.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_cap.png")


# 80############################################################################
def plot_electricity(rf, folder, colors, labr, labni, xaxislabel=None):
    uf = rf +"/u.csv"
    infof = rf + "/s_info.csv"

    df = pd.read_csv(uf)
    df = rescale_stre3am(df, infof, "elec")

    if xaxislabel == "year":
        xvals = df.iloc[:,0]
        w = (df.iloc[1, 0] - df.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(df.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    a.bar(xvals, df.iloc[:,0], width=w, label="Exist+RF", edgecolor="k",
          align="edge", lw=1.5)

    b = df.iloc[:, 0]

    a.bar(xvals, df.iloc[:,1], width=w, label="New Plant", bottom=b,
          edgecolor="k", align="edge", lw=1.5)


    a.set_title("Electricity")
    a.set_xlabel("Year")
    a.set_ylabel("MMBTU/yr")
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "u.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend.png")


# 80############################################################################
def plot_loans(rf, folder, colors, labr, labn, xaxislabel=None):

    rlf = rf + "/drloan.csv"
    drl = pd.read_csv(rlf)

    infof = rf + "/s_info.csv"
    drl = rescale_stre3am(drl, infof, "cash")


    base = pd.DataFrame([0.0 for i in range(drl.shape[0])])

    if xaxislabel == "year":
        xvals = drl.iloc[:,0]
        w = (drl.iloc[1, 0] - drl.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(drl.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    for l in range(1, drl.shape[1]):
        a.bar(xvals, height=drl.iloc[:, l],
              width=w, bottom=base.iloc[:, 0], align="edge", edgecolor="w",
              lw=0.01, color="#0067A8")
        base.iloc[:, 0] += drl.iloc[:, l]

    elf = rf + "/deloan.csv"
    d_el = pd.read_csv(elf)
    d_el = rescale_stre3am(d_el, infof, "cash")

    for l in range(1, d_el.shape[1]):
        a.bar(xvals, height=d_el.iloc[:, l],
              width=w, bottom=base.iloc[:, 0], align="edge", edgecolor="w",
              lw=0.01, color="#009368")
        base.iloc[:, 0] += d_el.iloc[:, l]

    nlf = rf + "/dnloan.csv"
    dnl = pd.read_csv(nlf)
    dnl = rescale_stre3am(dnl, infof, "cash")

    for l in range(1, dnl.shape[1]):
        a.bar(xvals, height=dnl.iloc[:, l],
              width=w, bottom=base.iloc[:, 0],
              align="edge", edgecolor="w", lw=0.08, color="#CF5404")
        base.iloc[:, 0] += dnl.iloc[:, l]


    rtf = rf + "/tret.csv"
    drt = pd.read_csv(rtf)
    drt = rescale_stre3am(drt, infof, "cash")


    for l in range(1, drt.shape[1]):
        a.bar(xvals, height=-drt.iloc[:, l], width=w,
              align="edge", edgecolor="w", lw=0., color="red")
    xdum = np.linspace(y0, yend, num=p_scale)
    a.plot(xdum, np.zeros(len(xdum)), "--", lw=0.05, color="k",)

    dummy_v = np.ones(len(x))*1e-01
    a.bar(x, height=dummy_v, width=w, align="edge",
          color="#0067A8", label="RetroF")
    a.bar(x, height=dummy_v, width=w, align="edge",
          color="#009368", label="Exp")
    a.bar(x, height=dummy_v, width=w, align="edge",
          color="#CF5404", label="New")
    a.bar(x, height=dummy_v, width=w, align="edge",
          color="red", label="Retire")

    ymax = base.max().max()
    a.set_title("Capital")
    a.set_xlabel("Year")
    a.set_ylabel("USD/yr")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(x)

    f.savefig(folder + "loans.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_loan.png")


# 80############################################################################
def plot_ep1(rf, folder, colors, labr, labn, xaxislabel=None):
    rep1f = rf + "/drep1.csv"
    nep1f = rf + "/dnep1.csv"
    demf = rf + "/demand.csv"
    infof = rf + "/s_info.csv"

    drep1 = pd.read_csv(rep1f)
    drep1 = rescale_stre3am(drep1, infof, "em")
    dnep1 = pd.read_csv(nep1f)
    dnep1 = rescale_stre3am(dnep1, infof, "em")

    if xaxislabel == "year":
        xvals = drep1.iloc[:,0]
        w = (drep1.iloc[1, 0] - drep1.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(drep1.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    b = np.zeros(drep1.shape[0])
    for i in range(1, drep1.shape[1]):
        a.bar(xvals, drep1.iloc[:, i],
              width=w, bottom=b, label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1])
        b += drep1.iloc[:, i]

    for i in range(1, dnep1.shape[1]):
        a.bar(xvals, dnep1.iloc[:, i],
              width=w, bottom=b, label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1],
              hatch="//")
        b += dnep1.iloc[:, i]

    ymax = b.max()

    a.set_title("(b) (STREAM) Scope 1 Cement Emission (em.)")
    a.set_xlabel("Year")
    a.set_ylabel("tonneCO2/yr")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "ep1ge.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_ep1.png")


# 80############################################################################
def plot_elec_by_tech(rf, folder, colors, labr, labn, xaxislabel=None):
    ruf = rf + "/dru.csv"
    nuf = rf + "/dnu.csv"
    infof = rf + "/s_info.csv"

    dru = pd.read_csv(ruf)
    dru = rescale_stre3am(dru, infof, "elec")
    dnu = pd.read_csv(nuf)
    dnu = rescale_stre3am(dnu, infof, "elec")

    if xaxislabel == "year":
        xvals = dru.iloc[:, 0]
        w = (dru.iloc[1, 0] - dru.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dru.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))


    b = np.zeros(dru.shape[0])
    for i in range(1, dru.shape[1]):
        a.bar(xvals, dru.iloc[:, i],
              width=w, bottom=b, label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1])
        b += dru.iloc[:, i]

    for i in range(1, dnu.shape[1]):
        a.bar(xvals, dnu.iloc[:, i],
              width=w, bottom=b, label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors[i-1],
              hatch="//")
        b += dnu.iloc[:, i]


    ymax = b.max()

    a.set_title("(c) (STREAM) Cement Electricity consumption")
    a.set_xlabel("Year")
    a.set_ylabel("MMBTU/yr")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "u_by_rf.png", dpi=300, format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_elec_rf.png")


# 80############################################################################
def plot_cumulative_expansion(rf, folder, colors, xaxislabel=None):
    ef = rf + "/dec_act.csv"
    infof = rf + "/s_info.csv"

    de = pd.read_csv(ef)
    de = rescale_stre3am(de, infof, "cap")

    b = pd.Series(np.zeros(de.shape[0]))

    if xaxislabel == "year":
        xvals = de.iloc[:, 0]
        w = (de.iloc[1, 0] - de.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(de.shape[0])
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    for col in range(1, de.shape[1]):
        a.bar(xvals, de.iloc[:, col],
              align="edge", edgecolor="w", lw=1.5,
              color=colors[1], width=w, bottom=b)
        b += de.iloc[:, col]

    a.set_title("Active expansion capacity")
    a.set_xlabel("Year")
    a.set_ylabel("tonne/yr")

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "ec.png", format="png")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_ec.png")


# 80############################################################################
def export_legend(legend, filename="legend.png"):
    """Put the legend in a png different file.
    """
    #: be sure to have  --> bbox_to_anchor=(1.0, 0.0)
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent().transformed(
        fig.dpi_scale_trans.inverted()
    )
    fig.savefig(filename, dpi=300, bbox_inches=bbox, format="png")


# 80############################################################################
def plot_bar_by_loc(rf, folder, colors, labr, labn, xaxislabel=None):
    cprf = rf + "/drcp_d_act.csv"
    cpnf = rf + "/dncp_d.csv"
    demf = rf + "/demand.csv"
    infof = rf + "/s_info.csv"

    dfr = pd.read_csv(cprf)
    dfr = rescale_stre3am(dfr, infof, "cap")
    dfn = pd.read_csv(cpnf)
    dfn = rescale_stre3am(dfn, infof, "cap")
    dfd = pd.read_csv(demf)
    dfd = rescale_stre3am(dfd, infof, "cap")

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = dfr.iloc[:, 0]
        w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dfr.shape[0])
        w = 0.8
    #w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8

    b = pd.Series(np.zeros(dfr.shape[0]))

    # column by column
    for i in range(1, dfr.shape[1]):
        y = dfr.iloc[:, i]
        name = y.name.split("_")
        cidx = int(name[1])
        a.bar(xvals, dfr.iloc[:, i],
              width=w, bottom=b, lw=0.5, color=colors[cidx-1],
              align="edge", edgecolor="w")
        b += dfr.iloc[:, i]
        # if dfr.iloc[:, i].sum() > 1:
        #     b += 1.0
    for i in range(1, dfn.shape[1]):
        y = dfn.iloc[:, i]
        name = y.name.split("_")
        cidx = int(name[1])
        a.bar(xvals, dfn.iloc[:, i],
              width=w, bottom=b, lw=0.5, color=colors[cidx-1],
              align="edge", edgecolor="w", hatch="//")
        b += dfn.iloc[:, i]


    ymax = b.max().max()
    a.plot(xvals, dfd.iloc[:, 0],
           label="Demand", lw=2, color="darkred", ls="--", marker="*")

    a.set_title("(a) (STREAM) Cement Production/Demand")
    a.set_xlabel("Year")
    a.set_ylabel("tonne/yr")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "demand-loc.png", dpi=300, format="png")
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_demand-loc.png")


# 80############################################################################
def plot_pie_by_loc(rf, folder, colors, labr, labn, xaxislabel=None):
    cprf = rf + "/drcp_d_act.csv"
    cpnf = rf + "/dncp_d.csv"

    infof = rf + "/s_info.csv"
    dinfo = pd.read_csv(infof)

    if dinfo.loc[0, "n_rtft"] != dinfo.loc[0, "n_new"]:
        raise("The number of techs mismatch")


    dfr = pd.read_csv(cprf)
    dfr = rescale_stre3am(dfr, infof, "cap")
    dfn = pd.read_csv(cpnf)
    dfn = rescale_stre3am(dfn, infof, "cap")
    #
    n_loc = dinfo.loc[0, "n_loc"]
    n_tech = dinfo.loc[0, "n_rtft"]
    n_tp = dfr.shape[0]
    #
    cap = np.zeros([n_loc, n_tech, n_tp])
    #
    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = dfr.iloc[:, 0]
        w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dfr.shape[0])
        w = 0.8

    #w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8

    b = pd.Series(np.zeros(dfr.shape[0]))
    # navigate by col
    for col in range(1, dfr.shape[1]):
        y = dfr.iloc[:, col]
        name = y.name.split("_")
        k = int(name[1])-1
        l = int(name[3])-1
        for row in range(y.shape[0]):
            cap[l, k, row] += y.iloc[row]
    for col in range(1, dfn.shape[1]):
        y = dfn.iloc[:, col]
        name = y.name.split("_")
        k = int(name[1])-1
        l = int(name[3])-1
        for row in range(y.shape[0]):
            cap[l, k, row] += y.iloc[row]

    f, axs = plt.subplots(ncols=n_tp, nrows=n_loc)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
    for col in range(n_tp):
        for row in range(n_loc):
            ax = axs[row, col]
            if sum(cap[row, :, col]) <= 1e-8:
                if sum(cap[row, :, col]) < 0.0:
                    print("cap {row}, {col} is less than 0")
                ax.pie([1], colors=["r"])
            else:
                l = []
                for cp_i in cap[row, :, col]:
                    if abs(cp_i) < 1e-8:
                        cp_i = 0
                    l.append(cp_i)
                ax.pie(l, colors=colors)

            #ax.set_title(f"loc={row}, period={col}", fontsize="small")
    f.savefig(folder + "pie_chart.png", dpi=300, format="png")


# 80############################################################################
def plot_em_bar_v2(rf, folder, colors, labr, labn, xaxislabel=None):
    # retrofits
    rcpe = rf + "/drcpe.csv"
    rfue = rf + "/drfue.csv"
    rep1 = rf + "/drep1_.csv"
    ruem = rf + "/druem.csv"
    infof = rf + "/s_info.csv"
    drcpe = pd.read_csv(rcpe)
    drcpe = rescale_stre3am(drcpe, infof, "em")
    drfue = pd.read_csv(rfue)
    drfue = rescale_stre3am(drfue, infof, "em")
    drep1 = pd.read_csv(rep1)
    drep1 = rescale_stre3am(drep1, infof, "em")
    druem = pd.read_csv(ruem)
    druem = rescale_stre3am(druem, infof, "em")
    # new plants
    ncpe = rf + "/dncpe.csv"
    nfue = rf + "/dnfue.csv"
    nep1 = rf + "/dnep1_.csv"
    nuem = rf + "/dnuem.csv"
    dncpe = pd.read_csv(ncpe)
    dncpe = rescale_stre3am(dncpe, infof, "em")
    dnfue = pd.read_csv(nfue)
    dnfue = rescale_stre3am(dnfue, infof, "em")
    dnep1 = pd.read_csv(nep1)
    dnep1 = rescale_stre3am(dnep1, infof, "em")
    dnuem = pd.read_csv(nuem)
    dnuem = rescale_stre3am(dnuem, infof, "em")
    # co2 budget
    fco2b = rf + "/co2.csv"
    dco2b = pd.read_csv(fco2b)
    dco2b = rescale_stre3am(dco2b, infof, "em")

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = drcpe.iloc[:,0]
        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(drcpe.shape[0])
        w = 0.8

    b = pd.Series(np.zeros(dncpe.shape[0]))

    last = drcpe.shape[1]
    for i in range(1, drcpe.shape[1]):
        if i == last - 1:
            label = "retro.Proc.CO2"
        else:
            label = ""
        a.bar(xvals, drcpe.iloc[:, i],
              width=w, bottom=b, lw=0.0, color="#dd0436",
              align="edge", edgecolor="w", label=label, alpha=0.5)
        b += drcpe.iloc[:, i]

    last = drfue.shape[1]
    for i in range(1, drfue.shape[1]):
        if i == last - 1:
            label = "retro.Fuel.CO2"
        else:
            label = ""
        a.bar(xvals, drfue.iloc[:, i],
              width=w, bottom=b, lw=0.0, color="#b8002a",
              align="edge", edgecolor="w", label=label, alpha=0.5)
        b += drfue.iloc[:, i]

    ##
    last = dncpe.shape[1]
    for i in range(1, dncpe.shape[1]):
        if i == last - 1:
            label = "new.Proc.CO2"
        else:
            label = ""
        #
        a.bar(xvals, dncpe.iloc[:, i],
              width=w, bottom=b, lw=0.0, color="#dd0436",
              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.5)
        b += dncpe.iloc[:, i]

    last = dnfue.shape[1]
    for i in range(1, dnfue.shape[1]):
        if i == last - 1:
            label = "new.Fuel.CO2"
        else:
            label = ""
        a.bar(xvals, dnfue.iloc[:, i],
              width=w, bottom=b, lw=0.0, color="#b8002a",
              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.5)
        b += dnfue.iloc[:, i]

    # last = druem.shape[1]
    # for i in range(1, druem.shape[1]):
    #     if i == last - 1:
    #         label = "retro.eGrid.CO2"
    #     else:
    #         label = ""
    #     a.bar(druem.iloc[:, 0], druem.iloc[:, i],
    #           width=w, bottom=b, lw=0.0, color="#ffba00",
    #           align="edge", edgecolor="w", label=label)
    #     b += druem.iloc[:, i]

    # last = dnuem.shape[1]
    # for i in range(1, dnuem.shape[1]):
    #     if i == last - 1:
    #         label = "new.eGrid.CO2"
    #     else:
    #         label = ""
    #     a.bar(dnuem.iloc[:, 0], dnuem.iloc[:, i],
    #           width=w, bottom=b, lw=0.0, color="#ffba00",
    #           align="edge", edgecolor="w", hatch="//", label=label)
    #     b += dnuem.iloc[:, i]

    b2 = pd.Series(np.zeros(dncpe.shape[0]))

    if xaxislabel == "year":
        xvals = drcpe.iloc[:, 0]
        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.7
    else:
        xvals = np.arange(drcpe.shape[0])
        w = 0.7

    last = drep1.shape[1]
    for i in range(1, drep1.shape[1]):
        if i == last - 1:
            label = "retro.PostCap.Proc.CO2"
        else:
            label = ""
        a.bar(xvals, drep1.iloc[:, i],
              width=w, bottom=b2, lw=0.0, color="#ff8e00",
              align="edge", edgecolor="k", label=label)
        b2 += drep1.iloc[:, i]

    #
    for i in range(1, dnep1.shape[1]):
        if i == last - 1:
            label = "new.PostCap.Proc.CO2"
        else:
            label = ""
        a.bar(xvals, dnep1.iloc[:, i],
              width=w, bottom=b2, lw=0.0, color="#ff8e00",
              align="edge", edgecolor="k", hatch="//",
              label=label)
        b2 += dnep1.iloc[:, i]

    last = druem.shape[1]

    #for i in range(1, druem.shape[1]):
    #    if i == last - 1:
    #        label = "retro.eGrid.CO2"
    #    else:
    #        label = ""
    #    a.bar(xvals, druem.iloc[:, i],
    #          width=w, bottom=b2, lw=0.0, color="#ffba00",
    #          align="edge", edgecolor="k", label=label)
    #    b2 += druem.iloc[:, i]

    #last = dnuem.shape[1]
    #for i in range(1, dnuem.shape[1]):
    #    if i == last - 1:
    #        label = "new.eGrid.CO2"
    #    else:
    #        label = ""
    #    a.bar(xvals, dnuem.iloc[:, i],
    #          width=w, bottom=b2, lw=0.0, color="#ffba00",
    #          align="edge", edgecolor="k", hatch="//")
    #    b2 += dnuem.iloc[:, i]

    # a.plot(xvals, dco2b.iloc[:], label="CO2-Constraint",
    #       lw=2, color="dimgray", ls="--", marker="*")

    ymax = b.max().max()
    a.set_title("Pre/Post capture CO2 Emissions")
    a.set_xlabel("Year")
    a.set_ylabel("tonneCO2/yr")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "co2_act.png", dpi=300, format="png")
    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_co2.png")



def plot_co2_cap_bar(rf, folder, colors, labr, labn, xaxislabel=None):
    # retrofits
    rcpe = rf + "/drcpe.csv"
    rfue = rf + "/drfue.csv"
    rep1 = rf + "/drep1_.csv"
    infof = rf + "/s_info.csv"

    drcpe = pd.read_csv(rcpe)
    drcpe = rescale_stre3am(drcpe, infof, "em")
    drfue = pd.read_csv(rfue)
    drfue = rescale_stre3am(drfue, infof, "em")
    drep1 = pd.read_csv(rep1)
    drep1 = rescale_stre3am(drep1, infof, "em")
    # new plants
    ncpe = rf + "/dncpe.csv"
    nfue = rf + "/dnfue.csv"
    nep1 = rf + "/dnep1_.csv"
    dncpe = pd.read_csv(ncpe)
    dncpe = rescale_stre3am(dncpe, infof, "em")
    dnfue = pd.read_csv(nfue)
    dnfue = rescale_stre3am(dnfue, infof, "em")
    dnep1 = pd.read_csv(nep1)
    dnep1 = rescale_stre3am(dnep1, infof, "em")

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = drcpe.iloc[:,0]
        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(drcpe.shape[0])
        w = 0.8


    dcap_r = drcpe + drfue - drep1

    b = pd.Series(np.zeros(dcap_r.shape[0]))

    last = dcap_r.shape[1]
    for i in range(1, dcap_r.shape[1]):
        if i == last - 1:
            label = "Existing process captured CO2"
        else:
            label = ""
        a.bar(xvals, dcap_r.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#dd0436",
              align="edge", edgecolor="w", label=label, alpha=0.8)
        b += dcap_r.iloc[:, i]


    dcap_n = dncpe + dnfue - dnep1
    ##
    last = dcap_n.shape[1]
    for i in range(1, dcap_n.shape[1]):
        if i == last - 1:
            label = "New process captured CO2"
        else:
            label = ""
        #
        a.bar(xvals, dcap_n.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#dd0436",
              align="edge", edgecolor="k", hatch="//", label=label, alpha=0.8)
        b += dcap_n.iloc[:, i]


    ymax = b.max().max()
    a.set_title("(b) Captured CO2")
    a.set_xlabel("Year")
    a.set_ylabel("tonneCO2/yr")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "co2_ccap.png", dpi=300, format="png")
    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_ccap.png")

def rescale_stre3am(df, info_csv, kind):
    dinfo = pd.read_csv(info_csv)
    col = ""
    if kind == "em":
        col = "sf_em"
    elif kind == "cap":
        col = "sf_cap"
    elif kind == "cash":
        col = "sf_cash"
    elif kind == "heat":
        col = "sf_heat"
    elif kind == "elec":
        col = "sf_elec"

    sf_ = dinfo.loc[0, col]
    df = df.apply(lambda x: x/sf_ if x.name != 'yr' else x, axis=0)
    return df

# 80############################################################################
def plot_legend(rf, folder, colors, labr, labn):
    f, a = plt.subplots(dpi=300)
    for i in range(len(labr)):
        a.bar([0], [0],
              label=labr[i],
              edgecolor="k", lw=1.5, color=colors[i])

    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "rtrf_labl.png")

    f, a = plt.subplots(dpi=300)
    for i in range(len(labn)):
        a.bar([0], [0],
              label=labn[i],
              edgecolor="k", lw=1.5, color=colors[i],
              hatch="//")


    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "new_labl.png")

    f, a = plt.subplots(dpi=300)
    a.plot([0], [0],
           label="Demand", lw=2, color="blue", ls="--", marker="*")

    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "dem_labl.png")


def plot_capf(rf, folder, colors, labr, labn, xaxislabel=None):
    cprf = rf + "/dracf.csv"
    dcf = pd.read_csv(cprf)

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = dcf.iloc[:, 0]
        w = (dcf.iloc[1, 0] - dcf.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dcf.shape[0])
        w = 0.8

    for i in range(1, dcf.shape[1]):
        name = dcf.columns[i]
        node = name.split("_")[1]
        if node == "3":
            a.step(xvals, dcf.iloc[:, i], ls="--", lw=0.5, marker=".", label=f"plnt={i}")

    a.set_title("(STREAM) Cap Fact Node=3 (Existing)")
    a.set_xlabel("Year")

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "r_capf.png", dpi=300, format="png")
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_r_capf.png")


    cpnf = rf + "/dnacf.csv"
    dcf = pd.read_csv(cpnf)
    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = dcf.iloc[:, 0]
        w = (dcf.iloc[1, 0] - dcf.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(dcf.shape[0])
        w = 0.8

    for i in range(1, dcf.shape[1]):
        name = dcf.columns[i]
        node = name.split("_")[1]
        if node == "3":
            a.step(xvals, dcf.iloc[:, i], ls="--", lw=0.5, marker=".", label=f"plnt={i}")

    a.set_title("(STREAM) Cap Fact Node=3 (New)")
    a.set_xlabel("Year")

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + "n_capf.png", dpi=300, format="png")
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, filename=folder + "legend_n_capf.png")



if __name__ == "__main__":
    main()
