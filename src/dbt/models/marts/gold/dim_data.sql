SELECT
    TO_NUMBER(TO_CHAR(DT, 'YYYYMMDD'))                         AS SK_DATA,
    DT                                                         AS DATA,
    YEAR(DT)                                                   AS ANO,
    QUARTER(DT)                                                AS TRIMESTRE,
    MONTH(DT)                                                  AS MES_NUMERO,
    MONTHNAME(DT)                                              AS MES_NOME,
    WEEKOFYEAR(DT)                                             AS SEMANA_ANO,
    DAY(DT)                                                    AS DIA_MES,
    DAYOFWEEKISO(DT)                                           AS DIA_SEMANA_NUMERO,
    DAYNAME(DT)                                                AS DIA_SEMANA_NOME,
    IFF(DAYOFWEEKISO(DT) IN (6, 7), TRUE, FALSE)              AS FL_FIM_SEMANA,
    DATE_TRUNC('MONTH', DT)                                    AS PRIMEIRO_DIA_MES,
    LAST_DAY(DT, 'MONTH')                                      AS ULTIMO_DIA_MES
FROM (
    SELECT DATEADD(DAY, SEQ4(), '2000-01-01'::DATE) AS DT
    FROM TABLE(GENERATOR(ROWCOUNT => 13149))
)
