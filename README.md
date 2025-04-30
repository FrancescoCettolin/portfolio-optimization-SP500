# Portfolio Optimization on S&P 500 Subset

This project was developed during the MSc in Quantitative Finance at POLIMI Graduate School of Management (2024–2025).  
It implements a full portfolio construction pipeline using real stock data from five S&P 500 companies, combining classical and advanced asset allocation techniques.

## Repository Structure

## Code Overview

Scripts are located in [`code/`](code):

- `Report.m` – End-to-end implementation of the project:  
  - Imports and cleans financial time series (prices, returns, market cap)  
  - Performs normality and distribution analysis  
  - Estimates covariance matrices (sample, constant correlation, shrinkage)  
  - Computes efficient frontiers using Markowitz theory  
  - Constructs tangency portfolios (unconstrained and constrained)  
  - Applies CAPM regression to estimate alphas and betas

- `BlackLitterman.m` – Implementation of the Black-Litterman model:  
  - Formulates investor views on relative performance  
  - Applies the Black-Litterman posterior expected returns  
  - Computes new optimal portfolio weights  
  - Visualizes asset allocation and risk-return tradeoffs

## Figures

The project includes several figures that illustrate the results of portfolio optimization analyses. Below is a categorized overview:

### Efficient Frontiers

- `Frontiera_MK.png` – Mean-variance frontier with individual stocks.
- `Frontiera_risk_free.png` – Efficient frontier with risk-free asset and Capital Market Line (CML).
- `Frontiere_vincolate.png` – Efficient frontier with portfolio constraints.
- `Frontiere_Risk Free_vincolate.png` – Constrained frontier with risk-free asset and CML.

### Covariance Matrix & Estimation

- `HeatMap_variance_mtx.png` – Heatmap of variance-covariance matrices (standard, constant correlation, shrinkage).

### Portfolio Weights

- `Pesi_Portafolgi_risk_free_vincolati.png` – Asset weights for constrained tangency portfolios.
- `Portafogli risk free su frontiera.png` – Comparison of portfolios on the risk-free frontier.
- `Portafolgi_diverse_MTX.png` – Portfolio weights under different covariance estimators.
- `Portafogli_con_tangente.png` – Portfolio weights for tangency portfolios.

### Return Analysis

- `Rendimenti_classic_log.png` – Comparison of simple vs exponential mean returns.
- `Total_and_Log returns.png` – Time series of total and log returns for selected stocks.
- `Price Stocks vs SPX.png` – Normalized price comparison of selected stocks vs S&P 500.

All figures are available in the [`figures/`](./figures/) directory.

## Data

Input files in [`data/`](data) include adjusted closing prices and total returns for:

- Discover Financial Services (DFS)
- Grainger Inc. (GWW)
- Nisource (NI)
- First Solar (FSLR)
- Verizon (VZ)
- S&P 500 Index (SPX)

These are used to compute return matrices, covariance estimates, and for CAPM calibration.

## Report

The full academic report is available here:  
[`report/Cettolin_Gestione_Portafogli.pdf`](report/Cettolin_Gestione_Portafogli.pdf)

---

> *Created by Francesco Cettolin – MSc Quantitative Finance @ POLIMI (2024–2025)*
