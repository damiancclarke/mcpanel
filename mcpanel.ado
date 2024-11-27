*===============================================================================
*			Matrix Completion Methods for Causal Panel Data Models
*===============================================================================

*! mcpanel v0.0.1 25nov2024
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
		di as error "Error: Panel is unbalanced."
		exit 451
	}
		
	qui count if `depvar' == .
	if r(N) != 0 {
		di as error "Error: Missing values found in dependent variable. A balanced panel without missing observations is required."
		exit 416
	}
	
	qui count if `treatment' == .
	if r(N)! = 0 {
		di as error "Error: Missing values found in treatment variable. A balanced panel without missing observations is required."
		exit 416
	}
	
	* Treatment class is not boolean.
	
	qui count if `treatment' != 0 & `treatment' != 1
		if r(N) !=0 {
		di as error "Error: The treatment variable takes values distinct from 0 (non-treated unit/period) and 1 (treated unit/period)."
		exit 450
	}
	
	* Staggered adoption. 
		
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
	
	qui{
	if "`lambda'" == "" & "`maxiter'" == "" & "`tolerance'" == "" {
		mata: mcnnm(depvar, treatment, 100, 1000, 1e-5)
		}
		
	else if "`lambda'" == "" & "`maxiter'" == "" & "`tolerance'" != "" {
		mata: tolerance = strtoreal(st_local("tolerance"))
		mata: mcnnm(depvar, treatment, 100, 1000, tolerance)
		}
		
	else if "`lambda'" == "" & "`maxiter'" != "" & "`tolerance'" == "" {
		mata: maxiter = strtoreal(st_local("maxiter"))
		mata: mcnnm(depvar, treatment, 100, maxiter, 1e-5)
		}
		
	else if "`lambda'" != "" & "`maxiter'" == "" & "`tolerance'" == "" {
		mata: lambda = strtoreal(st_local("lambda"))
		mata: mcnnm(depvar, treatment, lambda, 1000, 1e-5)
		}	
		
	else if "`lambda'" == "" & "`maxiter'" != "" & "`tolerance'" != "" {
		mata: maxiter = strtoreal(st_local("maxiter"))
		mata: tolerance = strtoreal(st_local("tolerance"))
		mata: mcnnm(depvar, treatment, 100, maxiter, tolerance)
		}
		
	else if "`lambda'" != "" & "`maxiter'" == "" & "`tolerance'" != "" {
		mata: lambda = strtoreal(st_local("lambda"))
		mata: tolerance = strtoreal(st_local("tolerance"))
		mata: mcnnm(depvar, treatment, lambda, 1000, tolerance)
		}
		
	else if "`lambda'" != "" & "`maxiter'" != "" & "`tolerance'" == "" {
		mata: lambda = strtoreal(st_local("lambda"))
		mata: maxiter = strtoreal(st_local("maxiter"))
		mata: mcnnm(depvar, treatment, lambda, maxiter, 1e-5)
		}
		
	else {
		mata: lambda = strtoreal(st_local("lambda"))
		mata: maxiter = strtoreal(st_local("maxiter"))
		mata: tolerance = strtoreal(st_local("tolerance"))
		mata: mcnnm(depvar, treatment, lambda, maxiter, tolerance)
		}
	
	cap rename Y_mcnnm `depvar'_mcnnm
	
	}
	
	timer off 1 
	
	*--------------------------------------------------------------------------*
	* (3) Returns and output.
	*--------------------------------------------------------------------------*
		
	return scalar lambda = `lambda'
	return scalar maxiter = `maxiter'
	return scalar tolerance = `tolerance'
	
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
	display as txt `touse'
	
	/* * Fixed Effects (para cuando estén listos)
	if groupfe == 1 & timefe == 1 {
		display as txt "> Group fixed effects and time fixed effects are included in the estimation."
		}
	else if groupfe == 1 & timefe == 0 {
		display as txt "> Group fixed effects are included in the estimation."
		}
	else if groupfe == 0 & timefe == 1 {
		display as txt "> Time fixed effects are included in the estimation."
		}
	else {
		display as txt "> No fixed effects are included in the estimation."
		}
	*/
	
	display as text "{hline 90}"
	display as txt ""
		
end

version 14
mata:
void mcnnm(real matrix depvar, real matrix treatment,
			| real scalar lambda, real scalar maxiter, real scalar tolerance)
{
	// Step 1: Generate the projection matrix.
	
	N = rows(depvar)
	T = cols(depvar)

	treatment = (treatment :== 0) 	// Create Po(A) indicator
	
	Po_Y = depvar :* treatment	// Apply the projection matrix for the observed depvar (Y_obs).
	
	// Step 2: Singular Value Decomposition (SVD) of initial projection matrix
	
	S = J(N, T, .)	
	Sigma = J(T, 1, .)
	Rt = J(T, T, .)
	
	svd(Po_Y, S, Sigma, Rt)
	
	// Step 3: Shrinkage operator to obtain initial low-rank matrix. 
	
	Sigma_shrink = J(rows(Sigma), cols(Sigma), .)
	
	// Apply shrinkage operator to singular values.
	for (i = 1; i <= rows(Sigma); i++) {                                     
        Sigma_shrink[i] = (Sigma[i] - lambda > 0) ? (Sigma[i] - lambda) : 0
    }
	
	// Initial low-rank approximation (L_1) using shrinked singular values.								
	L_1 = S * diag(Sigma_shrink) * Rt
	
	// Initialize L_k with observed values where treatment == 0.
	L_k = J(rows(L_1), cols(L_1), .)
	
	for (i = 1; i <= N; i++) {
        for (j = 1; j <= T; j++) {
            L_k[i,j] = (treatment[i,j] == 0) ? L_1[i,j] : Po_Y[i,j]
        }
    }
	
	// Step 4: Iterative loop to refine low-rank matrix until convergence.
	
	difference = 1
	iter = 0
	
	L_k1 = J(N, T, .)
	
	while (difference > tolerance & iter < maxiter) {
		iter++
		
		// Singular Value Decomposition for current L_k.
        svd(L_k, S, Sigma, Rt)
	
		// Apply shrinkage operator to singular values of current L_k.		
        for (i = 1; i <= rows(Sigma); i++) {
            Sigma_shrink[i] = (Sigma[i] - lambda > 0) ? (Sigma[i] - lambda) : 0
        }
		
		// Update low-rank approximation for L_{k+1}.
        L_k1_temp = S * diag(Sigma_shrink) * Rt
	
		// Apply projection to maintain observed values in Po_Y.
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= T; j++) {
                L_k1[i,j] = (treatment[i,j] == 0) ? L_k1_temp[i,j] : Po_Y[i,j]
            }
        }
		
		// Calculate Frobenius norm difference for convergence check.
		difference = norm(L_k1 - L_k, 2)
		
		// Update L_k for next iteration.
		L_k = L_k1
	}
	
	// Export the final matrix estimates in a variable format. 
	
	Y_mcnnm = colshape(L_k1_temp, 1)
	
	st_addvar("float", "Y_mcnnm")
	st_store(., "Y_mcnnm", Y_mcnnm)
	
	st_numscalar("num_iterations", iter)	
	
}	
end