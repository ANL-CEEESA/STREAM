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
def all_bars(rf, fmt):
    pltrcparams()
    #reference folder
    #rf = arg

    y0 = 2020
    yend = 2026
    p_scale = 6

    #fmt = "eps"

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


    colors_r = [
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
    rlf = rf + "/retro_labels.csv"
    nlf = rf + "/new_labels.csv"

    drl = pd.read_csv(rlf)
    labr = drl.iloc[:,0].to_list()
    dnl = pd.read_csv(nlf)
    labn = dnl.iloc[:,0].to_list()

    x_label = "Subperiod"

    plot_legend(rf, folder, colors_r, colors_n, labr, labn, fmt)

    plot_capacities(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=x_label)
    plot_cumulative_expansion(rf, folder, fmt, xaxislabel=x_label)
    plot_ep1(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=x_label)
    plot_elec_by_tech(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=x_label)
    plot_emisions(rf, folder, fmt, xaxislabel=x_label)
    plot_bar_by_loc(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=x_label)
    plot_co2_cap_bar(rf, folder, fmt, xaxislabel=x_label)
    plot_capture_relased_em(rf, folder, fmt, xaxislabel=x_label)
    plot_en_bar(rf, folder, fmt, xaxislabel=x_label)

    return folder

# 80############################################################################
def plot_emisions(rf, folder, fmt, xaxislabel=None):
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
        xvals = np.arange(1, df.shape[0]+1)
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
    a.set_title("Inc/Ret/New Emissions")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("$MT CO_{2} yr^{-1}$")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + f"inc_ret_new_em.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + "inc_ret_new_em_leg", fmt)
    plt.close(f)


# 80############################################################################
def plot_capture_relased_em(rf, folder, fmt, xaxislabel=None):
    # retrofits
    rcpe = rf + "/drcpe.csv"
    rfue = rf + "/drfue.csv"
    rep1 = rf + "/drep1_.csv"
    rups = rf + "/do_ups_e_mt_in.csv"
    infof = rf + "/s_info.csv"

    drcpe = pd.read_csv(rcpe)
    drcpe = rescale_stre3am(drcpe, infof, "em")
    drfue = pd.read_csv(rfue)
    drfue = rescale_stre3am(drfue, infof, "em")
    drep1 = pd.read_csv(rep1)
    drep1 = rescale_stre3am(drep1, infof, "em")
    drups = pd.read_csv(rups)
    drups = rescale_stre3am(drups, infof, "em")

    # new plants
    ncpe = rf + "/dncpe.csv"
    nfue = rf + "/dnfue.csv"
    nep1 = rf + "/dnep1_.csv"
    nups = rf + "/dn_ups_e_mt_in.csv"

    dncpe = pd.read_csv(ncpe)
    dncpe = rescale_stre3am(dncpe, infof, "em")
    dnfue = pd.read_csv(nfue)
    dnfue = rescale_stre3am(dnfue, infof, "em")
    dnep1 = pd.read_csv(nep1)
    dnep1 = rescale_stre3am(dnep1, infof, "em")
    dnups = pd.read_csv(nups)
    dnups = rescale_stre3am(dnups, infof, "em")

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    if xaxislabel == "year":
        xvals = drcpe.iloc[:,0]
        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(1, drcpe.shape[0] + 1)
        w = 0.8

    # captured
    dcap_r = drcpe + drfue - drep1
    dcap_n = dncpe + dnfue - dnep1

    b = pd.Series(np.zeros(dcap_r.shape[0]))

    last = dcap_r.shape[1]
    for i in range(1, dcap_r.shape[1]):
        if i == last - 1:
            label = "Existing captured emission"
        else:
            label = ""
        a.bar(xvals, -dcap_r.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#cd5c5c",
              align="edge", edgecolor="w", label=label, alpha=0.8)
        b -= dcap_r.iloc[:, i]

    ##
    last = dcap_n.shape[1]
    for i in range(1, dcap_n.shape[1]):
        if i == last - 1:
            label = "New captured emission"
        else:
            label = ""
        a.bar(xvals, -dcap_n.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#cd5c5c",
              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.8)
        b -= dcap_n.iloc[:, i]

    ymin = b.min().min()

    # emitted
    b = pd.Series(np.zeros(drep1.shape[0]))
    last = drep1.shape[1]
    for i in range(1, drep1.shape[1]):
        if i == last - 1:
            label = "Existing relased emission"
        else:
            label = ""
        a.bar(xvals, drep1.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#5ccdcd",
              align="edge", edgecolor="w", label=label, alpha=0.8)
        b += drep1.iloc[:, i]

    last = dnep1.shape[1]
    for i in range(1, dnep1.shape[1]):
        if i == last - 1:
            label = "New released emission"
        else:
            label = ""
        a.bar(xvals, dnep1.iloc[:, i],
              width=w, bottom=b, lw=0.5, color="#5ccdcd",
              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.8)
        b += dnep1.iloc[:, i]

    ymax = b.max().max()
    a.set_title("Emissions")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"

    a.set_xlabel(xlabel)

    a.set_ylabel("$MT CO_{2} yr^{-1}$")
    a.set_ylim(bottom=ymin*1.01, top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    a.hlines(0, xvals.min(), xvals.max()+w)
    figname = "co2_emit_cap"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")
    plt.close(f)
    # generate the legend
    f, a = plt.subplots(dpi=300)
    a.bar([0], [0], label="Existing captured CO2", color="#cd5c5c",
          edgecolor="w", lw=0.5, alpha=0.8)
    a.bar([0], [0], label="New captured CO2", color="#cd5c5c",
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")
    a.bar([0], [0], label="Existing emitted CO2", color="#5ccdcd",
          edgecolor="w", lw=0.5, alpha=0.8)
    a.bar([0], [0], label="New emitted CO2", color="#5ccdcd",
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")

    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)
    plt.close(f)

# 80############################################################################
def plot_capacities(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=None):
    cprf = rf + "/drcp.csv"
    cpnf = rf + "/dncp.csv"

    # base capacity
    rcpbf = rf + "/drcpb.csv"
    nc0nf = rf + "/dnc0.csv"

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
        xvals = np.arange(1, dfr.shape[0]+1)
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    b = pd.DataFrame([0.0 for i in range(dfr.shape[0])])
    for i in range(1, dfr.shape[1]):
        a.bar(xvals, dfr.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_r[i-1])
        b.iloc[:, 0] += dfr.iloc[:, i]

    for i in range(1, dfn.shape[1]):
        a.bar(xvals, dfn.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_n[i-1],
              hatch="//")
        b.iloc[:, 0] += dfn.iloc[:, i]

    ymax = b.max().max()
    a.plot(xvals, dfd.iloc[:, 0],
           label="Demand", lw=2, color="blue", ls="--", marker="*")

    a.set_title("Capacity(Active) and Demand")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MT $yr^{-1}$")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + f"demand-active_c.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    #export_legend(legend_object, folder + "legend_cap-active", fmt)

    # installed capacity plot!
    dfr0 = pd.read_csv(rcpbf)
    dfr0 = rescale_stre3am(dfr0, infof, "cap")

    dfn0 = pd.read_csv(nc0nf)
    dfn0 = rescale_stre3am(dfn0, infof, "cap")

    if xaxislabel == "year":
        xvals = dfr0.iloc[:, 0]
        w = (dfr0.iloc[1, 0] - dfr0.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(1, dfr0.shape[0]+1)
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    b = pd.DataFrame([0.0 for i in range(dfr0.shape[0])])
    for i in range(1, dfr0.shape[1]):
        a.bar(xvals, dfr0.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_r[i-1])
        b.iloc[:, 0] += dfr0.iloc[:, i]
    # This neees to start at 2!!
    for i in range(2, dfn0.shape[1]):
        a.bar(xvals, dfn0.iloc[:, i],
              width=w, bottom=b.iloc[:, 0], label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_n[i-1],
              hatch="//")
        b.iloc[:, 0] += dfn0.iloc[:, i]

    ymax = b.max().max()
    a.plot(xvals, dfd.iloc[:, 0],
           label="Demand", lw=2, color="blue", ls="--", marker="*")

    a.set_title("Capacity(Installed) and Demand")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MT $yr^{-1}$")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "demand-installed"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)
    plt.close(f)


# 80############################################################################
# not used anymore :(
# def plot_electricity(rf, folder, colors, labr, labni, fmt, xaxislabel=None):
#     uf = rf +"/u.csv"
#     infof = rf + "/s_info.csv"
#
#     df = pd.read_csv(uf)
#     df = rescale_stre3am(df, infof, "elec")
#
#     if xaxislabel == "year":
#         xvals = df.iloc[:,0]
#         w = (df.iloc[1, 0] - df.iloc[0, 0]) * 0.8
#     else:
#         xvals = np.arange(1, df.shape[0]+1)
#         w = 0.8
#
#     f, a = plt.subplots(dpi=300)
#     plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#     a.bar(xvals, df.iloc[:,0], width=w, label="Exist+RF", edgecolor="k",
#           align="edge", lw=1.5)
#
#     b = df.iloc[:, 0]
#
#     a.bar(xvals, df.iloc[:,1], width=w, label="New Plant", bottom=b,
#           edgecolor="k", align="edge", lw=1.5)
#
#
#     a.set_title("Electricity")
#
#     xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
#     a.set_xlabel(xlabel)
#
#     a.set_ylabel("MMBTU yr^{-1}")
#     # tick labels
#     a.xaxis.set_major_formatter("{x:.0f}")
#     a.set_xticks(xvals)
#
#     f.savefig(folder + f"u.{fmt}", dpi=300, format=f"{fmt}")
#
#     # save the legend
#     a.legend(bbox_to_anchor=(1.0, 1.0))
#     legend_object = a.get_legend()
#     export_legend(legend_object, folder + "legend", fmt)


# 80############################################################################
#def plot_loans(rf, folder, colors, labr, labn, fmt, xaxislabel=None):
#
#    rlf = rf + "/drloan.csv"
#    drl = pd.read_csv(rlf)
#
#    infof = rf + "/s_info.csv"
#    drl = rescale_stre3am(drl, infof, "cash")
#
#
#    base = pd.DataFrame([0.0 for i in range(drl.shape[0])])
#
#    if xaxislabel == "year":
#        xvals = drl.iloc[:,0]
#        w = (drl.iloc[1, 0] - drl.iloc[0, 0]) * 0.8
#    else:
#        xvals = np.arange(1, drl.shape[0]+1)
#        w = 0.8
#
#    f, a = plt.subplots(dpi=300)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#    for l in range(1, drl.shape[1]):
#        a.bar(xvals, height=drl.iloc[:, l],
#              width=w, bottom=base.iloc[:, 0], align="edge", edgecolor="w",
#              lw=0.01, color="#0067A8")
#        base.iloc[:, 0] += drl.iloc[:, l]
#
#    elf = rf + "/deloan.csv"
#    d_el = pd.read_csv(elf)
#    d_el = rescale_stre3am(d_el, infof, "cash")
#
#    for l in range(1, d_el.shape[1]):
#        a.bar(xvals, height=d_el.iloc[:, l],
#              width=w, bottom=base.iloc[:, 0], align="edge", edgecolor="w",
#              lw=0.01, color="#009368")
#        base.iloc[:, 0] += d_el.iloc[:, l]
#
#    nlf = rf + "/dnloan.csv"
#    dnl = pd.read_csv(nlf)
#    dnl = rescale_stre3am(dnl, infof, "cash")
#
#    for l in range(1, dnl.shape[1]):
#        a.bar(xvals, height=dnl.iloc[:, l],
#              width=w, bottom=base.iloc[:, 0],
#              align="edge", edgecolor="w", lw=0.08, color="#CF5404")
#        base.iloc[:, 0] += dnl.iloc[:, l]
#
#
#    rtf = rf + "/tret.csv"
#    drt = pd.read_csv(rtf)
#    drt = rescale_stre3am(drt, infof, "cash")
#
#
#    for l in range(1, drt.shape[1]):
#        a.bar(xvals, height=-drt.iloc[:, l], width=w,
#              align="edge", edgecolor="w", lw=0., color="red")
#    xdum = np.linspace(y0, yend, num=p_scale)
#    a.plot(xdum, np.zeros(len(xdum)), "--", lw=0.05, color="k",)
#
#    dummy_v = np.ones(len(x))*1e-01
#    a.bar(x, height=dummy_v, width=w, align="edge",
#          color="#0067A8", label="RetroF")
#    a.bar(x, height=dummy_v, width=w, align="edge",
#          color="#009368", label="Exp")
#    a.bar(x, height=dummy_v, width=w, align="edge",
#          color="#CF5404", label="New")
#    a.bar(x, height=dummy_v, width=w, align="edge",
#          color="red", label="Retire")
#
#    ymax = base.max().max()
#    a.set_title("Capital")
#
#
#    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
#    a.set_xlabel(xlabel)
#
#    a.set_ylabel("USD yr^{-1}")
#    a.set_ylim(top=ymax*1.01)
#    # tick labels
#    a.xaxis.set_major_formatter("{x:.0f}")
#    a.set_xticks(x)
#
#    f.savefig(folder + f"loans.{fmt}", dpi=300, format=f"{fmt}")
#
#    # save the legend
#    a.legend(bbox_to_anchor=(1.0, 1.0))
#    legend_object = a.get_legend()
#    export_legend(legend_object, folder + "legend_loan", fmt)


# 80############################################################################
def plot_ep1(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=None):
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
        xvals = np.arange(1, drep1.shape[0]+1)
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    b = np.zeros(drep1.shape[0])
    for i in range(1, drep1.shape[1]):
        a.bar(xvals, drep1.iloc[:, i],
              width=w, bottom=b, label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_r[i-1])
        b += drep1.iloc[:, i]

    for i in range(1, dnep1.shape[1]):
        a.bar(xvals, dnep1.iloc[:, i],
              width=w, bottom=b, label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_n[i-1],
              hatch="//")
        b += dnep1.iloc[:, i]

    ymax = b.max()

    a.set_title("Emission")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("$MT CO_{2} yr^{-1}$")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "ep1ge"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)
    plt.close(f)


# 80############################################################################
def plot_elec_by_tech(rf, folder, colors_r, colors_n, labr, labn, fmt, xaxislabel=None):
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
        xvals = np.arange(1, dru.shape[0]+1)
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))


    b = np.zeros(dru.shape[0])
    for i in range(1, dru.shape[1]):
        a.bar(xvals, dru.iloc[:, i],
              width=w, bottom=b, label=labr[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_r[i-1])
        b += dru.iloc[:, i]

    for i in range(1, dnu.shape[1]):
        a.bar(xvals, dnu.iloc[:, i],
              width=w, bottom=b, label=labn[i-1],
              align="edge", edgecolor="k", lw=1.5, color=colors_n[i-1],
              hatch="//")
        b += dnu.iloc[:, i]


    ymax = b.max()

    a.set_title("Electricity consumption")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MMBTU $yr^{-1}$")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)

    f.savefig(folder + f"u_by_rf.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + "legend_elec_rf", fmt)
    plt.close(f)


# 80############################################################################
def plot_cumulative_expansion(rf, folder, fmt, xaxislabel=None):
    ef = rf + "/dec_act.csv"
    infof = rf + "/s_info.csv"

    de = pd.read_csv(ef)
    de = rescale_stre3am(de, infof, "cap")

    b = pd.Series(np.zeros(de.shape[0]))

    if xaxislabel == "year":
        xvals = de.iloc[:, 0]
        w = (de.iloc[1, 0] - de.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(1, de.shape[0]+1)
        w = 0.8

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    for col in range(1, de.shape[1]):
        a.bar(xvals, de.iloc[:, col],
              align="edge", edgecolor="w", lw=0.5,
              color="#CC6633", width=w, bottom=b)
        b += de.iloc[:, col]

    a.set_title("Installed expansion capacity")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MT $yr^{-1}$")

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "expansion_cap"
    f.savefig(folder + f"{figname}.{fmt}", format=f"{fmt}")

    # save the legend
    # a.legend(bbox_to_anchor=(1.0, 1.0))
    # legend_object = a.get_legend()
    # export_legend(legend_object, folder + "legend_ec", fmt)

    plt.close(f)

# 80############################################################################
def export_legend(legend, filename, fmt):
    """Put the legend in a {fmt} different file.
    """
    #: be sure to have  --> bbox_to_anchor=(1.0, 0.0)
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent().transformed(
        fig.dpi_scale_trans.inverted())
    fig.savefig(filename + f".{fmt}", dpi=300,
                bbox_inches=bbox, format=f"{fmt}")


# 80############################################################################
def plot_bar_by_loc(rf, folder, colors_r, colors_n, labr, labn, fmt,
                    xaxislabel=None):
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
        xvals = np.arange(1, dfr.shape[0]+1)
        w = 0.8
    #w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8

    b = pd.Series(np.zeros(dfr.shape[0]))

    # column by column
    for i in range(1, dfr.shape[1]):
        y = dfr.iloc[:, i]
        name = y.name.split("_")
        cidx = int(name[1])
        a.bar(xvals, dfr.iloc[:, i],
              width=w, bottom=b, lw=0.5, color=colors_r[cidx-1],
              align="edge", edgecolor="w")
        b += dfr.iloc[:, i]
        # if dfr.iloc[:, i].sum() > 1:
        #     b += 1.0
    for i in range(1, dfn.shape[1]):
        y = dfn.iloc[:, i]
        name = y.name.split("_")
        cidx = int(name[1])
        a.bar(xvals, dfn.iloc[:, i],
              width=w, bottom=b, lw=0.5, color=colors_n[cidx-1],
              align="edge", edgecolor="w", hatch="//")
        b += dfn.iloc[:, i]


    ymax = b.max().max()
    a.plot(xvals, dfd.iloc[:, 0],
           label="Demand", lw=2, color="darkred", ls="--", marker="*")

    a.set_title("Capacity and Demand")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MT $yr^{-1}$")
    a.set_ylim(top=ymax*1.01)

    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "demand-location"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)
    plt.close(f)


# 80############################################################################
#def plot_pie_by_loc(rf, folder, colors, labr, labn, fmt, xaxislabel=None):
#    cprf = rf + "/drcp_d_act.csv"
#    cpnf = rf + "/dncp_d.csv"
#
#    infof = rf + "/s_info.csv"
#    dinfo = pd.read_csv(infof)
#
#    if dinfo.loc[0, "n_rtft"] != dinfo.loc[0, "n_new"]:
#        raise("The number of techs mismatch")
#
#
#    dfr = pd.read_csv(cprf)
#    dfr = rescale_stre3am(dfr, infof, "cap")
#    dfn = pd.read_csv(cpnf)
#    dfn = rescale_stre3am(dfn, infof, "cap")
#    #
#    n_loc = dinfo.loc[0, "n_loc"]
#    n_tech = dinfo.loc[0, "n_rtft"]
#    n_tp = dfr.shape[0]
#    #
#    cap = np.zeros([n_loc, n_tech, n_tp])
#    #
#    f, a = plt.subplots(dpi=300)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#    if xaxislabel == "year":
#        xvals = dfr.iloc[:, 0]
#        w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8
#    else:
#        xvals = np.arange(1, dfr.shape[0]+1)
#        w = 0.8
#
#    #w = (dfr.iloc[1, 0] - dfr.iloc[0, 0]) * 0.8
#
#    b = pd.Series(np.zeros(dfr.shape[0]))
#    # navigate by col
#    for col in range(1, dfr.shape[1]):
#        y = dfr.iloc[:, col]
#        name = y.name.split("_")
#        k = int(name[1])-1
#        l = int(name[3])-1
#        for row in range(y.shape[0]):
#            cap[l, k, row] += y.iloc[row]
#    for col in range(1, dfn.shape[1]):
#        y = dfn.iloc[:, col]
#        name = y.name.split("_")
#        k = int(name[1])-1
#        l = int(name[3])-1
#        for row in range(y.shape[0]):
#            cap[l, k, row] += y.iloc[row]
#
#    f, axs = plt.subplots(ncols=n_tp, nrows=n_loc)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#    for col in range(n_tp):
#        for row in range(n_loc):
#            ax = axs[row, col]
#            if sum(cap[row, :, col]) <= 1e-8:
#                if sum(cap[row, :, col]) < 0.0:
#                    print("cap {row}, {col} is less than 0")
#                ax.pie([1], colors=["r"])
#            else:
#                l = []
#                for cp_i in cap[row, :, col]:
#                    if abs(cp_i) < 1e-8:
#                        cp_i = 0
#                    l.append(cp_i)
#                ax.pie(l, colors=colors)
#
#            #ax.set_title(f"loc={row}, period={col}", fontsize="small")
#    f.savefig(folder + f"pie_chart.{fmt}", dpi=300, format=f"{fmt}")


# 80############################################################################
#def plot_em_bar_v2(rf, folder, colors, labr, labn, fmt, xaxislabel=None):
#    # retrofits
#    rcpe = rf + "/drcpe.csv"
#    rfue = rf + "/drfue.csv"
#    rep1 = rf + "/drep1_.csv"
#    ruem = rf + "/druem.csv"
#    infof = rf + "/s_info.csv"
#    drcpe = pd.read_csv(rcpe)
#    drcpe = rescale_stre3am(drcpe, infof, "em")
#    drfue = pd.read_csv(rfue)
#    drfue = rescale_stre3am(drfue, infof, "em")
#    drep1 = pd.read_csv(rep1)
#    drep1 = rescale_stre3am(drep1, infof, "em")
#    druem = pd.read_csv(ruem)
#    druem = rescale_stre3am(druem, infof, "em")
#    # new plants
#    ncpe = rf + "/dncpe.csv"
#    nfue = rf + "/dnfue.csv"
#    nep1 = rf + "/dnep1_.csv"
#    nuem = rf + "/dnuem.csv"
#    dncpe = pd.read_csv(ncpe)
#    dncpe = rescale_stre3am(dncpe, infof, "em")
#    dnfue = pd.read_csv(nfue)
#    dnfue = rescale_stre3am(dnfue, infof, "em")
#    dnep1 = pd.read_csv(nep1)
#    dnep1 = rescale_stre3am(dnep1, infof, "em")
#    dnuem = pd.read_csv(nuem)
#    dnuem = rescale_stre3am(dnuem, infof, "em")
#    # co2 budget
#    fco2b = rf + "/co2.csv"
#    dco2b = pd.read_csv(fco2b)
#    dco2b = rescale_stre3am(dco2b, infof, "em")
#
#    f, a = plt.subplots(dpi=300)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#    if xaxislabel == "year":
#        xvals = drcpe.iloc[:,0]
#        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.8
#    else:
#        xvals = np.arange(1, drcpe.shape[0]+1)
#        w = 0.8
#
#    b = pd.Series(np.zeros(dncpe.shape[0]))
#
#    last = drcpe.shape[1]
#    for i in range(1, drcpe.shape[1]):
#        if i == last - 1:
#            label = "retro.Proc.CO2"
#        else:
#            label = ""
#        a.bar(xvals, drcpe.iloc[:, i],
#              width=w, bottom=b, lw=0.0, color="#dd0436",
#              align="edge", edgecolor="w", label=label, alpha=0.5)
#        b += drcpe.iloc[:, i]
#
#    last = drfue.shape[1]
#    for i in range(1, drfue.shape[1]):
#        if i == last - 1:
#            label = "retro.Fuel.CO2"
#        else:
#            label = ""
#        a.bar(xvals, drfue.iloc[:, i],
#              width=w, bottom=b, lw=0.0, color="#b8002a",
#              align="edge", edgecolor="w", label=label, alpha=0.5)
#        b += drfue.iloc[:, i]
#
#    ##
#    last = dncpe.shape[1]
#    for i in range(1, dncpe.shape[1]):
#        if i == last - 1:
#            label = "new.Proc.CO2"
#        else:
#            label = ""
#        #
#        a.bar(xvals, dncpe.iloc[:, i],
#              width=w, bottom=b, lw=0.0, color="#dd0436",
#              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.5)
#        b += dncpe.iloc[:, i]
#
#    last = dnfue.shape[1]
#    for i in range(1, dnfue.shape[1]):
#        if i == last - 1:
#            label = "new.Fuel.CO2"
#        else:
#            label = ""
#        a.bar(xvals, dnfue.iloc[:, i],
#              width=w, bottom=b, lw=0.0, color="#b8002a",
#              align="edge", edgecolor="w", hatch="//", label=label, alpha=0.5)
#        b += dnfue.iloc[:, i]
#
#    # last = druem.shape[1]
#    # for i in range(1, druem.shape[1]):
#    #     if i == last - 1:
#    #         label = "retro.eGrid.CO2"
#    #     else:
#    #         label = ""
#    #     a.bar(druem.iloc[:, 0], druem.iloc[:, i],
#    #           width=w, bottom=b, lw=0.0, color="#ffba00",
#    #           align="edge", edgecolor="w", label=label)
#    #     b += druem.iloc[:, i]
#
#    # last = dnuem.shape[1]
#    # for i in range(1, dnuem.shape[1]):
#    #     if i == last - 1:
#    #         label = "new.eGrid.CO2"
#    #     else:
#    #         label = ""
#    #     a.bar(dnuem.iloc[:, 0], dnuem.iloc[:, i],
#    #           width=w, bottom=b, lw=0.0, color="#ffba00",
#    #           align="edge", edgecolor="w", hatch="//", label=label)
#    #     b += dnuem.iloc[:, i]
#
#    b2 = pd.Series(np.zeros(dncpe.shape[0]))
#
#    if xaxislabel == "year":
#        xvals = drcpe.iloc[:, 0]
#        w = (drcpe.iloc[1, 0] - drcpe.iloc[0, 0]) * 0.7
#    else:
#        xvals = np.arange(1, drcpe.shape[0]+1)
#        w = 0.7
#
#    last = drep1.shape[1]
#    for i in range(1, drep1.shape[1]):
#        if i == last - 1:
#            label = "retro.PostCap.Proc.CO2"
#        else:
#            label = ""
#        a.bar(xvals, drep1.iloc[:, i],
#              width=w, bottom=b2, lw=0.0, color="#ff8e00",
#              align="edge", edgecolor="k", label=label)
#        b2 += drep1.iloc[:, i]
#
#    #
#    for i in range(1, dnep1.shape[1]):
#        if i == last - 1:
#            label = "new.PostCap.Proc.CO2"
#        else:
#            label = ""
#        a.bar(xvals, dnep1.iloc[:, i],
#              width=w, bottom=b2, lw=0.0, color="#ff8e00",
#              align="edge", edgecolor="k", hatch="//",
#              label=label)
#        b2 += dnep1.iloc[:, i]
#
#    last = druem.shape[1]
#
#    #for i in range(1, druem.shape[1]):
#    #    if i == last - 1:
#    #        label = "retro.eGrid.CO2"
#    #    else:
#    #        label = ""
#    #    a.bar(xvals, druem.iloc[:, i],
#    #          width=w, bottom=b2, lw=0.0, color="#ffba00",
#    #          align="edge", edgecolor="k", label=label)
#    #    b2 += druem.iloc[:, i]
#
#    #last = dnuem.shape[1]
#    #for i in range(1, dnuem.shape[1]):
#    #    if i == last - 1:
#    #        label = "new.eGrid.CO2"
#    #    else:
#    #        label = ""
#    #    a.bar(xvals, dnuem.iloc[:, i],
#    #          width=w, bottom=b2, lw=0.0, color="#ffba00",
#    #          align="edge", edgecolor="k", hatch="//")
#    #    b2 += dnuem.iloc[:, i]
#
#    # a.plot(xvals, dco2b.iloc[:], label="CO2-Constraint",
#    #       lw=2, color="dimgray", ls="--", marker="*")
#
#    ymax = b.max().max()
#    a.set_title("Pre/Post capture CO2 Emissions")
#
#    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
#    a.set_xlabel(xlabel)
#
#    a.set_ylabel("$MT CO_{2} yr^{-1}$")
#    a.set_ylim(top=ymax*1.01)
#    # tick labels
#    a.xaxis.set_major_formatter("{x:.0f}")
#    a.set_xticks(xvals)
#
#    f.savefig(folder + f"co2_act.{fmt}", dpi=300, format=f"{fmt}")
#    # save the legend
#    a.legend(bbox_to_anchor=(1.0, 1.0))
#    legend_object = a.get_legend()
#    export_legend(legend_object, folder + "legend_co2", fmt)



def plot_co2_cap_bar(rf, folder, fmt, xaxislabel=None):
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
        xvals = np.arange(1, drcpe.shape[0]+1)
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
    a.set_title("Captured CO2")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("$MT CO_{2} yr^{-1}$")
    a.set_ylim(top=ymax*1.01)
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "co2_ccap"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")
    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)
    plt.close(f)

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
def plot_legend(rf, folder, colors_r, colors_n, labr, labn, fmt):
    f, a = plt.subplots(dpi=300)
    for i in range(len(labr)):
        a.bar(0, 0,
              label=labr[i],
              edgecolor="k", lw=1.5, color=colors_r[i])

    legend = a.legend(loc='center', frameon=False)

    # if we remove these a horizontal black line appears?
    a.set_xlim(1, 2)
    a.set_ylim(1, 2)
    a.axis('off')
    f.savefig(folder + f"retrofits_legend.{fmt}", dpi=300, format=f"{fmt}")

    f, a = plt.subplots(dpi=300)
    for i in range(len(labn)):
        a.bar(0, 0,
              label=labn[i],
              edgecolor="k", lw=1.5, color=colors_n[i],
              hatch="//")

    legend = a.legend(loc='center', frameon=False)
    a.set_xlim(1, 2)
    a.set_ylim(1, 2)
    a.axis('off')
    f.savefig(folder + f"new_legend.{fmt}", dpi=300, format=f"{fmt}")


    f, a = plt.subplots(dpi=300)
    a.plot(0, 0,
           label="Demand", lw=2, color="blue", ls="--", marker="*")


    legend = a.legend(loc='center', frameon=False)
    a.set_xlim(1, 2)
    a.set_ylim(1, 2)
    a.axis('off')
    f.savefig(folder + f"demand-legend.{fmt}", dpi=300, format=f"{fmt}")

    plt.close(f)


#def plot_capf(rf, folder, colors, labr, labn, fmt, xaxislabel=None):
#    cprf = rf + "/dracf.csv"
#    dcf = pd.read_csv(cprf)
#
#    f, a = plt.subplots(dpi=300)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#    if xaxislabel == "year":
#        xvals = dcf.iloc[:, 0]
#        w = (dcf.iloc[1, 0] - dcf.iloc[0, 0]) * 0.8
#    else:
#        xvals = np.arange(1, dcf.shape[0]+1)
#        w = 0.8
#
#    for i in range(1, dcf.shape[1]):
#        name = dcf.columns[i]
#        node = name.split("_")[1]
#        if node == "2":
#            a.step(xvals, dcf.iloc[:, i], ls="--", lw=0.5, marker=".", label=f"plnt={i}")
#
#    a.set_title("Cap Fact Node=2 (Existing)")
#
#    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
#    a.set_xlabel(xlabel)
#
#    # tick labels
#    a.xaxis.set_major_formatter("{x:.0f}")
#    a.set_xticks(xvals)
#
#    f.savefig(folder + f"r_capf.{fmt}", dpi=300, format=f"{fmt}")
#    a.legend(bbox_to_anchor=(1.0, 1.0))
#    legend_object = a.get_legend()
#    export_legend(legend_object, folder + "legend_r_capf", fmt)
#
#
#    cpnf = rf + "/dnacf.csv"
#    dcf = pd.read_csv(cpnf)
#    f, a = plt.subplots(dpi=300)
#    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))
#
#    if xaxislabel == "year":
#        xvals = dcf.iloc[:, 0]
#        w = (dcf.iloc[1, 0] - dcf.iloc[0, 0]) * 0.8
#    else:
#        xvals = np.arange(1, dcf.shape[0]+1)
#        w = 0.8
#
#    for i in range(1, dcf.shape[1]):
#        name = dcf.columns[i]
#        node = name.split("_")[1]
#        if node == "2":
#            a.step(xvals, dcf.iloc[:, i], ls="--", lw=0.5, marker=".", label=f"plnt={i}")
#
#    a.set_title("Cap Fact Node=2 (New)")
#
#    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
#    a.set_xlabel(xlabel)
#
#    # tick labels
#    a.xaxis.set_major_formatter("{x:.0f}")
#    a.set_xticks(xvals)
#
#    f.savefig(folder + f"n_capf.{fmt}", dpi=300, format=f"{fmt}")
#    a.legend(bbox_to_anchor=(1.0, 1.0))
#    legend_object = a.get_legend()
#    export_legend(legend_object, folder + "legend_n_capf", fmt)


def plot_en_bar(rf, folder, fmt, xaxislabel=None):
    uf = rf +"/u.csv"
    infof = rf + "/s_info.csv"

    dinfo = pd.read_csv(infof)
    n_loc = dinfo.loc[0, "n_loc"]
    n_loc = dinfo.loc[0, "n_loc"]

    rfu = 3
    nfu = 3
    drff = [pd.read_csv(rf+ f"/dr_f_{i}.csv") for i in range(1, n_loc+1)]
    drff = [rescale_stre3am(drff[i], infof, "heat") for i in range(n_loc)]
    dnff = [pd.read_csv(rf+ f"/dn_f_{i}.csv") for i in range(1, n_loc+1)]
    dnff = [rescale_stre3am(dnff[i], infof, "heat") for i in range(n_loc)]

    drh = pd.read_csv(rf + "/drh.csv")
    drh = rescale_stre3am(drh, infof, "heat")

    dnh = pd.read_csv(rf + "/dnh.csv")
    dnh = rescale_stre3am(dnh, infof, "heat")


    rhf = np.zeros((drh.shape[0], rfu))
    nhf = np.zeros((dnh.shape[0], nfu))

    for l in range(1, n_loc+1):
        # fuel
        for f in range(rfu):
            for row in range(drh.shape[0]):
                # rhf[row, f] += drh.iloc[row, l] * drff[l-1].iloc[row, f+1]
                rhf[row, f] += drff[l-1].iloc[row, f+1]
        for f in range(nfu):
            for row in range(dnh.shape[0]):
                # nhf[row, f] += dnh.iloc[row, l]# * dnff[l-1].iloc[row, f+1]
                nhf[row, f] += dnff[l-1].iloc[row, f+1]

    df = pd.read_csv(uf)
    df = rescale_stre3am(df, infof, "elec")

    if xaxislabel == "year":
        xvals = df.iloc[:,0]
        w = (df.iloc[1, 0] - df.iloc[0, 0]) * 0.8
    else:
        xvals = np.arange(1, df.shape[0]+1)
        w = 0.8

    cp = ["#e27474", "#8a9edb", "#ffd7c2", "#2b2b2b"]
    fuels = ["Coal", "DFO2", "Natural Gas"]

    f, a = plt.subplots(dpi=300)
    plt.ticklabel_format(axis="y", style="sci", scilimits=(0, 0))

    a.bar(xvals, df.iloc[:,0], width=w, label="Ex.+Rf. Electricity",
          edgecolor="w", align="edge", lw=1.5, color=cp[0])

    b = pd.Series(np.zeros(df.shape[0]))
    b += df.iloc[:, 0]

    a.bar(xvals, df.iloc[:,1], width=w, label="New Electricity", bottom=b,
          edgecolor="w", align="edge", lw=1.5, color=cp[0], hatch="//")

    b += df.iloc[:, 1]
    for fu in range(rfu):
        a.bar(xvals, rhf[:,fu], width=w, label=f"Ex.+Rf. {fuels[fu]}", bottom=b,
              edgecolor="w",
              align="edge", lw=1.5, color=cp[fu+1])
        b += rhf[:, fu]
    for fu in range(nfu):
        a.bar(xvals, nhf[:,fu], width=w, label=f"New {fuels[fu]}", bottom=b,
              edgecolor="w",
              align="edge", lw=1.5, color=cp[fu+1], hatch="//")
        b += nhf[:, fu]


    a.set_title("Aggregate Energy Use")

    xlabel = xaxislabel if isinstance(xaxislabel, str) else "Period"
    a.set_xlabel(xlabel)

    a.set_ylabel("MMBTU $yr^{-1}$")
    # tick labels
    a.xaxis.set_major_formatter("{x:.0f}")
    a.set_xticks(xvals)
    figname = "energy_use"
    f.savefig(folder + f"{figname}.{fmt}", dpi=300, format=f"{fmt}")

    # save the legend
    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    #export_legend(legend_object, folder + "legend", fmt)

    # generate the legend
    f, a = plt.subplots(dpi=300)
    a.bar([0], [0], label="Existing Elec.", color=cp[0],
          edgecolor="w", lw=0.5, alpha=0.8)
    a.bar([0], [0], label="New Elec.", color=cp[0],
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")

    a.bar([0], [0], label=f"Ex.+Rf. {fuels[0]}", color=cp[1],
          edgecolor="w", lw=0.5, alpha=0.8)
    a.bar([0], [0], label=f"Ex.+Rf. {fuels[1]}", color=cp[2],
          edgecolor="w", lw=0.5, alpha=0.8)
    a.bar([0], [0], label=f"Ex.+Rf. {fuels[2]}", color=cp[3],
          edgecolor="w", lw=0.5, alpha=0.8)


    a.bar([0], [0], label=f"New {fuels[0]}", color=cp[1],
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")
    a.bar([0], [0], label=f"New {fuels[1]}", color=cp[2],
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")
    a.bar([0], [0], label=f"New {fuels[2]}", color=cp[3],
          edgecolor="w", lw=0.5, alpha=0.8, hatch="//")

    a.legend(bbox_to_anchor=(1.0, 1.0))
    legend_object = a.get_legend()
    export_legend(legend_object, folder + f"{figname}-leg", fmt)

    plt.close(f)

if __name__ == "__main__":
    main()
