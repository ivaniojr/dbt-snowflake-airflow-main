# Dashboard Metabase — Acompanhamento de Previsões de Tarefas (MUNKA)

Este documento descreve o dashboard construído no Metabase para acompanhamento de
previsto x realizado das tarefas do projeto MUNKA, conforme especificado em
`DASHBOARD_METABASE.md`. Todo o conteúdo usa **dados reais** do Snowflake — nenhum
número foi inventado ou mockado.

## 1. Como acessar

1. Subir a stack (ao menos o serviço `metabase`):
   ```
   cd airflow && docker compose up -d metabase
   ```
2. Acessar `http://localhost:3000`.
3. Login com a conta de administrador criada no setup inicial (ver
   `CONEXAO_METABASE_SNOWFLAKE.md` na raiz do projeto para detalhes da conexão).
4. Navegar até a coleção **"MUNKA - Acompanhamento de Previsões de Tarefas"** e abrir
   o dashboard **"Acompanhamento de Previsões de Tarefas"**.

A conexão Snowflake usada ("Snowflake - MUNKA") aponta para a conta `sfedu02-gfb24387`,
usuário `DRAGON`, warehouse `DRAGON_WH`, banco `DRAGON_DB`, autenticando via chave RSA
(`rsa_key.p8`), com acesso restrito aos schemas `MUNKA_GOLD` e `MUNKA_ML`.

## 2. Fontes de dados utilizadas

| Tabela | Papel |
|---|---|
| `MUNKA_GOLD.FCT_TAREFA` | Fato de tarefas — horas executadas (`HORAS_EXECUTADAS`), datas, valor faturado (`VALOR_FATURADO`), chave para regra (`SK_REGRA`) e projeto (`SK_PROJETO`). |
| `MUNKA_GOLD.DIM_REGRA` | Regra de negócio de estimativa de horas por complexidade/serviço/cargo/nível, incluindo `HET_MAX` ("Horas Estimadas Teto") e `COMPLEXIDADE`. |
| `MUNKA_GOLD.DIM_PROJETO` | Nome do projeto, usado na tabela de maiores diferenças. |

Todas as consultas filtram por `HORAS_EXECUTADAS IS NOT NULL AND HET_MAX IS NOT NULL`,
garantindo que só entrem tarefas com dado real de execução **e** de estimativa. Isso
resulta em **159.608 tarefas** analisadas (de um total de 161.968 na fato).

Os arquivos-fonte de cada consulta estão versionados em [`metabase/queries/`](../../metabase/queries/).

## 3. Limitação importante: o que é "previsto" neste dashboard

**As previsões do modelo de Machine Learning treinado (`src/ml/batch_inference.py`)
não são persistidas no Snowflake** — elas são geradas sob demanda e salvas apenas em
um CSV local (`novas_previsoes.csv`), fora do warehouse. Isso significa que não existe,
hoje, nenhuma tabela no Snowflake com a saída do modelo de ML para ser comparada
com o realizado.

Por isso, o "previsto" usado neste dashboard é `DIM_REGRA.HET_MAX` — a estimativa de
horas da **regra de negócio** (que, aliás, é uma das 15 features de entrada do próprio
modelo de ML). Isto é uma medida real, existente e íntegra no Snowflake, mas **não é
o mesmo que a previsão do modelo treinado**. As métricas MAE/RMSE/R² exibidas no
dashboard (0.64 / 3.19 / 0.38) avaliam a acurácia dessa **regra de estimação**, não a
acurácia do modelo de ML em produção.

Adicionalmente, o `RELATORIO_TECNICO_PROJETO_MUNKA.md` reporta MAE=2.0449,
RMSE=2.5902 e R²=0.9114 para o modelo de ML — esses números vêm de um dataset de
avaliação gerado com `np.random` em `export_evaluation_dataset.py` (dados mockados
para fins de demonstração do pipeline de avaliação), **não** de previsões reais
persistidas. Portanto eles não são reproduzidos neste dashboard, que trabalha
exclusivamente com dados genuínos de Snowflake.

## 4. Limitação: custo previsto

O modelo de dados não possui uma tarifa (`custo_hora`) por cargo/serviço para
calcular um "custo previsto" a partir de `HET_MAX`. Conforme instrução explícita do
escopo do projeto (não inventar taxas), o dashboard exibe apenas o **custo realizado**
(`SUM(VALOR_FATURADO)`), sem nenhuma comparação "previsto x realizado" para custo.

## 5. Estrutura do dashboard (aba "Camada Gold - Previsto x Realizado")

### KPIs (linha superior)
| Card | Fórmula | Fonte |
|---|---|---|
| KPI - Tarefas Analisadas | `COUNT(*)` | `FCT_TAREFA` ⋈ `DIM_REGRA` |
| KPI - Horas Realizadas | `SUM(HORAS_EXECUTADAS)` | `FCT_TAREFA` |
| KPI - Horas Previstas | `SUM(HET_MAX)` | `DIM_REGRA` |
| KPI - Erro Medio Absoluto | `AVG(ABS(HET_MAX - HORAS_EXECUTADAS))` | `FCT_TAREFA` ⋈ `DIM_REGRA` |
| KPI - Custo Realizado | `SUM(VALOR_FATURADO)` | `FCT_TAREFA` |
| Métricas do Modelo - MAE/RMSE/R² | ver seção 3 | `FCT_TAREFA` ⋈ `DIM_REGRA` |

### Gráficos
| Card | Tipo | Descrição |
|---|---|---|
| Gráfico - Previsto x Realizado por Complexidade | Barras | Média de horas previstas vs. realizadas, agrupado por `COMPLEXIDADE`. |
| Gráfico - Erro por Complexidade | Barras | Erro médio (com sinal) e erro médio absoluto por `COMPLEXIDADE`. |
| Gráfico - Evolução Temporal | Linhas | Soma mensal de horas previstas vs. realizadas (por `DATA_FIM`, 49 meses). |
| Gráfico - Distribuição do Erro | Barras | Histograma da diferença (previsto − realizado) em 5 faixas. |

### Tabela
| Card | Descrição |
|---|---|
| Tabela - Maiores Diferenças | Top 15 tarefas com maior erro absoluto, com nome da tarefa, projeto, complexidade, horas previstas/realizadas e erro. |

## 6. Filtros do dashboard

- **Complexidade** (Texto/Categoria, múltipla escolha): conectado às cards "KPI - Tarefas
  Analisadas" e "KPI - Horas Realizadas" via Field Filter na coluna `DIM_REGRA.COMPLEXIDADE`.
- **Período** (Date picker, "All Options"): conectado às mesmas duas cards via Field
  Filter na coluna `FCT_TAREFA.DATA_FIM`.

Os demais cards usam parâmetros de template opcionais (`[[AND {{...}}]]`) que não
quebram a query quando os filtros do dashboard não estão conectados a eles — a
sintaxe de colchete duplo do Metabase omite a cláusula inteira quando a variável não
tem valor. Por limitação de tempo/automação, apenas os dois cards acima têm Field
Filter completamente configurado; os demais permanecem com os valores completos
(sem filtro aplicado), mas ainda assim com dados 100% reais.

## 7. Achados / narrativa de apoio à decisão

- A regra de estimação de horas (`HET_MAX`) tem erro médio absoluto de **0,64 horas**
  por tarefa sobre ~159 mil tarefas — um valor baixo em termos absolutos.
- O R² de **0,38** indica que, apesar do erro médio baixo, a regra explica apenas
  ~38% da variância do tempo realmente executado — há tarefas com desvios grandes
  que "puxam" o RMSE (3,19h) bem acima do MAE.
- Por complexidade, o erro médio absoluto cresce com a complexidade declarada
  (maior em "Alta", menor em "Única"), sugerindo que a regra de estimativa é menos
  confiável para tarefas mais complexas — candidatas naturais a um modelo de ML mais
  sofisticado (o que já está em desenvolvimento, mas ainda não persiste previsões no
  Snowflake, ver seção 3).
- A tabela de maiores diferenças permite auditoria pontual das tarefas com maior
  desvio absoluto entre estimativa e execução, útil para investigação de causa-raiz.

## 8. Arquitetura

Este dashboard foi construído **inteiramente dentro do Metabase**, sem:
- criação de novas tabelas/views no Snowflake;
- alterações no pipeline Airflow/dbt existente;
- qualquer dado sintético/mockado.

Toda consulta usa apenas SQL nativo sobre `MUNKA_GOLD.FCT_TAREFA`, `MUNKA_GOLD.DIM_REGRA`
e `MUNKA_GOLD.DIM_PROJETO`, já existentes no warehouse.

## 9. Camada MUNKA_ML (aba "Camada ML - Features do Modelo")

Além da camada `MUNKA_GOLD`, o dashboard inclui uma segunda aba que consulta
diretamente a tabela `MUNKA_ML.ML_TAREFA_FEATURES` — o "tabelão" (*wide table*)
desnormalizado que alimenta o treinamento do modelo de ML (15 features de entrada +
variáveis-alvo `HORAS_EXECUTADAS`/`TOTAL_UST`). Todas as consultas usam SQL nativo
direto sobre essa tabela, sem joins com a camada Gold.

### 9.1. KPIs
| Card | Fórmula | Valor real |
|---|---|---|
| ML - KPI Registros na Camada | `COUNT(*)` | 161.968 |
| ML - KPI Score Qualidade Media | `AVG(SCORE_QUALIDADE_EVIDENCIA)` | 13.8 |
| ML - KPI Tarefas Bugfix | `SUM(FL_IS_BUGFIX)` | 42.436 |
| ML - KPI UST Media | `AVG(TOTAL_UST)` | 4.41 |

### 9.2. Gráficos e tabela

Layout (de cima para baixo): "Score e Horas por Complexidade" e "Envolvimento por
Área" lado a lado na mesma linha; "Evidências Técnicas" e "Maiores Scores de
Evidência" ocupando toda a largura horizontal, cada um em sua própria linha.

| Card | Descrição |
|---|---|
| Gráfico ML - Score e Horas por Complexidade | Score médio de qualidade da evidência e horas médias executadas, por `NOME_COMPLEXIDADE`. O score cresce com a complexidade (11.2 em "Única" até 33.0 em "Alta"), assim como as horas médias (2.2h até 8.6h) — evidência mais rica tende a acompanhar tarefas mais complexas. |
| Gráfico ML - Envolvimento por Área | Contagem de tarefas por área técnica envolvida (`FL_ENVOLVE_FRONTEND`, `FL_ENVOLVE_BACKEND`, `FL_ENVOLVE_DADOS`). Backend concentra a maior parte (~38 mil), seguido de Frontend e Dados. |
| Gráfico ML - Evidências Técnicas | Contagem de tarefas por tipo de evidência técnica extraída (`TEM_CODIGO`, `TEM_SQL`, `TEM_COMMIT`, `FL_TEM_PULL_REQUEST`, `FL_IS_BUGFIX`). `TEM_COMMIT` domina (147.740 tarefas, ~91%); Pull Request é raríssimo (13 casos). |
| Tabela ML - Maiores Scores de Evidência | Top 15 tarefas com maior `SCORE_QUALIDADE_EVIDENCIA`, com projeto, complexidade, horas executadas e UST. |

Estes cards não têm Field Filter conectado aos filtros de dashboard (Complexidade/
Período são específicos da aba `MUNKA_GOLD`); todos exibem o conjunto completo de
161.968 registros da camada ML.

## 10. Evidência visual

Ver [`dashboard.png`](dashboard.png) (aba "Camada Gold - Previsto x Realizado", camada
`MUNKA_GOLD`) e [`dashboard_ml.png`](dashboard_ml.png) (aba "Camada ML - Features do
Modelo", camada `MUNKA_ML`) — screenshots reais do dashboard renderizado com dados ao
vivo do Snowflake (capturados via link público temporário do Metabase, removido em
seguida por segurança).
