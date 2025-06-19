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
# map_pie.py
# notes: create a map with the progression of technologies.

# 80############################################################################

import geopandas as gpd
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import datetime


__author__ = "David Thierry @dthierry"

def pltrcparams():
    #plt.rcParams.update({'font.size': 10})
    rfigsize = plt.rcParams['figure.figsize']
    ratio = rfigsize[1]/rfigsize[0]
    sarang_size = 6.9444444444
    plt.rcParams['figure.figsize'] = [sarang_size*ratio, sarang_size]
    plt.rcParams['font.sans-serif'] = "Helvetica"

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


def cap_matrix(rf):
    cprf = rf + "/drcp_d_act.csv"
    cpnf = rf + "/dncp_d.csv"

    infof = rf + "/lrn_info.csv"
    s_info = rf + "/s_info.csv"
    dinfo = pd.read_csv(infof)


    if dinfo.loc[0, "n_rtft"] != dinfo.loc[0, "n_new"]:
        raise("The number of techs mismatch")


    dfr = pd.read_csv(cprf)
    dfr = rescale_stre3am(dfr, s_info, "cap")
    dfn = pd.read_csv(cpnf)
    dfn = rescale_stre3am(dfn, s_info, "cap")
    #
    n_loc = dinfo.loc[0, "n_loc"]
    n_tech = dinfo.loc[0, "n_rtft"]
    n_tp = dfr.shape[0]
    #
    cap = np.zeros([n_loc, n_tech, n_tp])
    #
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
    return cap, (n_tp, n_loc, n_tech), dfr.iloc[:, 0]


def gen_map(res_folder, sample_folder, map_folder, fmt):

    #fmt = "eps"

    # plant file
    plant_f = sample_folder + "/sample_cs_n=10.csv"
    map_f = map_folder + "/cb_2018_us_state_20m.shp"

    lat_1= 29
    lat_2= 46
    lon_0= -97
    lat_0= 39
    projection = f"+proj=aea +lat_1={lat_1} +lat_2={lat_2} +lat_0={lat_0} +lon_0={lon_0}"

    d = gpd.read_file(map_f).to_crs(projection)

    dp = pd.read_csv(plant_f)

    d = d.loc[(~d.NAME.isin(
            ["water/agua/d'eau",'Navassa Island',
             'Puerto Rico','United States Virgin Islands',
             'Alaska', 'Hawaii']))]

    locations = []
    for row in range(dp.shape[0]):
        s = dp.loc[row, "State"]
        #s = "US-" + s
        booldf = d.loc[:, "STUSPS"] == s
        #
        idx = 0
        for row in booldf:
            if row:
                break
            idx += 1
        no_location = True if idx == booldf.shape[0] else False
        #
        if no_location:
            raise(f"This state was not found in the map {s}")
        locations.append(idx)
    n_loc = dp.shape[0]

    centroids = d.centroid
    xc = centroids.x
    yc = centroids.y


    nrows = 4


    edgecolor = "k"
    facecolor = "w"

    pltrcparams()
    # dummy plot generator
    f0, a0 = plt.subplots()

    piecolors = [
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

    # maps
    rf = res_folder  # reference folder
    # call the matrix function
    cap, (n_tp, n_loc, n_tech), labels = cap_matrix(rf)
    labels = ["subperiod {}".format(i) for i in range(1, n_tp+1)]
    # main plot
    fig, ax = plt.subplots(nrows, n_tp//nrows, sharex=True, sharey=True, dpi=600,
                           gridspec_kw={'hspace':0.1, 'wspace':-0.05})

    yoffs = np.random.uniform(-1e-01, 1e-01, size=n_loc) + 1e0
    xoffs = np.random.uniform(-1e-01, 1e-01, size=n_loc) + 1e0
    smin = 0
    smax = 0
    for i in range(n_tp):
        axx = ax.flat[i]
        d.plot(ax=axx, lw=0.1, facecolor='none', edgecolor=edgecolor, zorder=1e6)
        axx.set_title(labels[i], pad=-6.0)
        axx.axis("off")
        if i == 0:
            for plant in range(n_loc):
                loc_idx = locations[plant]
                x, y = xc.iloc[loc_idx], yc.iloc[loc_idx]
                axx.annotate("{}".format(plant+1),
                             xy=(x*xoffs[plant], y*yoffs[plant]))
        for plant in range(n_loc):
            loc_idx = locations[plant]
            x, y = xc.iloc[loc_idx], yc.iloc[loc_idx]
            values = cap[plant, :, i]


            #s = sum(values)
            s = sum(values)
            smin = smin if s > smin else s
            smax = smax if s < smax else s
            # s = sum(values) * 1e-02/2
            facecolor=piecolors
            if s <= 1e-08:
                wedges = a0.pie([1], colors="red")
                s = 5
                facecolor=["red"]
                axx.scatter([x], [y],
                            s=1.0,
                            facecolor="red",
                            edgecolor='black',
                            linewidth=0.1,
                            alpha=1.0
                            )
            else:
                values = [val if val > 0 else 0 for val in values]
                wedges = a0.pie(values, colors=piecolors)
            n_wedges = len(wedges[0])
            for j in range(len(values)):


                sc = axx.scatter([x], [y],
                                s=values[j],
                                facecolor=piecolors[j],
                                edgecolor='black',
                                linewidth=0.1,
                                alpha=0.5
                                )


    f0, ax0 = plt.subplots()
    sx = np.linspace(np.floor(smax)/2, np.floor(smax), num=3)
    npoints = 3
    sc = ax0.scatter([x for i in range(npoints)],
                     [y for i in range(npoints)], s=sx)
    lc = ticker.LinearLocator(3)
    kw = dict(prop="sizes", fmt="{x:.0f}", num=npoints) #,
              #func=lambda s: s/500)
    legend2 = axx.legend(*sc.legend_elements(**kw),
                        loc="lower right", title="tonne/yr")
                         #bbox_to_anchor=(1,1))
    ts = datetime.datetime.now().timestamp()
    fig.savefig(f"map_{ts}.{fmt}", format=f"{fmt}")
    print(f"Generated map_{ts}.{fmt}\n")
    return f"map_{ts}.{fmt}"


