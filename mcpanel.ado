*===============================================================================
*			Matrix Completion Methods for Causal Panel Data Models
*===============================================================================

*! mcnnm v0.0.1 25nov2024
program mcpanel, rclass
	version 14
	
	syntax varlist(min = 4 max = 4 numeric) [if] [in] [, lambda(real 100) maxiter(real 1000) TOLerance(real 1e-5) groupfe timefe]
	
	*------------------------------------------------------------------------------*
	* (0) Error checks.
	*------------------------------------------------------------------------------*
	
	local depvar `1'
	local treatment `2'
	local panelvar `3'
	local timevar `4'
	
	* Unbalanced panel. 
	
	qui xtset `panelvar' `timevar'
	
	if "`r(balanced)'" != "strongly balanced" {
		di as error "error: panel is unbalanced."
		exit 451
	}
		
	qui count if `depvar' == .
	if r(N) != 0 {
		di as error "error: missing values found in dependent variable, a balanced panel without missing observations is required."
		exit 416
	}
	
	qui count if `treatment' == .
	if r(N)! = 0 {
		di as error "error: missing values found in treatment variable,a balanced panel without missing observations is required."
		exit 416
	}
	
	* Treatment class is not boolean.
	
	qui count if `treatment' != 0 & `treatment' != 1
		if r(N) !=0 {
		di as error "error: the treatment variable takes values distinct from 0 (non-treated unit/period) and 1 (treated unit/period)."
		exit 450
	}
	
	* Existence of variables.
	
	capture confirm variable Y_mcnnm
	if (_rc == 0) {
		drop Y_mcnnm
	}
	
	capture confirm variable `depvar'_mcnnm
	if (_rc == 0) {
		di as error "error: variable `depvar'_mcnnm is already defined."
		exit 110
	}
		
	*--------------------------------------------------------------------------*
	* (1) Data set up (Stata/Mata).
	*--------------------------------------------------------------------------*
		
	qui xtset `panelvar' `timevar'	// Sorting data and defining the panel structure.

	local N = r(imax)					// Number of units.
	local T = r(tmax) - r(tmin) + 1		// Number of periods

	mata: N = strtoreal(st_local("N"))
	mata: T = strtoreal(st_local("T"))
	
	mata: depvar = rowshape(st_data(., "`depvar'"), N)	
	mata: treatment = rowshape(st_data(., "`treatment'"), N)
	
	*--------------------------------------------------------------------------*
	* (2) Run mcpanel (uses Mata functions).
	*--------------------------------------------------------------------------*
	
	timer clear 1
	timer on 1
	
	mata: lambda = strtoreal(st_local("lambda"))
	mata: maxiter = strtoreal(st_local("maxiter"))
	mata: tolerance = strtoreal(st_local("tolerance"))
	mata: groupfe = strtoreal(st_local("groupfe"))
	mata: timefe = strtoreal(st_local("timefe"))
	
	qui mata: mcpanel(depvar, treatment, lambda, maxiter, tolerance, "groupfe", "timefe")
	
	//if "`groupfe'" == "" & "`timefe'" == ""{
	//	
	//}
	
	cap rename Y_mcnnm `depvar'_mcnnm
	
	timer off 1 
	
	*--------------------------------------------------------------------------*
	* (3) Returns and output.
	*--------------------------------------------------------------------------*
		
	return scalar lambda = `lambda'
	return scalar maxiter = `maxiter'
	return scalar tolerance = `tolerance'
	//return scalar groupfe = `groupfe'
	//return scalar timefe = `timefe'
	
	return local cmdline  "mcnnm `0'"
	return local cmd      "mcnnm"
	
	display as text ""
	display as text "{hline 90}"
	display as txt "Matrix Completion with Nuclear Norm Minimization."
	display as txt ""
	if num_iterations != `maxiter' {
		display as txt "> The algorithm converged in " num_iterations " iterations."
		}
	else {
		display as txt "> The algorithm did not converge. Consider increasing the maximum number of iterations."
		}
	qui timer list 1 
	display as txt "> Total time: " r(t1) " seconds."
	display as txt "> Regularization parameter: lambda = `lambda'."
	display as txt "> Tolerance parameter: tolerance = `tolerance'."
	if "`groupfe'" == "groupfe" & "`timefe'" == "timefe" {
		display as txt "> Group fixed effects and time fixed effects are included in the estimation."
		}
	else if "`groupfe'" == "groupfe" & "`timefe'" == "" {
		display as txt "> Group fixed effects are included in the estimation."
		}
	else if "`groupfe'" == "" & "`timefe'" == "timefe" {
		display as txt "> Time fixed effects are included in the estimation."
		}
	else {
		display as txt "> No fixed effects are included in the estimation."
		}
	display as txt `touse'
	display as text "{hline 90}"
	display as txt ""
		
end

*------------------------------------------------------------------------------*
* (4) Mata functions
*------------------------------------------------------------------------------*

* (A) Function 'mcpanel'. 

// This function displays the matrix completion with nuclear norm minimization algorith with or without
// fixed effects. Depending of the specification, you can estimate the counterfactual considering group 
// fixed effects, time fixed effects, or both. Also you can estimate the counterfactual including covariates
// to improve your estimations. 

version 14
mata:	
void mcpanel(real matrix depvar, real matrix treatment,
			| real scalar lambda, real scalar maxiter, real scalar tolerance, string scalar groupfe, string scalar timefe)
{	
	// Step 1: Generate the projection matrix.
	
	N = rows(depvar)
	T = cols(depvar)
	
	treated = treatment				// 1 if treated.
	untreated = (treatment :== 0) 	// 1 if untreated.
	
	Po_Y = depvar :* untreated	// Apply the projection matrix for the observed depvar (Y_obs).

	// Step 2: Including fixed effects if required. Here we update the projection matrix with the fixed effects P_o(Y_obs - group_fe - time_fe - cons_fe).
	
	time_fe = J(rows(depvar), cols(depvar), 0)
	group_fe = J(rows(depvar), cols(depvar), 0)
	cons_fe = J(rows(depvar), cols(depvar), 0)
	
	if (groupfe == "groupfe" & timefe == "timefe") { 				// Group and time fixed effects.
		group_fe = ((rowsum(depvar) :/ T) :- sum(depvar)/(N*T)) * J(1, cols(depvar), 1)
		time_fe = J(rows(depvar), 1, 1) * ((colsum(depvar) :/ N) :- sum(depvar)/(N*T))
		cons_fe = J(N,T,sum(depvar)/(N*T))

		Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
	}
	else if (groupfe == "groupfe" & timefe != "timefe") {			// Group fixed effects.
		group_fe = ((rowsum(depvar) :/ T) :- sum(depvar)/(N*T)) * J(1, cols(depvar), 1)
		cons_fe = J(N,T,sum(depvar)/(N*T))

		Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
	}
	else if (groupfe != "groupfe" & timefe == "timefe") {			// Time fixed effects.
		time_fe = J(rows(depvar), 1, 1) * ((colsum(depvar) :/ N) :- sum(depvar)/(N*T))
		cons_fe = J(N,T,sum(depvar)/(N*T))

		Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
	}
	else if (groupfe != "groupfe" & timefe != "timefe") {			// No fixed effects.
		Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
	}

	// Step 3: Singular Value Decomposition (SVD) of initial projection matrix
	
	S = J(N, T, .)	
	Sigma = J(T, 1, .)
	Rt = J(T, T, .)
	
	svd(Po_Y_adj, S, Sigma, Rt)
	
	// Step 4: Shrinkage operator to obtain initial low-rank matrix. 
	
	Sigma_shrink = J(rows(Sigma), cols(Sigma), .)
	
	// Apply shrinkage operator to singular values.
	Sigma_shrink = Sigma :- lambda
	Sigma_shrink = Sigma_shrink :* (Sigma_shrink :> 0)
	
	// Initial low-rank approximation (L_1) using shrinked singular values.								
	L_1 = S * diag(Sigma_shrink) * Rt
	
	// Initialize L_k with observed values where treatment == 0.
	L_k = J(rows(L_1), cols(L_1), .)
	L_k = Po_Y_adj :* untreated + L_1 :* treated 
	
	// Step 4: Iterative loop to refine low-rank matrix until convergence.
	
	difference = 1
	iter = 0
	
	L_k1 = J(N, T, .)
	
	while (difference > tolerance & iter < maxiter) {
		iter++
		
		if (groupfe != "" & timefe != "") { 				// Group and time fixed effects.
			group_fe = ((rowsum(depvar) :/ T) :- sum(depvar)/(N*T)) * J(1, cols(depvar), 1)
			time_fe = J(rows(depvar), 1, 1) * ((colsum(depvar) :/ N) :- sum(depvar)/(N*T))
			cons_fe = J(N,T,sum(depvar)/(N*T))

			Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
		}
		else if (groupfe != "" & timefe == "") {			// Group fixed effects.
			group_fe = ((rowsum(depvar) :/ T) :- sum(depvar)/(N*T)) * J(1, cols(depvar), 1)
			cons_fe = J(N,T,sum(depvar)/(N*T))

			Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
		}
		else if (groupfe == "" & timefe != "") {			// Time fixed effects.
			time_fe = J(rows(depvar), 1, 1) * ((colsum(depvar) :/ N) :- sum(depvar)/(N*T))
			cons_fe = J(N,T,sum(depvar)/(N*T))

			Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
		}
		else if (groupfe != "groupfe" & timefe != "timefe") {	// No fixed effects.
			Po_Y_adj = (depvar) :* untreated + (group_fe + time_fe + cons_fe) :* treated
	}
		
		// Singular Value Decomposition for current L_k.
        svd(L_k, S, Sigma, Rt)
	
		// Apply shrinkage operator to singular values of current L_k.		
		Sigma_shrink = Sigma :- lambda
		Sigma_shrink = Sigma_shrink :* (Sigma_shrink :> 0)
	
		// Update low-rank approximation for L_{k+1}.
        L_k1_temp = S * diag(Sigma_shrink) * Rt
	
		// Apply projection to maintain observed values in Po_Y.
		L_k1 = Po_Y_adj :* untreated + L_k1_temp :* treated 
		
		// Calculate Frobenius norm difference for convergence check.
		difference = norm(L_k1 - L_k, 2)
		
		// Update L_k for next iteration.
		L_k = L_k1
	}
	
	// Export the final matrix estimates in a variable format. 
	L_end = L_k1_temp

	Y_mcnnm = colshape(L_end, 1)
	
	st_addvar("float", "Y_mcnnm")
	st_store(., "Y_mcnnm", Y_mcnnm)
	
	st_numscalar("num_iterations", iter)	
}
end