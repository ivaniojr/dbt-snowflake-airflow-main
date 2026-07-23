# Execução 05: Avaliação Avançada e Interpretabilidade em ML

## 🎯 Implementation Plan (Planejamento)
O pipeline de ML estava rodando perfeitamente e gravando no MLflow, porém ainda estava restrito às validações simples de Holdout (MSE/MAE).
- **Diagnóstico:** Para auditoria corporativa profunda, precisávamos garantir contra o sobreajuste (Overfitting), estabilidade da semente aleatória (estabilidade k-fold) e explicabilidade de quais features influenciaram as predições.
- **Proposta:**
  1. **K-Fold Cross-Validation**: Usar 5 Folds, realizando o *StandardScaling* por dentro de cada Fold isoladamente (Zero Leakage) e extrair a média e o desvio padrão de (R², MAE e MSE).
  2. **Validação e Early Stopping**: Rastrear a Loss do Treino junto com a Loss de Validação (Holdout interna) a cada época para gerar a curva e provar que as redes não sofreram Overfitting.
  3. **Gráficos de Homocedasticidade**: Gerar *Scatter Plots* para visualizar como os erros (resíduos) se distribuem ao redor da linha do zero.
  4. **Interpretabilidade (Feature Importance)**: Extrair e plotar lado a lado o peso que cada coluna teve no resultado através do método *Permutation Feature Importance*.

---

## ✅ Walkthrough (O que foi entregue)
(A ser preenchido após a finalização da execução).
