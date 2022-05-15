I tre blocchi principali sono FSM,ALU_BLCK,FIFO_CLASSIFIED e WALLACE TREE MULTIPLIER (comprende walltree_func).
Il blocco TOP_DSP contiene i tre blocchi principali e li collega tra di loro
Il blocco wallace_tree_multiplier e wallace_tree_func contengono il codice del moltiplicatore 
Il blocco data memory è la memoria utilizzata per contenere i dati
Il blocck program memory è la memoria che contiene il programma
Il file fifo_classified contiene il registro classificatore di uscita
Il file tb_dsp è il testbench
Il file clock.xdc è il constraint del clock
SENSIPLUS_FIFO_EMA è la memoria che simula i file EMA (da eliminare una volta capito come sincronizzare l'ingresso con il sensiplus)
