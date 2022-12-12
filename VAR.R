source("functions.R")
library(GetBCBData)
library(lubridate)
library(tidyverse)
library(tsibble)
library(forecast)
library(ggplot2)
library(vars)
library(timetk)
## importing -------------

# PIB mensal - Valores correntes - R$ milhões (BCB)
# Taxa de juros - Selic acumulada no mês anualizada base 252 - % a.a.
# Índice Nacional de Preços ao Consumidor Amplo (IPCA) - % a.m.
df_bcb <- GetBCBData::gbcbd_get_series(
  id = c(
    "pib_mensal" = 4380,
    "selic" = 4189,
    "ipca" = 433
  ),
  first.date = lubridate::ymd("2003-12-01"),
  use.memoise = FALSE
) %>%
  tidyr::pivot_wider(
    id_cols = "ref.date",
    names_from = "series.name",
    values_from = "value"
  ) %>%
  dplyr::rename("date" = "ref.date") %>%
  dplyr::mutate(date = tsibble::yearmonth(.data$date))

## visualize ------------------------
df_bcb %>%
  mutate(date = as.Date(date)) %>%
  pivot_longer(cols = pib_mensal:cambio) %>%
  plot_time_series(
  .date_var = date,
  .value = value,
  .facet_vars = name,
  .facet_ncol = 2
  )


## diff --------------
vars_ndiffs <- df_bcb %>%
  dplyr::select(-"date") %>%
  report_ndiffs()

vars_ndiffs

df_bcb %<>%
  dplyr::mutate(
    dplyr::across(
      .cols = vars_ndiffs$variable[vars_ndiffs$ndiffs > 0],
      .fns = ~tsibble::difference(
        x = .x,
        differences = vars_ndiffs$ndiffs[vars_ndiffs$variable == dplyr::cur_column()]
      )
    )
  ) %>%
  tidyr::drop_na()

df_bcb

## graph ---------------
df_bcb %>%
  mutate(date = as.Date(date)) %>%
  pivot_longer(cols = pib_mensal:ipca) %>%
  plot_time_series(
    .date_var = date,
    .value = value,
    .facet_vars = name,
    .facet_ncol = 3
  )

# VAR ----------------
### Estimar nlags ----------------------
lags_var <- vars::VARselect(
  y = df_bcb[-1],
  lag.max = 12,
  type = "const"
)
lags_var
### Estimar modelo VAR---------------
fit_var <- VAR(
  y = df_bcb[-1],
  p = lags_var$selection["AIC(n)"],
  type = "const",
  lag.max = 12,
  ic = "AIC"
)
fit_var

irf_var <- irf(
  x = fit_var,
  impulse = "selic",
  response = "ipca",
  n.ahead = 12
)
irf_var

plot(irf_var)

lags = 1:13

df_irf <- data.frame(irf = irf_var$irf,
                     lower = irf_var$Lower, upper = irf_var$Upper,
                     lags = lags)

colnames(df_irf) <- c('irf', 'lower', 'upper', 'lags')
ggplot(data = df_irf,aes(x=lags,y=irf)) +
  geom_line(aes(y = upper), colour = 'lightblue2') +
  geom_line(aes(y = lower), colour = 'lightblue')+
  geom_line(aes(y = irf), linewidth=.8)+
  geom_ribbon(aes(x=lags, ymax=upper,
                  ymin=lower),
              fill="blue", alpha=.1) +
  xlab("") + ylab("IPCA") +
  ggtitle("Resposta ao Impulso na SELIC") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        plot.margin = unit(c(2,10,2,10), "mm"))+
  geom_line(colour = 'black')+
  scale_x_continuous(breaks=number_ticks(13))+
  theme_bw()

### avaliar -------------------------
# residuo --------------
serial.test(fit_var, lags.pt = 12, type  = "PT.asymptotic")
serial.test(fit_var, lags.pt = 12, type  = "PT.adjusted")
serial.test(fit_var, lags.pt = 12, type  = "BG")
serial.test(fit_var, lags.pt = 12, type  = "ES")
normality.test(fit_var)
arch.test(fit_var, lags.multi = 12)
# decomposição da variância ------------
fevd.fit <- fevd(fit_var)
fevd.fit$pib_mensal
fevd.fit$selic
fevd.fit$ipca
