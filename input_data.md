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
license: BSD-3 

---

(s:key_data)=
## Key data


| **name**     | **value** |
|--------------|------------|
| n_periods    | 2          |
| n_subperiods | 4          |
| n_loc        | 10         |
| n_rtft       | 5          |
| n_new        | 5          |
| n_fstck      | 2          |
| n_node       | 2          |
| n_mat        | 5          |
| n_link       | 1          |
| yr_subperiod | 5          |
| y0           | 2020       |
| x_ub         | 2          |
| interest     | 0.1        |
| sf_cap       | 0.001      |
| sf_cash      | 1          |
| sf_heat      | 0.001      |
| sf_elec      | 0.001      |
| sf_em        | 0.001      |
| key_node     | 2          |

(s:initial_cap)=
## Initial Capacity

|**c0 (scaled)**|
|--------------|
| 0.074025541  |
| 0.088821461  |
| 0.069424165  |
| 0.071001601  |
| 0.078500753  |
| 0.055332288  |
| 0.081475707  |
| 0.069308589  |
| 0.077918123  |
| 0.096303537  |



| **(1, 1)**  | **(2, 1)**  | **(3, 1)**  | **(4, 1)**  | **(5, 1)**  | **(1, 2)**  | **(2, 2)**  | **(3, 2)**  | **(4, 2)**  | **(5, 2)**  |
|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|--------------|
| 2.999972419 | 2.849973798 | 2.999972419 | 5.624349101 | 3.899964145 | 0.299997242 | 0.28499738  | 0.299997242 | 0.474955687 | 0.389996415  |
| 2.999436155 | 2.849464347 | 2.999436155 | 5.622666717 | 3.899267002 | 0.299943616 | 0.284946435 | 0.299943616 | 0.474825653 | 0.3899267    |
| 3.000007336 | 2.850006969 | 3.000007336 | 5.624593399 | 3.900009537 | 0.300000734 | 0.285000697 | 0.300000734 | 0.474973138 | 0.390000954  |
| 3.000121971 | 2.850115873 | 3.000121971 | 5.625120658 | 3.900158563 | 0.300012197 | 0.285011587 | 0.300012197 | 0.47501211  | 0.390015856  |
| 2.999826365 | 2.849835047 | 2.999826365 | 5.626016088 | 3.899774275 | 0.299982637 | 0.284983505 | 0.299982637 | 0.475061951 | 0.389977427  |
| 2.999571372 | 2.849592803 | 2.999571372 | 5.625140256 | 3.899442784 | 0.299957137 | 0.28495928  | 0.299957137 | 0.474995063 | 0.389944278  |
| 3.000652409 | 2.850619789 | 3.000652409 | 5.624912544 | 3.900848132 | 0.300065241 | 0.285061979 | 0.300065241 | 0.475015917 | 0.390084813  |
| 3.0004247   | 2.850403465 | 3.0004247   | 5.626174002 | 3.90055211  | 0.30004247  | 0.285040346 | 0.30004247  | 0.475092423 | 0.390055211  |
| 2.999922867 | 2.849926724 | 2.999922867 | 5.624550774 | 3.899899728 | 0.299992287 | 0.284992672 | 0.299992287 | 0.474967481 | 0.389989973  |
| 2.999992857 | 2.849993214 | 2.999992857 | 5.624385476 | 3.899990714 | 0.299999286 | 0.284999321 | 0.299999286 | 0.474958794 | 0.389999071  |


| demand     |
|------------|
| 0.60968941 |
| 0.69677828 |
| 0.78386715 |
| 0.87095601 |
| 0.95804488 |
| 1.04513375 |
| 1.13222262 |
| 1.21931149 |
|            |
|            |



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
