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


import sys
sys.path.insert(1, "../../src/stre3am_d/util/toy/")
from bars import all_bars
from switches import all_switches
from map_res import gen_map


def print_disclaimer():
    disclaimer_text = """
    DISCLAIMER: Please read the README.md before running this script.
    Make sure you have run the Julia files, `gen_data_toy.jl` `prototype.jl`
    BEFORE you run this script.
    Also make sure you have created the environment with the environment.yml at
    the root directory of STRE3AM.
    """

def main():
    print_disclaimer()

    with open("most_recent_run.txt") as f:
        fname = f.readlines()[0]

    all_bars(fname, "png")
    all_switches(fname, "png")

    print("To plot the map please donwload the shapefile from the website:")
    link = "https://www.census.gov/geographies/mapping-files/time-series/geo/carto-boundary-file.html"
    print(link)
    mapname = "cb_2018_us_state_20m.zip [<1.0 MB]"
    print(mapname)
    # uncomment this line if you have the mapfile
    # gen_map(fname,
    #         "samples",
    #         "./cb_2018_us_state_20m",
    #         "png")




if __name__ == "__main__":
    main()
