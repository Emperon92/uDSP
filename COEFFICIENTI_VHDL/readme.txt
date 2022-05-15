MLP_ND_VHDL  -> TRAINING -> ESPORTANO I PARAMETRI MLP QUANTIZZATI DA CARICARE IN MEMORIA DATI SU UDSP NEI FILE DI TESTO (coeff, coeff_beta) 
RVFL_ND_VHDL -> TRAINING -> ESPORTANO I PARAMETRI RVFL QUANTIZZATI DA CARICARE IN MEMORIA DATI SU UDSP NEI FILE DI TESTO (MLP_b1, MLP_b2,MLP_w1,MLP_w2)

in più producono nei file di testo l'input, l'output e il valore dei registri intermedi: MLP (MLP_input, n1_q n2_q, output)    RVFL(input, class, H_q_test, output)
per confrontare con i processi interni della uDSP

test_microDSP -> compara i risultati output_matlab (y_pred prodotto da matlab) e output prodotto da simulazione behavioral uDSP
se corrispondenza 100% i modelli funzionano correttamente. 