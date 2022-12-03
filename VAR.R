source("functions.R")
library(magrittr)
library(GetBCBData)
library(ipeadatar)
library(lubridate)
library(tidyr)
library(dplyr)
library(tsibble)
library(purrr)
library(forecast)
library(ggplot2)
library(vars)

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
  tidyr::pivot_longer(-"date") %>%
  ggplot2::ggplot() +
  ggplot2::aes(x = lubridate::as_date(date), y = value) +
  ggplot2::geom_line() +
  ggplot2::facet_wrap(~name, scales = "free")

## VAR ----------------

lags_var <- vars::VARselect(
  y = df_bcb[-1],
  lag.max = 12,
  type = "const"
)

# Estimar modelo VAR
fit_var <- vars::VAR(
  y = df_bcb[-1],
  p = lags_var$selection["AIC(n)"],
  type = "const",
  lag.max = 12,
  ic = "AIC"
)
fit_var

irf_var <- vars::irf(
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

number_ticks <- function(n) {function(limits) pretty(limits, n)}
ggplot(data = df_irf,aes(x=lags,y=irf)) +
  geom_line(aes(y = upper), colour = 'lightblue2') +
  geom_line(aes(y = lower), colour = 'lightblue')+
  geom_line(aes(y = irf), linewidht=.8)+
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
