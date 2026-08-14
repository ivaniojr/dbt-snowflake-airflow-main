-- KPI: quantidade de tarefas sinalizadas como correção de bug (feature FL_IS_BUGFIX)
SELECT SUM(FL_IS_BUGFIX) AS QTD_BUGFIX
FROM MUNKA_ML.ML_TAREFA_FEATURES
