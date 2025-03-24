---
title: Data Input
subject: Case-stude
subtitle: A short description of an input data file.
short_title: Data Input
authors:
  - name: David Thierry 
    affiliations:
      - Energy Systems and Infrastructure Analysis.
  - name: Sarang Supekar
    affiliations:
      - Energy Systems and Infrastructure Analysis.
license: BSD-3-Clause 
---

The prototype case study was created to show the functionality of `stre3am`.
This page illustrates the typical form of some of the input data, as well as a
short description of all the data required. This will reference the excel
spreadsheet `f0.xlsx` which contains all inputs for the model.

(s:key_data)=
## Key data

The *key data* refers to information that is used to construct every other data
structure of the model. For example, the cardinality of the period and subperiod
sets ({math}`\mathcal{P}` & {math}`\mathcal{P}_1`), location
({math}`\mathcal{L}`), retrofit and new technology sets ({math}`\mathcal{K}_r` &
{math}`\mathcal{K}_n`), etc.

:::{table} Key data sheet.
:label: tab:key_data
:align: center
| **name**     | **value**  | **Description** |
|--------------|------------|-----------------|
| n_periods    | 2          |number of periods|
| n_subperiods | 4          |number of subperiods|
| n_loc        | 10         |number of locations|
| n_rtft       | 5          |number of retrofit tech.|
| n_new        | 5          |number of new plant tech.|
| n_fstck      | 2          |number of feedstocks|
| n_node       | 2          |number of process node|
| n_mat        | 5          |number of materials|
| n_link       | 1          |number of edges|
| yr_subperiod | 5          |number of year/subperiods|
| y0           | 2020       |initial year|
| x_ub         | 2          |expansion units upper bound|
| interest     | 0.1        |interest rate|
| sf_cap       | 0.001      |capacity scaling factor|
| sf_cash      | 1          |cash scaling factor|
| sf_heat      | 0.001      |heat scaling factor|
| sf_elec      | 0.001      |electric scaling factor|
| sf_em        | 0.001      |emission scaling factor|
| key_node     | 2          |key node|
:::

The previous table also contains floating point values for parameters like
scaling factors (`sf_`), etc. 

(s:r-t-l-map)=
## Row to location mapped arrays 

Several parameters are indexed by location. In this example,
{math}`|\mathcal{L}|=10`, thus data like the *initial capacity* is given as a
column vector with 10 rows. I.e.,

:::{table} Initial capacity
:label: tab:initcap
:align: center
|**location**|**c0 (scaled)**|
|----|--------------|
|1| 0.074025541  |
|2| 0.088821461  |
|3| 0.069424165  |
|4| 0.071001601  |
|5| 0.078500753  |
|6| 0.055332288  |
|7| 0.081475707  |
|8| 0.069308589  |
|9| 0.077918123  |
|10| 0.096303537  |
:::

The mapping of row to location is the preferred layout in `stre3am`.
Multi-dimensional parameters, e.g., the retrofit electricity intensity factor
{math}`\mathtt{r_u}_{kln}` &mdash;which has 3 dimensions, technology, location and
node&mdash; has a row mapped to location, and uses columns for each combination of
technology and node. For example, in the next table {math}`|\mathcal{K}_r|=5`
and {math}`|\mathcal{N}|=2`, which yields 10 columns.

:::{table} Electricity intensity factor
:label: tab:u
:align: center
|(retr.,node)| **(1, 1)**  | **(2, 1)**  | **(3, 1)**  | **(4, 1)**  | **(5, 1)**  | **(1, 2)**  | **(2, 2)**  | **(3, 2)**  | **(4, 2)**  | **(5, 2)**  |
|------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|
|l=1| 2.999972419 | 2.849973798 | 2.999972419 | 5.624349101 | 3.899964145 | 0.299997242 | 0.28499738  | 0.299997242 | 0.474955687 | 0.389996415  |
|l=2| 2.999436155 | 2.849464347 | 2.999436155 | 5.622666717 | 3.899267002 | 0.299943616 | 0.284946435 | 0.299943616 | 0.474825653 | 0.3899267    |
|l=3| 3.000007336 | 2.850006969 | 3.000007336 | 5.624593399 | 3.900009537 | 0.300000734 | 0.285000697 | 0.300000734 | 0.474973138 | 0.390000954  |
|l=4| 3.000121971 | 2.850115873 | 3.000121971 | 5.625120658 | 3.900158563 | 0.300012197 | 0.285011587 | 0.300012197 | 0.47501211  | 0.390015856  |
|l=5| 2.999826365 | 2.849835047 | 2.999826365 | 5.626016088 | 3.899774275 | 0.299982637 | 0.284983505 | 0.299982637 | 0.475061951 | 0.389977427  |
|l=6| 2.999571372 | 2.849592803 | 2.999571372 | 5.625140256 | 3.899442784 | 0.299957137 | 0.28495928  | 0.299957137 | 0.474995063 | 0.389944278  |
|l=7| 3.000652409 | 2.850619789 | 3.000652409 | 5.624912544 | 3.900848132 | 0.300065241 | 0.285061979 | 0.300065241 | 0.475015917 | 0.390084813  |
|l=8| 3.0004247   | 2.850403465 | 3.0004247   | 5.626174002 | 3.90055211  | 0.30004247  | 0.285040346 | 0.30004247  | 0.475092423 | 0.390055211  |
|l=9| 2.999922867 | 2.849926724 | 2.999922867 | 5.624550774 | 3.899899728 | 0.299992287 | 0.284992672 | 0.299992287 | 0.474967481 | 0.389989973  |
|l=10| 2.999992857 | 2.849993214 | 2.999992857 | 5.624385476 | 3.899990714 | 0.299999286 | 0.284999321 | 0.299999286 | 0.474958794 | 0.389999071  |
:::


## Row to time-slice mapped data

A *limited* amount of input data is indexed by time-slice. This is due to their
time-dependency. For example the overall demand changes from time-slice to
time-slice yielding an array as follows:

:::{table} Overall demand 
:label: tab:demand
:align: center
|(per,subp)|time slice| demand     |
|----------|----------|------------|
|(1,1)     |1| 0.60968941 |
|(1,2)     |2| 0.69677828 |
|(1,3)     |3| 0.78386715 |
|(1,4)     |4| 0.87095601 |
|(2,1)     |5| 0.95804488 |
|(2,2)     |6| 1.04513375 |
|(2,3)     |7| 1.13222262 |
|(2,4)     |8| 1.21931149 |
:::

(s:sheet_ref)=
## Sheet name reference

The input data spreadsheet `f0.xlsx` has all the relevant information for the
prototype case study of `stre3am`. The following table is a description of the
sheets/parameters involved.

| **Sheet name**   | **description**                             |
|------------------|---------------------------------------------|
| key              | Key parameters                              |
| n_rfu            | number of fuels (retrofit)                  |
| n_nfu            | number of fuels (new)                       |
| c0               | initial capacity                            |
| e_C              | expansion factor                            |
| e_c_ub           | expansion upper bound                       |
| e_loanFact       | expansion loan factor                       |
| e_l_ub           | expansion loan ub                           |
| e_Ann            | expansion annuity factor                    |
| e_ann_ub         | expansion annuity ub                        |
| e_ladd_ub        | expansion loan add ub                       |
| e_loan_ub        | expansion loan ub                           |
| e_pay_ub         | expansion payment ub                        |
| r_filter         | retrofit technology filter                  |
| r_cp_ub          | retrofit capacity ub                        |
| r_cpb_ub         | retrofit installed capacity ub              |
| r_c_H            | retrofit heat factor                        |
| r_rhs_H          | retrofit heat rhs                           |
| r_eh_ub          | retrofit heat ub                            |
| r_c_F            | retrofit fuel factor                        |
| r_rhs_F          | retrofit fuel rhs                           |
| r_ehf_ub         | retrofit fuel heat ub                       |
| r_c_U            | retrofit electricity factor                 |
| r_rhs_U          | retrofit electricity rhs                    |
| r_c_UonSite      | retrofit elec. Onsite                       |
| r_u_ub           | retrofit electricity ub                     |
| r_c_cpe          | retrofit process emission factor            |
| r_rhs_cpe        | retrofit process emission rhs               |
| r_cpe_ub         | retrofit process emission ub                |
| r_c_Fe           | retrofit fuel emission                      |
| r_c_Fgenf        | retrofit onsite fuel emission               |
| r_u_ehf_ub       | retrofit onsite electricity fuel ub         |
| r_c_Hr           | retrofit onsite electricty heat rate        |
| r_fu_e_ub        | retrofit fuel emission ub                   |
| r_u_fu_e_ub      | retrofit onsite electricty fuel emission ub |
| r_ep0_ub         | retrofit overall emissions                  |
| r_chi            | retrofit emission capture factor            |
| r_ep1ge_ub       | retrofit emitted ub                         |
| r_sigma          | retrofit emission storage factor            |
| r_ep1gce_ub      | retrofit emission captured emitted ub       |
| r_ep1gcs_ub      | retrofit emission captured storaged ub      |
| r_c_fOnm         | retrofit fixed o&m factor                   |
| r_rhs_fOnm       | retrofit fixed o&m rhs                      |
| r_cfonm_ub       | retrofit fixed ub                           |
| r_c_vOnm         | retrofit variable o&m factor                |
| r_rhs_vOnm       | retrofit rhs o&m rhs                        |
| r_cvonm_ub       | retrofit variable o&m ub                    |
| r_e_c_ub         | retrofit expansion capacity                 |
| r_loanFact       | retrofit loan factor                        |
| r_l0_ub          | retrofit loan ub                            |
| r_le_ub          | retrofit expansion ub                       |
| r_Ann            | retrofit annuity factor                     |
| r_ann0_bM        | retrofit annuity ub                         |
| r_anne_bM        | retrofit annuity expansion ub               |
| r_l0add_bM       | retrofit loan added ub                      |
| r_leadd_bM       | retrofit expansion loan ub                  |
| r_loan_ub        | retofit loan ub                             |
| r_pay0_ub        | retrofit payment ub                         |
| r_paye_ub        | retrofit expansion ub                       |
| r_c_Fstck        | retrofit feedstock factor                   |
| r_rhs_Fstck      | retrofit feedstock ub                       |
| r_fstck_ub       | retrofit feedstock ub                       |
| r_Kmb            | retrofit material ratio (by node)           |
| r_x_in_ub        | retrofit input material ub (by node)        |
| r_x_out_ub       | retrofit output material ub (by node)       |
| r_c_upsein_rate  | retrofit upstream emission rate (by node)   |
| r_ups_e_mt_in_ub | retrofit upstream emission ub (by node)     |
| n_filter         | new technology filter                       |
| n_cp_bM          | new capacity ub                             |
| n_c0_bM          | new installed capacity ub                   |
| n_c0_lo          | new installed capacity lb                   |
| n_loanFact       | new loan factor                             |
| n_l_bM           | new loan ub                                 |
| n_Ann            | new annuity factor                          |
| n_ann_bM         | new annuity ub                              |
| n_ladd_bM        | new added loan ub                           |
| n_loan_bM        | new loan ub                                 |
| n_pay_bM         | new payment ub                              |
| n_c_H            | new heat factor                             |
| n_rhs_H          | new heat rhs                                |
| n_eh_ub          | new heat ub                                 |
| n_c_F            | new fuel factor                             |
| n_rhs_F          | new fuel rhs                                |
| n_ehf_ub         | new fuel heat factor                        |
| n_c_U            | new electricty factor                       |
| n_rhs_U          | new electricty rhs                          |
| n_c_UonSite      | new electricity onsite factor               |
| n_u_ub           | new electricity ub                          |
| n_c_cpe          | new process emission factor                 |
| n_rhs_cpe        | new process emission rhs                    |
| n_cpe_ub         | new process emission ub                     |
| n_c_Fe           | new fuel emission factor                    |
| n_c_Fgenf        | new onsite elec. fuel emission factor       |
| n_u_ehf_ub       | new onsite fuel emission ub                 |
| n_c_Hr           | new onsite heat rate                        |
| n_fu_e_ub        | new fuel emission ub                        |
| n_u_fu_e_ub      | new onsite elec. Fuel emission ub           |
| n_ep0_bM         | new overall emission ub                     |
| n_chi            | new emission capture factor                 |
| n_ep1ge_bM       | new emission emitted ub                     |
| n_sigma          | new emission storage factor                 |
| n_ep1gce_bM      | new emission captured emitted ub            |
| n_ep1gcs_bM      | new emission captured storaged ub           |
| n_c_fOnm         | new fixed o&m factor                        |
| n_rhs_fOnm       | new fixed rhs                               |
| n_cfonm_bM       | new fixed o&m ub                            |
| n_c_vOnm         | new variable o&m factor                     |
| n_rhs_vOnm       | new variable o&m ub                         |
| n_cvonm_bM       | new variable o&m ub                         |
| n_c_Fstck        | new feedstock factor                        |
| n_rhs_Fstck      | new feedstock rhs                           |
| n_fstck_ub       | new feedstock ub                            |
| n_Kmb            | new material ratio (by node)                |
| n_x_in_ub        | new input material ub (by node)             |
| n_x_out_ub       | new output material ub (by node)            |
| n_c_upsein_rate  | new upstream emission rate (by node)        |
| n_ups_e_mt_in_ub | new upstream emission ub (by node)          |
| c_u_cost         | electricity cost                            |
| c_r_ehf_cost     | retrofit fuel cost                          |
| c_n_ehf_cost     | new fuel cost                               |
| c_cts_cost       | capture and storage cost                    |
| c_xin_cost       | input material cost                         |
| o_cp_ub          | existing capacity ub                        |
| o_cpe_bM         | existing emission ub                        |
| o_u_ub           | existing electricity ub                     |
| o_ehf_ub         | existing fuel ub                            |
| o_ep0_bM         | existing overall emission ub                |
| o_ep1ge_bM       | existing emission emitted ub                |
| o_ep1gce_bM      | existing emission captured ub               |
| o_ep1gcs_bM      | existing emission storaged captured ub      |
| o_ups_e_mt_in_ub | existing upstream material emission ub      |
| o_pay_bM         | existing payment ub                         |
| o_cfonm_bM       | existing fixed o&m ub                       |
| o_cvonm_bM       | existing variable o&m ub                    |
| o_fstck_ub       | existing feedstock ub                       |
| o_x_in_ub        | existing input material ub                  |
| o_x_out_ub       | existing output material ub                 |
| t_ret_c_bM       | retirement cost ub                          |
| t_loan_bM        | total loan ub                               |
| r_loan0          | initial loan                                |
| discount         | discount                                    |
| demand           | demand                                      |
| co2_budget       | emission budget                             |
| GcI              | grid carbon intensity                       |
| node_mat         | node-material matrix                        |
| skip_mb          | skip node mass balance                      |
| input_mat        | input material flag                         |
| output_mat       | output material flag                        |
| links_list       | node edges list                             |
| ckey             | node key material                           |
| nd_en_fltr       | node energy flag                            |
| nd_em_fltr       | node emission flag                          |
| r_Kkey_j         | retrofit key material                       |
| n_Kkey_j         | new key material                            |
| min_cpr          | node minimum capacity factor                |
| fuel_names       | fuel names                                  |
| units            | unit names                                  |
| RF_label         | retrofit labels                             |
| NW_label         | new labels                                  |
