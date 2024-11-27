# mcpanel: Implementation of Matrix Completion for Causal Panel Data Methods in Stata

This repository is a work in progress for the Stata implementation of *"Matrix Completion Methods for Causal Panel Data Models"* (Athey et al., 2021).  This is a method for estimating causal effects in panel data settings with by imputing untreated potential outcomes.  The method is based on matrix completion methods.  

Code is currently under construction, and should not be viewed as a complete implementation at this point.  This respository will be updated as code develops.

## Syntax

## Estimator Details
Setting with $N$ units and $T$ time periods.  $Y_{it}(0)$ and $Y_{it}(1)$.  In period $t$ unit $i$ is exposed or not to binary treatment with $W_{it}=1$ indicating exposure; $W_{it}=0$ otherwise.  Observe ($W_{it},Y_{it}$), where realised outcome is $Y_{it}=Y_it(W_it)$.

Observe:  
- $\mathbm{Y}$: Realized outcomes
- $\mathbm{W}$: Treamtn outcomes
- $\mathbm{X}\in\mathcal{R}^{N \times P}$ 
- $\mathbm{Z}\in\mathcal{R}^{T \times Q}$
As well as observe ...


## Examples

Below we show an example based on work in progress.  This uses the Abadie et al. (2010) data on the effect of California's Proposition 99 on cigarette consumption.  This is currently based on arbitrary values for lambda without state and year FEs.  The incorporation of FEs and cross-validation, as well as further code optimisation, is currently in progress.
```s
webuse set www.damianclarke.net/stata/
webuse prop99_example.dta, clear

//California is stcode==3
encode state, gen(stcode)


// Implement the mcpanel estimator (no state year FEs for now)
mcpanel packspercapita treat stcode year, lambda(0.1) maxiter(100000)
```
```
------------------------------------------------------------------------------------------
Matrix Completion with Nuclear Norm Minimization.

> The algorithm converged in 22454 iterations.
> Total time: 5.27 seconds.
> Regularization parameter: lambda = .1.
> Tolerance parameter: tolerance = .00001.

------------------------------------------------------------------------------------------
```

Generate a graph based on code output:
```s
twoway line packspercapita        year if stcode == 3, lcolor(red) lwidth(thick)   ///
    || line packspercapita_mcnnm  year if stcode == 3, lcolor(blue) lwidth(thick)  ///
    xline(1988) legend(order(1 "California" 2 "Matrix Completion") pos(1) ring(0)) ///
    ytitle("Packs per capita")
graph export prop99_mcnnm.png, replace
```
<img src="https://github.com/damiancclarke/mcpanel/blob/main/prop99_mcnmm.png" width="600" height="400">

## References
Susan Athey, Mohsen Bayati, Nikolay Doudchenko, Guido Imbens & Khashayar Khosravi (2021) Matrix Completion Methods for Causal Panel Data Models, Journal of the American Statistical Association, 116:536, 1716-1730, DOI: [10.1080/01621459.2021.1891924](https://doi.org/10.1080/01621459.2021.1891924)

Abadie, A., Diamond, A., & Hainmueller, J. (2010). Synthetic control methods for comparative case studies: Estimating the effect of California's tobacco control program. Journal of the American Statistical Association, 105(490), 493–505. DOI: [10.1198/jasa.2009.ap08746](https://doi.org/10.1198/jasa.2009.ap08746)


## Authors

**Nicolás Bastías Campos**, Universidad de Chile.
 Email: nbastias@fen.uchile.cl

**Damian Clarke**, Universidad de Chile.
 Email:dclarke@fen.uchile.cl
 Website: [http://www.damianclarke.net/](http://www.damianclarke.net/)

