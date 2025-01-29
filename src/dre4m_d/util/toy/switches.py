
import pandas as pd
import matplotlib.pyplot as plt
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

colors = [
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

rlf = "retro_labels.csv"
nlf = "new_labels.csv"

rfilter_f = "retro_filters.csv"
nfilter_f = "new_filters.csv"

drl = pd.read_csv(rlf)
labr = drl.iloc[:,0].to_list()
dnl = pd.read_csv(nlf)
labn = dnl.iloc[:,0].to_list()


rfilter = pd.read_csv(rfilter_f)
nfilter = pd.read_csv(nfilter_f)

rtpc = [hex_to_rgb(i) for i in colors]
ntpc = [hex_to_rgb(i) for i in colors]
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
    a.set_xlabel("Period")
    f.tight_layout()

    f.savefig(folder + f"rf_{k}_.eps", dpi=200, transparent=True, format="eps")
    plt.close(f)

matrix = [[rtpc[0] for col in range(ly[0].shape[1])] for row in range(ly[1].shape[0])]

for row in range(ly[0].shape[0]):
    for col in range(ly[0].shape[1]):
        c = rtpc[0]
        sum_elem = 0
        for k in range(len(ly)):
            sum_elem += ly[k][row][col]
            if ly[k][row][col] > 0:
                c = rtpc[k]
        if sum_elem > 1:
            print("this is an error")
        matrix[row][col] = c

f, a = plt.subplots()#figsize=(5, 25))

a.set_xticks(np.arange(0, ntslices, 1))
a.set_yticks(ticks=ytick, labels=ylab)

a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

a.imshow(matrix, aspect="equal")
a.grid(which="minor", color="w", linestyle="-", linewidth=1)
a.tick_params(which="minor", bottom=False, left=False)

a.set_title(f"Retrofit status")
a.set_ylabel("Plant")
a.set_xlabel("Period")
f.tight_layout()

f.savefig(folder + f"rf_agg_.eps", dpi=200, transparent=True, format="eps")
plt.close(f)


######## ######## ######## ######## ######## ######## ######## ######## ########
# generate the legend
f, a = plt.subplots(dpi=300)
for i in range(dlrn.loc[0, "n_rtft"]):
    a.bar([1], [1], label=labr[i], color=colors[i])
l = a.legend(bbox_to_anchor=(1,1), loc="upper left")
f.canvas.draw()
bbox = l.get_window_extent().transformed(f.dpi_scale_trans.inverted())
f.savefig(folder + "legend_rf.eps", bbox_inches=bbox, format="eps")
######## ######## ######## ######## ######## ######## ######## ######## ########


ly = []
for k in range(dlrn.loc[0, "n_new"]):
    yn = dyn[f"k_{k+1}_l_1"]
    for l in range(1, dlrn.loc[0, "n_loc"]):
        if rfilter.iloc[l, k]:
            c = f"k_{k+1}_l_{l+1}"
            yn_l = dyn[c].to_numpy()
        else:
            yr_l = np.zeros(dyn.shape[0])
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

    a.set_title(f"New {k} status")
    a.set_ylabel("Plant")
    a.set_xlabel("Period")
    f.tight_layout()

    f.savefig(folder + f"nw_{k}_.eps", dpi=200, transparent=True, format="eps")
    plt.close(f)

# for l in range(dlrn.loc[0, "n_loc"]):
#     c = [f"k_{k+1}_l_{l+1}" for k in range(dlrn.loc[0, "n_new"])]
#     yn_l = dyn[c].to_numpy()
#
#     yn = np.transpose(yn_l)
#
#     f, a = plt.subplots(figsize=(20, 5))
#
#     a.set_xticks(np.arange(0, 30, 1))
#     a.set_yticks(np.arange(0, dlrn.loc[0, "n_new"], 1))
#
#     a.set_xticks(np.arange(-0.5, 29, 1), minor=True)
#     a.set_yticks(np.arange(-0.5, dlrn.loc[0, "n_new"]-1, 1), minor=True)
#
#     a.imshow(yn, cmap="Blues", aspect="equal", interpolation="nearest", vmin=0)
#     a.grid(which="minor", color="w", linestyle="-", linewidth=1)
#     a.tick_params(which="minor", bottom=False, left=False)
#     #a.set_xticklabels(np.arange(2020, 2050, 1))
#     a.set_yticklabels(nw_l)
#
#     a.set_title(f"loc={l+1}")
#     a.set_ylabel("new kind")
#     a.set_xlabel("period")
#     f.tight_layout()
#
#     f.savefig(folder + f"nws_l-{l}.eps", dpi=200, transparent=True)
#     plt.close(f)

matrix = [[ntpc[0] for col in range(ly[0].shape[1])] for row in range(ly[1].shape[0])]

for row in range(ly[0].shape[0]):
    for col in range(ly[0].shape[1]):
        c = ntpc[0]
        sum_elem = 0
        for k in range(len(ly)):
            sum_elem += ly[k][row][col]
            if ly[k][row][col] > 0:
                c = ntpc[k]
        if sum_elem > 1:
            print("this is an error")
        matrix[row][col] = c

f, a = plt.subplots()#figsize=(5, 25))

a.set_xticks(np.arange(0, ntslices, 1))
a.set_yticks(ticks=ytick, labels=ylab)

a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

a.imshow(matrix, aspect="equal")
a.grid(which="minor", color="w", linestyle="-", linewidth=1)
a.tick_params(which="minor", bottom=False, left=False)

a.set_title(f"New plant status")
a.set_ylabel("Plant")
a.set_xlabel("Period")
f.tight_layout()

f.savefig(folder + f"nw_agg_.eps", dpi=200, transparent=True, format="eps")
plt.close(f)



######## ######## ######## ######## ######## ######## ######## ######## ########
# generate the legend
f, a = plt.subplots(dpi=300)
for i in range(dlrn.loc[0, "n_new"]):
    a.bar([1], [1], label=labn[i], color=colors[i])
l = a.legend(bbox_to_anchor=(1,1), loc="upper left")
f.canvas.draw()
bbox = l.get_window_extent().transformed(f.dpi_scale_trans.inverted())
f.savefig(folder + "legend_nw.eps", bbox_inches=bbox, format="eps")
######## ######## ######## ######## ######## ######## ######## ######## ########

# for l in range(dlrn.loc[0, "n_loc"]):
nloc = dlrn.loc[0, "n_loc"]
nper = dlrn.loc[0, "n_p"]
nsp = dlrn.loc[0, "n_p2"]

ntslices = nper * nsp

yo_l = dyo.iloc[:,1:].to_numpy()

yo = np.transpose(yo_l)

#f, a = plt.subplots(figsize=(20, 5))
#f, a = plt.subplots(figsize=(24, 8))




f, a = plt.subplots()#figsize=(5, 25))
a.set_xticks(np.arange(0, ntslices, 1))
#a.set_yticks(np.arange(1, nloc+1, 1))
#a.set_yticks(prange)

a.set_yticks(ticks=ytick, labels=ylab)
a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

a.imshow(yo, cmap="Reds", aspect="equal", interpolation="nearest", vmin=0)
a.grid(which="minor", color="w", linestyle="-", linewidth=1)
a.tick_params(which="minor", bottom=False, left=False)
#a.set_xticklabels(range(2020, 2050, 5))
#a.set_yticklabels(["Online"])

a.set_title(f"Online status")
a.set_ylabel("Plant")
a.set_xlabel("Period")
f.tight_layout()

f.savefig(folder + "yo.eps", dpi=200, transparent=True, format="eps")
plt.close(f)


######## ######## ######## ######## ######## ######## ######## ######## ########
ye_l = dye.iloc[:,1:].to_numpy()
yo_l = dyo.iloc[:,1:].to_numpy()

ye_l = np.multiply(ye_l, yo_l)
ye = np.transpose(ye_l)

#f, a = plt.subplots(figsize=(20, 5))
#f, a = plt.subplots(figsize=(24, 8))
f, a = plt.subplots()#figsize=(5, 25))

a.set_xticks(np.arange(0, ntslices, 1))
#a.set_yticks(np.arange(1, nloc+1, 1))
#a.set_yticks(prange)

a.set_yticks(ticks=ytick, labels=ylab)

a.set_xticks(np.arange(-0.5, ntslices+1, 1), minor=True)
a.set_yticks(np.arange(0.5, nloc, 1), minor=True)

a.imshow(ye.reshape(ye.shape[0], -1),
         cmap="Oranges", aspect="equal", interpolation="nearest", vmin=0)
a.grid(which="minor", color="w", linestyle="-", linewidth=1)
a.tick_params(which="minor", bottom=False, left=False)

a.set_title("Expansion status")
a.set_ylabel("Plant")
a.set_xlabel("Period")
f.tight_layout()

f.savefig(folder + "exps_.eps", dpi=200, transparent=True, format="eps")
plt.close(f)



