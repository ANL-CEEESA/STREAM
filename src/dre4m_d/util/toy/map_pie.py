import geopandas as gpd
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

__author__ = "David Thierry @dthierry"

def pltrcparams():
    plt.rcParams.update({'font.size': 18})
    rfigsize = plt.rcParams['figure.figsize']
    ratio = rfigsize[1]/rfigsize[0]
    sarang_size = 6.9444444444
    plt.rcParams['figure.figsize'] = [sarang_size*ratio, sarang_size]
    plt.rcParams['font.sans-serif'] = "Helvetica"

# create a matrix for capacities by tech, loc and time
def cap_matrix(rf):
    cprf = rf + "/drcp_d_act.csv"
    cpnf = rf + "/dncp_d.csv"

    infof = rf + "/lrn_info.csv"
    dinfo = pd.read_csv(infof)

    if dinfo.loc[0, "n_rtft"] != dinfo.loc[0, "n_new"]:
        raise("The number of techs mismatch")


    dfr = pd.read_csv(cprf)
    dfn = pd.read_csv(cpnf)
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

# plant file
plant_f = "/Users/dthierry/Projects/dr3milp/src/ins_07_29/softX/fac_.csv"
#plant_f = "/Users/dthierry/Projects/dr3milp/src/data/state_cap.csv"
dictbounds = {'lat_1': 29.5, 'lat_2': 45.5, 'lon_0': -96.5, 'lat_0': 38.5}

projstring = '+proj=aea +lat_1={} +lat_2={} +lat_0={} +lon_0={}'.format(dictbounds['lat_1'], dictbounds['lat_2'], dictbounds['lat_0'], dictbounds['lon_0'])

d = gpd.read_file("/Users/dthierry/Downloads/Political_Boundaries_Area_-3349456916297595386/Political_Boundaries_(Area).shp").to_crs(projstring)


dp = pd.read_csv(plant_f)

d = d.loc[
    (d.COUNTRY == 'USA')
    & (~d.NAME.isin(
        ["water/agua/d'eau",'Navassa Island',
         'Puerto Rico','United States Virgin Islands',
         'Alaska', 'Hawaii']))]

# x
locations = []
for row in range(dp.shape[0]):
    s = dp.loc[row, "State"]
    s = "US-" + s
    booldf = d.loc[:, "STATEABB"] == s
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
#
centroids = d.centroid
xc = centroids.x
yc = centroids.y


nrows = 4


edgecolor = "k"
facecolor = "w"

pltrcparams()
# dummy plot generator
f0, a0 = plt.subplots()
#
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


labels = ["2020", "2025", "2030", "2035", "2040", "2045", "2050", "2055"]

# maps
rf = "."  # reference folder
# call the matrix function
cap, (n_tp, n_loc, n_tech), labels = cap_matrix(rf)
labels = ["t={}".format(i) for i in range(n_tp)]
# main plot
fig, ax = plt.subplots(nrows, n_tp//nrows, sharex=True, sharey=True, dpi=600,
                       gridspec_kw={'hspace':0.1, 'wspace':-0.05})
#plt.rcParams.update({'axes.titlesize': 'x-small'})


for i in range(n_tp):
    axx = ax.flat[i]
    d.plot(ax=axx, lw=0.1, facecolor='none', edgecolor=edgecolor, zorder=1e6)
    axx.set_title(labels[i], pad=-6.0)
    axx.axis("off")
    for plant in range(n_loc):
        loc_idx = locations[plant]
        x, y = xc.iloc[loc_idx], yc.iloc[loc_idx]
        values = cap[plant, :, i]
        #s = sum(values)
        s = sum(values)*5
        #s = sum(values) * 1e-02/2
        facecolor=piecolors
        if s <= 1e-08:
            wedges = a0.pie([1], colors="red")
            s = 1
            facecolor=["red"]
        else:
            values = [val if val > 0 else 0 for val in values]
            wedges = a0.pie(values, colors=piecolors)
        n_wedges = len(wedges[0])
        for j in range(n_wedges):
            axx.scatter([x], [y],
                          marker=(wedges[0][j].get_path().vertices.tolist()),
                          facecolor=facecolor[j],
                          s=s,
                          edgecolor='black',
                          linewidth=0.1,
                          # alpha=1.0
                          )

fig.savefig("map.png")


