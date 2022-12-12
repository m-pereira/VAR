# VAR

Vetores Autorregressivos (VAR) são muito usados por economistas e entendo como uma técnica econométrica muito útil. Nesse projeto busco estimar a Função Impulso Resposta (FIR) que simula um choque positivo na SELIC e como isso se desdobra no IPCA (índice oficial de inflação brasileira), essa ténica é útil para entendermos o efeito da SELIC no IPCA.

```
install.packages("magrittr","GetBCBData", "ipeadatar",
"lubridate", "tidyr", "dplyr", "tsibble", "purrr",
"forecast", "ggplot2", "vars")
```

Nesse projeto inicia-se com a análise visual das séries PIB mensal, Selic e IPCA, as séries não PIB e Selic não são estacionárias, então aplica-se a diferenciação para atender a condição de estacionaridade das séries para aplicação do modelo VAR. As séries em nível podem ser vistas na figura abaixo.


![alt text](https://github.com/m-pereira/VAR/blob/main/TS.png)

Atendendo a condição necessária, avalia-se o número ótimo de defasagens seguindo a estatística AIC. O teste indica que doze defasagens o modelo VAR apresenta o melhor resíduo. Assim estima-se o modelo VAR e a Função Impulso Resposta de um choque na Selic e o impacto no IPCA. A figura mostra que um choque na Selic leva de 8 a 12 meses para reduzir o IPCA, indicando que a economia leva tempo para se ajustar a nova taxa de juros.

![alt text](https://github.com/m-pereira/VAR/blob/main/VAR.png)

Após essa etapa, realiza-se a análise de decomposição da variância e análise de resíduo com testes de normalidade, autocorrelação e heterocedasticidade. Concluí-se que o modelo pode ser melhorado, incorporando variáveis como câmbio e taxa de desemprego que afetam o IPCA, entretanto para o propósito desse projeto, avaliar o impacto somente da Selic no IPCA, dá se por suficiente. Aumentos da Selic são ferramentas para redução na inflação, mas economia é algo complexo e leva tempo para se observar o impacto dessa decisão, um aumento na taxa de juros hoje, reduz a inflação futura, daqui a 8 a 12 meses, não a inflação imediata do próximo mês. 
