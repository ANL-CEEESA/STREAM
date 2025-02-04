# -*- coding: utf-8 -*-

# Copyright (C) 2023, UChicago Argonne, LLC
# All Rights Reserved
# Software Name: STRE3AM: Strategic Technology Roadmapping and Energy,
# Economic, and Equity Analysis Model
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
# vim: tabstop=2 shiftwidth=2 expandtab colorcolumn=80 tw=80

# written by David Thierry @dthierry 2023
# readExcelResults.py
# description: load dataframes with the excelt results
#
# log:
# 1-30-23 added some comments
#
#
#80#############################################################################

import sys
import pandas as pd
from typing import Tuple
from generalD import *

__author__ = "David Thierry"

def loadExcelOveralls(shift: bool=False) -> Tuple[dict, float]:
    """read the aggregates of the _effective.xlsx file, which is generated from
    the results.
    """
    excelFileName = getFiles("*_effective.xlsx")
    if not excelFileName:
        raise Exception("not found")
    ef = pd.ExcelFile(excelFileName)
    #b = pd.DataFrame()  # this doesn't work :S
    l = {}
    for name in names:
        count = 0
        kind = kinds[name]
        if max(kind) == 0:
            continue
        for i in range(I):
            print(name, kind)
            r = range(kind[i])
            for k in r:
                suffix = "" if name in ["w", "uw"] else "_" + str(k)
                #: sheet names for w and uw are different
                sheetName = name + "_" + str(i) + suffix
                print(sheetName)
                df = ef.parse(sheet_name=sheetName, index_col=0)
                df = df.drop(columns="Unnamed: 1") # might delete later
                series = df.sum(axis=1) # sum over age
                series.name = sheetName
                if count == 0:
                    b = pd.DataFrame(series)
                else:
                    d = pd.DataFrame(series)
                    b = b.join(d)
                count += 1
        l[name] = b

    d = ef.parse(sheet_name="d", index_col=0)
    d.drop(d.tail(1).index, inplace=True)
    l["demand"] = d
    dmax = d.max()[0]
    if shift:
        for name in names:
            if name == "w":
                continue
            l[name] = l[name].shift(fill_value=0) #: shift by one
    return l, dmax

