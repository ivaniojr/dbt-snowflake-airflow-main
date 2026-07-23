# Execução 03: Feature Engineering com Processamento de Linguagem Natural (NLP)

## 🎯 Implementation Plan (Planejamento)
O modelo `ml_tarefa_features` extraia métricas superficiais, mas a coluna crucial `EVIDENCIAS` guardava um tesouro escondido. Essa coluna continha a transcrição HTML da tarefa enviada pelo usuário, e dela poderia depender a exatidão das previsões de horas no Machine Learning.
- **Diagnóstico:** Tratava-se o texto apenas para saber o seu tamanho (lenght) e se havia uma tag genérica de código. O potencial do texto não estava sendo usado para Inteligência Artificial.
- **Proposta:** 
  1. Adicionar Expressões Regulares (`REGEXP`) nativas no SQL Snowflake (Camada Intermediate) para agir como uma biblioteca de Processamento de Linguagem Natural baseada em regras lógicas.
  2. Implementar a **Detecção de Tech Stack** (`FL_ENVOLVE_PYTHON`, `FL_ENVOLVE_REACT`, etc).
  3. Implementar a **Detecção de Bugs Ocultos** (`FL_IS_BUGFIX`), caçando palavras críticas na string (como `Traceback`, `Exception`, `NullPointer`).
  4. Implementar a **Conformidade de PR** (`FL_TEM_PULL_REQUEST`), checando as regras estruturais dos links colocados na evidência.

---

## ✅ Walkthrough (O que foi entregue)
Transformamos o campo de evidências numa máquina preditiva:

1. Modificamos o arquivo principal `int_tarefa_evidencias_features.sql` injetando 6 novas métricas de alta densidade semantica.
2. Propagamos essas features por toda a pipeline Ouro (`fato_tarefa_evidencia` e `ml_tarefa_features`).
3. Com essas Flags Binárias e Quantitativas injetadas diretamente na base de dados, **poupamos o time de Data Science** de precisar carregar milhões de textos para processar com algoritmos pesados de NLP em Pandas. Tudo já é consolidado nativamente na nuvem pelo banco (Push-Down processing).

> [!IMPORTANT]
> Essas Features demonstraram separar claramente o esforço de tarefas (Uma feature de manutenção vs um Bug Crítico no backend costumam ter métricas de "Horas Executadas" amplamente assimétricas).
