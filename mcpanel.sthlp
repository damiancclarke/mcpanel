{smcl}
{* *! version 0.0.1 November 4, 2024}
{title:Title}

{p 4 4 2}
{cmdab:mcpanel} {hline 2} Matrix Completion estimation

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{opt mcpanel} {opt depvar} {opt groupvar} {opt timevar} {opt treatment} {ifin}{cmd:,} [{it:options}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt level}({it:#})} specifies the confidence level, as a percentage, for confidence intervals. The default is the level set by set level (which by default is level(95)).{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:mcpanel} implements the Matrix Completion method of Athey et al., (2021)...

{marker options}{...}
{title:Options}



{marker results}{...}
{title:Stored results}


{marker examples}{...}
{title:Examples}


{marker references}{...}
{title:References}


{title:Author}
Nicolás Bastías Campos, Universidad de Chile.
Email {browse "mailto:nbastias@fen.uchile.cl":nbastias@fen.uchile.cl}


Damian Clarke, Universidad de Chile.
Email {browse "mailto:dclarke@fen.uchile.cl":dclarke@fen.uchile.cl}
Website {browse "http://www.damianclarke.net/"}


{title:Website}
{cmd:sdid} is maintained at {browse "https://github.com/damiancclarke/mcpanel": https://github.com/damiancclarke/mcpanel} 