{smcl}
{* *! version 0.0.1 November 25, 2024}
{hline}
{cmd:help mcnnm}{right: mcpanel v0.0.1}
{hline}

{title:Title}

{p 4 4 2}
{cmdab:mcnnm} {hline 2} Matrix Completion with Nuclear Norm Minimization.

{marker syntax}{...}
{title:Syntax}

{p 8 4 2}
{cmd:mcnnm} {it:depvar} {it:treatment} {it:groupvar} {it:timevar}  {ifin} 
			[{cmd:,} {cmd:lambda({it:#})} 
			{cmd:maxiter({it:#})} 
			{cmdab:tol:erance(}{it:#}{cmd:)} 
			{cmd:groupfe} 
			{cmd:timefe}]
			
{synoptset 11 tabbed}{...}
{synopt:{it:depvar}}is the potential outcome to be estimated for the treated unit/periods.{p_end}
{synopt:{it:treatment}}is a binary indicator variable that specifies each unit/period to be treated.{p_end}
{synopt:{it:groupvar}}identifies the panels.{p_end}
{synopt:{it:timevar}}dentifies the times within panels.{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lambda}({it:#})} specifies the lambda regularization parameter for the nuclear norm. The default value is 100.{p_end}
{synopt :{opt maxiter}({it:#})} specifies the maximum number of iterations for the algorithm convergence. The default value is 1000.{p_end}
{synopt :{opt tolerance}({it:#})} specifies the algorithm tolerance stopping rule. The default value is 1e-5.{p_end}
{synopt :{opt groupfe}} optional argument that indicates wheter to estimate fixed unit effects. The default is {it:not} to estimate them.{p_end}
{synopt :{opt timefe}} optional argument that indicates wheter to estimate fixed time effects. The default is {it:not} to estimate them{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mcnnm} implements the Matrix Completion method for causal panel data models introduced by Athey et al. (2021). This method imputes the missing potential outcomes
			of the control group for treated units/periods, where missingness arises from the treatment assignment. Specifically, this method can estimate potential 
			outcomes for the control group in cases where a single unit is treated from an initial adoption date onward, as well as cases where multiple units receive 
			the treatment but adoption dates vary across units. {cmd:mcnnm} command constructs synthetic control groups by imputing missing elements through a low-rank 
			matrix, using regularization and a nuclear norm to characterize the estimator. By accounting for time and group dependencies, the matrix completion with 
			nuclear norm estimator provides insights into what would have happened in the absence of treatment. For more details, see Athey et al. (2021) and ... (...).
			
{pstd}
{cmd:mcnnm} {it:depvar} {it:treatment} {it:groupvar} {it:timevar} command performs the matrix completion with nuclear norm estimator. The {it:depvar} represents the 
			potential outcome for treated units/periods that we aim to estimate. The command requires a {it:treatment} indicator variable (binary) to specify whether 
			each unit/period is treated. Finally, {it:groupvar} and a {it:timevar} must be provided to account for group and time/period dependencies.
					
{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{cmd:lambda}({it:#}) specifies the lambda regularization parameter for the nuclear norm. The default value is 100.

{phang}
{cmd:maxiter}({it:#}) specifies the maximum number of iterations for the algorithm convergence. The default value is 1000.

{phang}
{cmd:tolerance}({it:#}) specifies the algorithm tolerance stopping rule. The default value is 1e-5.

{phang}
{cmd:groupfe} optional argument that indicates wheter to estimate fixed unit effects. The default is {it:not} to estimate them.

{phang}
{cmd:timefe} optional argument that indicates wheter to estimate fixed time effects. The default is {it:not} to estimate them

{marker results}{...}
{title:Stored results}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(lambda)}}regularization parameter used.{p_end}
{synopt:{cmd:r(maxiter)}}maximum iterations used.{p_end}
{synopt:{cmd:r(tolerance)}}convergence tolerance used.{p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Local macros}{p_end}
{synopt:{cmd:r(cmdline)}}command line executed.{p_end}
{synopt:{cmd:r(cmd)}}name of the command.{p_end}

{marker examples}{...}
{title:Examples}


{title:Example with single treated/unit adoption.}
	
Setup 
	
	Importing the dataset
	
	{cmd:. webuse set www.damianclarke.net/stata/}
	
	{cmd:. webuse prop99_example.dta, clear}
	
	{cmd:. encode state, gen(stcode)}
	
	Matrix Completion with Nuclear Norm
	
	{cmd:. mcpanel packspercapita treat stcode year}
	
	Matrix Completion with Nuclear norm with the optimal lambda selected with cross-validation and fixed effects
	
	{cmd:. mcpanel packspercapita treat stcode year, lambda(0.01941918) maxiter(150000) groupfe timefe}
	
	Graph
	
	{cmd:. twoway line packspercapita year if stcode == 3 || line packspercapita_mcnnm year if stcode == 3, xline(1988)}
	

	{title:Example with staggered adoption.}
	
	Setup 
	
	{cmd:. use synth_smoking_stag.dta, clear}
	
	Matrix Completion with Nuclear norm
	
	{cmd:. mcpanel cigsale treat state year}
	
	Matrix Completion with Nuclear norm with the optimal lambda selected with cross-validation
	
	{cmd:. mcpanel cigsale treat state year, lambda(0.01000053) maxiter(440000)}
	
	Graph
	
	{cmd:. twoway line cigsale year if state == 3 || line cigsale_mcnnm year if state == 3, xline(1988)}
	
{marker references}{...}
{title:References}

{pstd}
Athey, S., Bayati, M., Doudchenko, N., Imbens, G., & Khosravi, K. (2021). Matrix Completion Methods for Causal Panel Data Models. {it:Journal of the American Statistical Association, 116(536)}, 1716–1730. 


{title:Authors}

    {opt Nicolás Bastías Campos}, Universidad de Chile.
    . Email: {browse "mailto:nbastias@fen.uchile.cl":nbastias@fen.uchile.cl}
    . Website: {browse "http://nabastias.github.io/"}

    {cmd:Damian Clarke}, Universidad de Chile.
    . Email: {browse "mailto:dclarke@fen.uchile.cl":dclarke@fen.uchile.cl}
    . Website: {browse "http://www.damianclarke.net/"}

{title:Website}

{p 4 8 2}
{opt mcpanel} is maintained at {browse "https://github.com/damiancclarke/mcpanel"} 

{title:Also see}
{p 4 8 2}
{pstd}
{opt mcnnm} is part of the {helpb mcpanel} package. Additionally, you can check {helpb mcnnm_cv} for the Matrix Completion with Nuclear Norm Minimization command with 
cross-validation.
