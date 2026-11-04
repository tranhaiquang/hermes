Champion-row formula templates (copy from the last data row of the prior month's adjusted template).

## Sheet 1 `1.Input production result `
- Columns 1-13: A Month, B Date, C Shift, D Machine ("SEMI n"), E Model, F Component,
  G Model+Component (=E&F), H Good Output (value = SUM QTY), I Total Output (=H+U),
  J Cycle Time (VLOOKUP to sheet 5 D:E, "No Matching" if missing), K Operating time
  (=IF(G="","",I*J/3600)), L Availability (=IF(OR(H="",H=0),"",H*J/3600)),
  M Performance (=IF(H=0,"",U*J/3600)).
- Columns 14-20: N-Q1, O-Q2, P-Q3, Q-Q4, R-Q5, S-Q6, T-Q7 (defect values only Q1/Q2/Q3/Q4/Q7 used;
  empty cells stay empty).
- Column 21 (U): defect count =SUM(N{r}:T{r}).

## Sheet 2 `2. Input downtime`
- A Month (=IF(B="","",MONTH(B))), B Date, C Shift, D Machine, E Machine number,
  F Base =IF(E="","",IF(OR(C=1,C=2),30,45)),
  Q =SUM(F:P)/60, R =E-Q (=7.5 h for shift 1/2).
- AB =SUM(S:AA)/60 (changeover total), AC/C2/C1 11-45,
  AF =SUM(AC:AE)/60,
  AP =SUM(AG:AO)/60 (technical total),
  AQ =SUM(AB,AF,AP) (total planned h),
  AR =SUMIFS(sheet1 K, sheet1 B, sheet2 B, sheet1 C, sheet2 C, sheet1 D, sheet2 D)
      (operating time),
  AS =R-AQ, AT =SUMIFS(sheet1 H,...), AU =SUMIFS(sheet1 I,...),
  AV =IFERROR((R-AQ)/R,""), AW =IFERROR(AR/AS,""),
  AX =IFERROR(AT/AU,0), AY =IF(AV=0,0%,IFERROR(AV*AW*AX,"")).

## Sheet 5 `5. Standard CT`
- A No (sequential), B Model, C Component, D =B&C, E Cycle time (sec).

## Defect statistics (historical Jan-Jun pattern)
- H-bin incidence -> defect incidence: <300 -> 4.5%; 300-800 -> 58.7%;
  800-1500 -> 96.5%; 1500-2500 -> 96.2%; >2500 -> 96.3%.
- Defect count U resampled from the matching H bin's historical distribution;
  one defect column ~95.5%, two ~3.4%, three ~1.1%; only Q1/Q2/Q3/Q4/Q7 used.
- Aug/Sept simplification: defect rate ~1% of H, whole numbers min 11,
  spread over 1-2 of Q1-Q4/Q7.