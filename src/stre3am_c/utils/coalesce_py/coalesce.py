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

# vim: expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2022
# coalesce.py
# description: This file creates a nice summary of all the excel files from a
# given case study
#
# log:
# 1-31-23 added some comments
#
#
#80#############################################################################

import pandas as pd
import os, sys

# Notes:
# Root directory contains a several of folders
# Each folder contains 4 cases
# Within each folder there should be a _stats.xlsx file

def getCurFold(path: str = ".") -> list:
    """Gets the current folder path.
    """
    result = []
    for _, dirs, _ in os.walk(path):
        break
    return sorted(dirs)

def get_folders(directory) -> dict:
    """Gets all the folders in the current directory.
    """
    fulladdress = []
    d = []
    dirs = os.listdir(directory)
    dirs = sorted(dirs)
    for i in dirs:
        k = os.path.join(directory, i)
        if os.path.isdir(k):
            fulladdress.append(k)
            d.append(i)
    actDict = {}
    idx = 0
    for i in d:
        s = i.split("_")[4:]
        key = ""
        for j in s:
            key += j + "_"
        key = key[:-1]
        actDict[key] = fulladdress[idx]
        idx += 1
    suffix = "_stats.xlsx"
    for k in actDict.keys():
        fn = actDict[k].split("/")[-1] + suffix
        actDict[k] = os.path.join(actDict[k], fn)
    return actDict


def coalesce():
    """Read the excel files contents and get the summary file.
    """
    # A file can be "cb", "bau", "c350", and "c500"
    #
    folders = getCurFold()
    listOfFileDict = []
    lef0 = []
    titles = []
    for f in folders:
        filesDict = get_folders(f)
        listOfFileDict.append(filesDict)
        print(f"the mf folder {f}")
        for k in filesDict.keys():
            print(f"\t{k}")
            lef0.append(filesDict[k])
            titles.append(k)


    # we need to know the spreadsheet names first
    pdef = pd.ExcelFile(lef0[0])
    sheet_names = pdef.sheet_names
    with pd.ExcelWriter("coalesce.xlsx", mode="w") as writer:
        df = pd.DataFrame(["next sheet"])
        df.to_excel(writer, sheet_name="next")

    for sh_n in sheet_names:
        #if sh_n != "ccost_retro":
        #    continue
        #d0 = pd.DataFrame()
        k = 0
        lef = lef0.copy()
        titlesl = titles.copy()
        while len(lef) != 0:
            ef = lef.pop()
            pdef = pd.ExcelFile(ef)
            head = titlesl.pop()
            # read the dataframe
            df1 = pdef.parse(sheet_name=sh_n, header=None)
            #: justfornow
            if len(df1.columns) == 2:
                df1.columns = [0, head]
            if k != 0:
                df0 = pd.merge(df0, df1, on=0, how="outer")
            else:
                df0 = df1
            k += 1
        print(df0.iloc[1,0])
        if df0.iloc[1,0] == "sum":
            rn = df0.shape[0]
            df0.iloc[1,:], df0.iloc[rn-1,:] = df0.iloc[rn-1,:].copy(), df0.iloc[1, :]

        with pd.ExcelWriter("coalesce.xlsx", mode="a") as writer:
            df0.to_excel(writer, sheet_name=f"{sh_n}")




if __name__ == "__main__":
    coalesce()

