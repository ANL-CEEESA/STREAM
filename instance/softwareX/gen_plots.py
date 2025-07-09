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

# written by @dthierry 2025


import os
import sys

sys.path.insert(1, "../../src/stre3am_d/util/toy/")

import numpy as np
import pandas as pd
import matplotlib as mpl

import matplotlib.pyplot as plt

from bars import all_bars
from switches import all_switches
from map_res import gen_map


def pltrcparams():
    mpl.rcParams.update(mpl.rcParamsDefault)
    rfigsize = plt.rcParams['figure.figsize']
    ratio = rfigsize[1]/rfigsize[0]
    plt.rcParams['font.sans-serif'] = "Helvetica"
    plt.rcParams['figure.autolayout'] = True



def print_disclaimer():
    disclaimer_text = """
    DISCLAIMER: Please read the README.md before running this script.
    Make sure you have run the Julia files, `gen_data_toy.jl` `prototype.jl`
    BEFORE you run this script.
    Also make sure you have created the environment with the environment.yml at
    the root directory of STRE3AM.
    """

def main():
    #print_disclaimer()
    fmt = "eps"

    plot_results(fmt)
    mpl.rcParams.update(mpl.rcParamsDefault)

    #plot_maps(fmt)
    #mpl.rcParams.update(mpl.rcParamsDefault)

    #compute_scenario_data(fmt)
    # mpl.rcParams.update(mpl.rcParamsDefault)
    #pareto_curve(fmt)


def plot_results(fmt):
    with open("most_recent_run.txt", "r") as f:
        ln = 0
        lines = f.readlines()
        with open("output.txt", "w") as nf:
            for line in lines:
                fname = line.split()[0]
                bar_file = all_bars(fname, fmt)
                switch_file = all_switches(fname, fmt)
                os.rename(bar_file, f"{ln}-b")
                os.rename(switch_file, f"{ln}-s")

                newline = line.rstrip() + "\t" #+ f"{ln}-b" + "\t" \
                newline += f"{ln}-s" + "\t"
                newline += "\n"
                nf.write(newline)

                ln += 1



def plot_maps(fmt):
    with open("most_recent_run.txt", "r") as f:
        ln = 0
        lines = f.readlines()
        with open("map_output.txt", "w") as nf:
            for line in lines:
                fname = line.split()[0]
                map_file = gen_map(fname,
                                   "../softwareX/samples",
                                   "../softwareX/cb_2018_us_state_20m",
                                   fmt)

                os.rename(map_file, f"{ln}-map.{fmt}")
                newline = line.rstrip() + "\t" + f"{ln}-map.{fmt}" + "\n"
                nf.write(newline)
                ln += 1


def compute_scenario_data(fmt):
    pltrcparams()
    with open("most_recent_run.txt") as f:
        lines = f.readlines()
        n_rows = len(lines)
        n_scen = n_rows // 2

        n_cols = 4
        val_matrix = np.zeros((n_rows, n_cols))
        for row in range(n_rows):
            v = lines[row].split()
            for col in range(1, len(v)):
                val_matrix[row, col-1] = np.float64(v[col])

    abatement_cost = np.zeros(n_scen)
    incremental_cost = np.zeros(n_scen)
    incremental_em = np.zeros(n_scen)

    for i in range(n_scen):
        cc_ofv = val_matrix[i*2, 2]
        cc_cov = val_matrix[i*2, 3]

        bau_ofv = val_matrix[i*2+1, 2]
        bau_cov = val_matrix[i*2+1, 3]

        incremental_cost[i] = cc_ofv - bau_ofv
        incremental_em[i] = bau_cov - cc_cov

        abatement_cost[i] = (incremental_cost[i])/(incremental_em[i])


    f, a = plt.subplots(dpi=300)

    a.bar(np.linspace(1, n_scen, num=n_scen), incremental_cost, color="tab:blue",
          label="Incremental Cost", width=0.5, align="edge")
    a.yaxis.label.set_color("tab:blue")
    a.set_ylabel("Incremental cost MMUSD")

    a2 = a.twinx()
    a2.bar(np.linspace(1.5, n_scen+0.5, num=n_scen), incremental_em, color="tab:red",
           label="Incremental Em.", width=0.5, align="edge")
    a2.set_ylabel("Incremental Em. MT$CO_{2}$")
    a2.yaxis.label.set_color("tab:red")

    a3 = a.twinx()
    a3.spines.right.set_position(("axes", 1.2))
    a3.plot(np.linspace(1.5, n_scen+0.5, num=n_scen), abatement_cost,
            color="tab:olive", linestyle="",
            label="Abatement", marker="v")
    a3.set_ylabel("Abatement MMUSD/MT$CO_{2}$")
    a3.yaxis.label.set_color("tab:olive")

    a.set_title("Scenarios Incremental Cost and Emissions")
    a.set_xlabel("Scenario")

    a.grid()

    colors_list = ["tab:blue", "tab:red", "tab:olive"]
    labels = ["Incremental Cost", "Incremental Em.", "Abatement"]
    handles = [plt.Rectangle((0,0), 1, 1, color=colors_list[i]) for i in range(3)]

    a.legend(handles=handles, labels=labels)
    f.savefig(f"incremental.{fmt}", dpi=300, format=fmt)


    d = pd.DataFrame({"scenario": np.arange(n_scen),
                      "incremental_MMUSD": incremental_cost,
                      "incremental_MTCO2": incremental_em,
                      "abatement_MT/MMUSD": abatement_cost})
    d.to_csv("scenario_increment_abat.csv")

    return d


def pareto_curve(fmt):
    n_cols = 4 # columns from the most_recent_run

    bau_ofv = 1.0
    bau_cov = 1.0
    minco2_ofv = 1.0
    minco2_cov = 1.0

    with open("bau_run.txt") as f:
        lines = f.readlines()
        v = lines[0].split()
        print(v)
        bau_ofv = np.float64(v[3])
        bau_cov = np.float64(v[4])

    print(f"bau_ofv = {bau_ofv}\tbau_cov = {bau_cov}")
    # with open("minco2_run.txt") as f:
    #     lines = f.readlines()
    #     v = lines[0].split()
    #     print(v)
    #     minco2_ofv = np.float64(v[3])
    #     minco2_cov = np.float64(v[4])

    # print(f"minco2_ofv = {minco2_ofv}\tminco2_cov = {minco2_cov}")

    with open("most_recent_run.txt") as f:
        lines = f.readlines()
        n_rows = len(lines)
        val_matrix = np.zeros((n_rows, n_cols))
        for row in range(n_rows):
            v = lines[row].split()
            for col in range(1, len(v)):
                val_matrix[row, col-1] = np.float64(v[col])

    ofv = np.zeros(n_rows)  # objective function value
    cov = np.zeros(n_rows)  # co2 value

    incremental_cost = np.zeros(n_rows) # includes bau & min_co2
    incremental_em = np.zeros(n_rows) # includes bau & min_co2

    abatement_cost = np.zeros(n_rows)  # includes min_co2

    for i in range(n_rows):
        ofv[i] = val_matrix[i, 2]
        cov[i] = val_matrix[i, 3]

    c_red = np.linspace(0., 0.5, n_rows)

    d = pd.DataFrame(np.column_stack((c_red, ofv, cov)),
                     columns=["c_red", "npv_MMUSD", "co2_MT"])

    d.loc[-1] = [-9999.0, bau_ofv, bau_cov]
    d.index = d.index+1
    d = d.sort_index()

    #d.loc[len(d)] = [9999.0, minco2_ofv, minco2_cov]

    d.to_csv("pareto_front.csv")

    f, a = plt.subplots(dpi=300)
    a.plot(cov, ofv, lw=2, color="tab:blue", marker="s", fillstyle="none")
    a.grid()
    a.set_title("Pareto front")
    a.set_xlabel("MT$CO_2$")
    a.set_ylabel("MMUSD")

    for i in range(n_rows):
        a.annotate(f"{c_red[i]:.0%}", xy=(cov[i], ofv[i]), textcoords="data")

    a.plot(bau_cov, bau_ofv, color="tab:red", marker="*")
    a.annotate("BAU", xy=(bau_cov, bau_ofv), textcoords="data")

    #a.plot(minco2_cov, minco2_ofv, color="tab:green", marker="*")
    #a.annotate("Minimum CO$_2$", xy=(minco2_cov, minco2_ofv), textcoords="data")

    #a.set_ylim(bottom=0)
    f.savefig(f"pareto.{fmt}", dpi=300, format=fmt)

    #
    for i in range(n_rows):
        incremental_cost[i] = ofv[i] - bau_ofv
        incremental_em[i] =  bau_cov - cov[i]

    #incremental_cost[n_rows+1] = minco2_ofv -  bau_ofv
    #incremental_em[n_rows+1] = bau_ofv - minco2_cov

    for i in range(n_rows):
        abatement_cost[i] = incremental_cost[i]/incremental_em[i]

    d = pd.DataFrame(np.column_stack((c_red,
                                      incremental_cost,
                                      incremental_em,
                                      abatement_cost)),
                     columns=["c_red", "npv_MMUSD", "co2_MT", "ab_MMUSD/co2_MT"])
    d.to_csv("incremental_pareto.csv")

    f, a = plt.subplots(dpi=300)
    a.plot(incremental_em, incremental_cost, lw=2, color="tab:red", marker="o",
           fillstyle="none")
    a.grid()
    a.set_title("Incremental (Relative to BAU)")
    a.set_xlabel("Incremental emission MT$CO_2$")
    a.set_ylabel("Incremental cost MMUSD")

    for i in range(n_rows):
        a.annotate(f"{c_red[i]:.0%}", xy=(incremental_em[i], incremental_cost[i]), textcoords="data")

    f.savefig(f"incremental_cost.{fmt}", dpi=300, format=fmt)


if __name__ == "__main__":
    main()
