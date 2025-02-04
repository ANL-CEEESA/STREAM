# -*- coding: utf-8 -*-
# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy,
# Economic, and Equity Analysis Model
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
# fuels.py
# notes: plots the fuel consumption bars.

# 80############################################################################

import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
import pandas as pd
import numpy as np
import datetime
import os
import sys

__author__ = "David Thierry @dthierry"

try:
    arg = sys.argv[1]
except IndexError:
    raise SystemExit(f"Usage: {sys.argv[0]} <string>")

f0 = arg

plt.style.use("seaborn-v0_8-colorblind")

dt = datetime.datetime.now()
folder = dt.strftime("%c")
folder = folder.replace(" ", "-")
folder = folder.replace(":", "-")

os.mkdir(folder)

folder = './' + folder
folder += '/'

labr = ["Orig", # 1
        "r:Efficiency", # 2
        "r:Coal->H2", # 5
        "r:Full elec", # 7
        "r:CCUS", # 8
        ]

labn = ["N/A", # 1
        "n:Efficiency", # 2
        "n:Coal->H2", # 5
        "n:Full elec", # 7
        "n:CCUS", # 8
        ]

lab = ["Orig", # 1
        "r:Efficiency", # 2
        "r:LC3", # 2
        "r:Coal->NG", # 2
        "r:Coal->H2", # 5
        "r:Bio+", # 5
        "r:Full elec", # 7
        "r:CCUS", # 8
        ]
labr = lab
labn = lab
infof = f0 + "/s_info.csv"
dlrn = pd.read_csv(infof)

n_rtft = dlrn.loc[0, "n_rtft"]
n_new = dlrn.loc[0, "n_new"]
n_fu = dlrn.loc[0, "n_fu"]
n_p = dlrn.loc[0, "n_p"]
n_p2 = dlrn.loc[0, "n_p2"]

nrows = int(np.ceil(n_fu/2))

plt.rcParams.update({'axes.titlesize': 'small'})

figs, axs = plt.subplots(int(np.ceil(n_fu/2)), 2,
                         sharex="all",
                         #gridspec_kw={'hspace':0.05},#, 'wspace':1.05},
                         figsize=(nrows/2, nrows)
                         )

#gridsize = (int(np.ceil(n_fu/2)), 2)
#axs = []
#for fu in range(n_fu):
#    if fu < np.ceil(n_fu/2):
#        col = 0
#        row = fu
#    else:
#        col = 1
#        row = fu - int(np.ceil(n_fu/2))
#
#    axs.append(plt.subplot2grid(gridsize, (row, col)))

axs = axs.flatten()
w = 0.8

b = np.zeros([n_p*n_p2, n_fu])


#colors = [
#    "#FF5733",
#    "#33FF57",
#    "#FF33C2",
#    "#33C2FF",
#    "#FFC233",
#    "#C233FF",
#    "#FF336A",
#    "#33D4FF"]

colors = [
    "#e7b24b",
    "#cec44b",
    "#b0d54b",
    "#88e54b",
    "#6adc75",
    "#68b7a7",
    "#6890ca",
    "#6a5ee6"
]

titles = ["Coal", "Nat. Gas", "Petcoke", "H2"]
titles = ["Agric.BPD",
          "Asphalt/RoadOil",
          "Biodiesel",
          "Biodiesel_1",
          "Biogas",
          "Bituminous",
          "Blastf. Gas",
          "Coalcoke",
          "Coke",
          "Dist.FuelOil.2",
          "Kerosene",
          "Landfillgas",
          "Mixed",
          "Motorgasoline",
          "Municipalsolid",
          "Naturalgas",
          "Naturalgasol.",
          "Otheroil",
          "Petroleumcoke",
          "Plastics",
          "Propane",
          "Propanegas",
          "Res.Fueloilno.5",
          "Res.Fueloilno.6",
          "Solid.BPD",
          "Subbituminous",
          "Tires",
          "Used Oil",
          "Woodandwoodres.",
          "Woodandwoodres._1",
          "Hydrogen"]

for i in range(1, n_rtft+1):
    f = f0 + f"/drehf_{i}.csv"
    df = pd.read_csv(f)
    for fu in range(1, n_fu+1):
        #title = df.columns[fu]
        title = titles[fu-1]
        values = [val if val > 1e-2 else 0.0 for val in df.iloc[:, fu]]
        axs[fu-1].bar(df.iloc[:, 0], values,
                      width=w, bottom=b[:, fu-1], label=labn[i-1],
                      align="edge", lw=1.0, color=colors[i-1], edgecolor="k")

        b[:, fu-1] += df.iloc[:, fu]



for i in range(1, n_new+1):
    f = f0 + f"/dnehf_{i}.csv"
    df = pd.read_csv(f)
    for fu in range(1, n_fu+1):
        #title = df.columns[fu]
        title = titles[fu-1]
        values = [val if val > 1e-2 else 0.0 for val in df.iloc[:, fu]]
        axs[fu-1].bar(df.iloc[:, 0], values,
                      width=w, bottom=b[:, fu-1], label=labn[i-1],
                      align="edge", lw=1.0, color=colors[i-1], edgecolor="k",
                      hatch="/")

        b[:, fu-1] += df.iloc[:, fu]


for fu in range(1, n_fu+1):
    axs[fu-1].set_ylim(bottom=0)
    title = titles[fu-1]
    axs[fu-1].set_title(title)
    axs[fu-1].set_ylabel("MMBTU")
    axs[fu-1].ticklabel_format(style='sci', axis='y', scilimits=(0, 0))
    axs[fu-1].xaxis.set_major_formatter("{x:.0f}")
    axs[fu-1].set_xticks(df.iloc[:, 0])

plt.subplots_adjust(hspace=0.5, wspace=0.5)
plt.savefig(folder + "fuels.png" , dpi=300)


