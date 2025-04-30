# %%
#PUNTO 6

# %%
import os
import yfinance as yf
import pandas as pd
import numpy as np


# %%
# Ottieni il percorso della directory corrente dove si trova lo script
current_dir = os.path.dirname(os.path.abspath(__file__))

# Definisci i nomi dei file
file_names = {
   "NI": "NI.N.csv",
   "VZ": "VZ.N.csv", 
   "DFS": "DFS.N.csv",
   "FSLR": "FSLR.OQ.csv",
   "GWW": "GWW.N.csv"
}

# Costruisci i percorsi completi
file_paths = {stock: os.path.join(current_dir, filename) for stock, filename in file_names.items()}

#stampa la directory corrente
print(current_dir)

#stampa i percorsi
print(file_paths)

# %%
# Funzione per caricare e pulire i dati da un file CSV
def load_and_clean_data(file_path, stock_name):
   if not os.path.exists(file_path):
       print(f"Errore: Il file {file_path} non esiste.")
       return None
   data = pd.read_csv(file_path)
   
   # Pulizia
   data = data[['Date', 'Company Market Cap', '1 Month Total Return']].dropna()
   data['Company Market Cap'] = pd.to_numeric(data['Company Market Cap'], errors='coerce')
   data['1 Month Total Return'] = pd.to_numeric(data['1 Month Total Return'], errors='coerce')
   data.rename(columns={
       'Company Market Cap': f'Company Market Cap_{stock_name}',
       '1 Month Total Return': f'1 Month Total Return_{stock_name}'
   }, inplace=True)
   
   # Converti i rendimenti da percentuali a valori decimali
   data[f'1 Month Total Return_{stock_name}'] = data[f'1 Month Total Return_{stock_name}'] / 100.0
   return data


# %%
# Caricamento e pulizia dei dati per ogni titolo
stock_data = {}
for stock, path in file_paths.items():
   cleaned_data = load_and_clean_data(path, stock)
   if cleaned_data is not None:
       stock_data[stock] = cleaned_data

# Unione dei dati sulla base della colonna 'Date'
combined_data = stock_data['NI']
for stock in ['VZ', 'DFS', 'FSLR', 'GWW']:
   combined_data = pd.merge(combined_data, stock_data[stock], on='Date', how='inner')

# Calcolo della somma dei market cap e dei pesi relativi
market_cap_columns = [col for col in combined_data.columns if "Company Market Cap" in col]
total_return_columns = [col for col in combined_data.columns if "1 Month Total Return" in col]

combined_data['Total Market Cap'] = combined_data[market_cap_columns].sum(axis=1)
for col in market_cap_columns:
   stock_name = col.split('_')[-1]
   combined_data[f'Weight_{stock_name}'] = combined_data[col] / combined_data['Total Market Cap']

# %%
# Arrotonda i pesi alla quarta cifra decimale
for stock in ['NI', 'VZ', 'DFS', 'FSLR', 'GWW']:
   combined_data[f'Weight_{stock}'] = combined_data[f'Weight_{stock}']

# Verifica della somma dei pesi
combined_data['Sum of Weights'] = combined_data[[f'Weight_{col.split("_")[-1]}' for col in market_cap_columns]].sum(axis=1)
if not combined_data['Sum of Weights'].apply(lambda x: abs(x - 1) < 1e-6).all():
   print("Errore: La somma dei pesi non è uguale a 1 in tutte le date.")
else:
   print("La somma dei pesi è uguale a 1 in tutte le date.")

# Calcolo del Market Return come media ponderata
combined_data['Market Return'] = sum(
   combined_data[f'Weight_{col.split("_")[-1]}'] * combined_data[f'1 Month Total Return_{col.split("_")[-1]}']
   for col in market_cap_columns
).round(4)  # Arrotondamento alla quarta cifra decimale
print(combined_data[['Date', 'Market Return', 'Sum of Weights', 'Total Market Cap', 'Weight_NI', 'Weight_VZ', 'Weight_DFS', 'Weight_FSLR', 'Weight_GWW']].tail(5))

# %%
# Definisci il tasso privo di rischio mensile = 0.03/12
risk_free_rate = 0.0025
print("Tasso privo di rischio (rf) = ", risk_free_rate)

# Calcola il coefficiente di avversione al rischio λ come costante
average_market_return = combined_data['Market Return'].mean()
print("Rendimento medio di mercato:", average_market_return)

market_variance = combined_data['Market Return'].var().round(4)
print("Varianza di mercato:", market_variance)  

lambda_constant = (average_market_return - risk_free_rate) / market_variance
if lambda_constant < 0:
   print("Errore: Il coefficiente di avversione al rischio è negativo.")
   lambda_constant = 2.5 #costante accademica
else:
   print("Il coefficiente di avversione al rischio è positivo. (λ) =" , lambda_constant)


# %%
# Calcolo della matrice di covarianza (Σ) dei ritorni
returns_data = combined_data[[f'1 Month Total Return_{stock}' for stock in ['NI', 'VZ', 'DFS', 'FSLR', 'GWW']]]
cov_matrix = returns_data.cov().round(4)
print("Matrice di covarianza:")
print(cov_matrix)
print()

# Calcolo dei pesi di mercato
market_weights = combined_data[[f'Weight_{stock}' for stock in ['NI', 'VZ', 'DFS', 'FSLR', 'GWW']]].iloc[-1].values
print("Pesi di mercato originali:")
for stock, weight in zip(['NI', 'VZ', 'DFS', 'FSLR', 'GWW'], market_weights.round(5)):
    print(f"{stock}: {weight}")
print()

# Calcolo del vettore π (pi) originale
pi_vector = np.dot(cov_matrix, market_weights) * lambda_constant
print("Vettore π (pi) originale:")
for stock, pi_val in zip(['NI', 'VZ', 'DFS', 'FSLR', 'GWW'], pi_vector):
    print(f"{stock}: {pi_val:.4f}")
print()

# Creazione del DataFrame per π con nomi dei titoli
pi_vector_df = pd.DataFrame({
    'Stock': ['NI', 'VZ', 'DFS', 'FSLR', 'GWW'],
    'Pi': pi_vector,
    'Pesi di Mercato Neutri': market_weights.round(5)
})

# Stampa del vettore π con nomi dei titoli
print("\nVettore π (pi) con rendimenti impliciti:")
for stock, pi_val in zip(['NI', 'VZ', 'DFS', 'FSLR', 'GWW'], pi_vector):
    print(f"{stock}: {pi_val:.4f}")

# Definisci i percorsi per i file di output nella directory corrente
final_results_path = os.path.join(current_dir, "Returns_Portafoglio_Market_Cap.csv")
pi_vector_path = os.path.join(current_dir, "Pi_Vector_Neutral_Portfolio_Weights.csv")

# Salvataggio dei risultati
result = combined_data[['Date', 'Market Return'] + [f'Weight_{col.split("_")[-1]}' for col in market_cap_columns]]
result.to_csv(final_results_path, index=False)
pi_vector_df.to_csv(pi_vector_path, index=False)

print("Codice eseguito correttamente. Risultati salvati nei file CSV nella stessa directory del codice.")

# %%
# Verifica della formula inversa
# Usando l'inversa della matrice di covarianza
cov_inverse = np.linalg.inv(cov_matrix)
optimal_weights = (1/lambda_constant) * np.dot(cov_inverse, pi_vector)

print("Verifica dei pesi:")
print("Pesi originali vs Pesi calcolati:")
for stock, orig, calc in zip(['NI', 'VZ', 'DFS', 'FSLR', 'GWW'], 
                            market_weights.round(4), 
                            optimal_weights.round(4)):
    print(f"{stock}: {orig} vs {calc}")
print()

# Creazione del DataFrame di confronto
comparison_df = pd.DataFrame({
    'Stock': ['NI', 'VZ', 'DFS', 'FSLR', 'GWW'],
    'Original Weight': market_weights.round(4),
    'Calculated Weight': optimal_weights.round(4),
    'Difference': (optimal_weights - market_weights).round(4),
    'Pi': pi_vector.round(4)
})

print("Tabella di confronto completa:")
print(comparison_df)

# Verifica della somma dei pesi
print("\nSomma dei pesi originali:", market_weights.sum().round(4))
print("Somma dei pesi calcolati:", optimal_weights.sum().round(4))

# %%
#punto 7 View 1

# %%
#Definizione delle opinioni (Q) e matrice P
# Q rappresenta le previsioni sui rendimenti degli asset, mentre P specifica le relazioni tra gli asset e le opinioni
Q = np.array([0.02, 0.03])  #FSLR salirà del 2%, GWW  del 3%
P = np.array([
    [0, 0, 0, 1, 0],   # View su FSLR
    [0, 0, 0, 0, 1]  # View su GWW
])
print("Opinioni (Q):", Q)
print("Matrice P:")
print(P)

# %%
tau = 0.025  # Costante di incertezza delle views

# %%
# Calcolo di Omega (incertezza delle views)
# Formula per Omega: Omega = diag(P * tau * Sigma * P.T)
# rappresenta l'incertezza associata alle opinioni espresse

Omega = np.diag(np.diag(P @ (tau * cov_matrix.values) @ P.T))
print("Omega:")
print(Omega)
print()

# Calcolo della matrice combinata (posterior)
# Formula per la matrice di covarianza a posteriori: posterior_cov_matrix = (inv(tau * Sigma) + P.T * inv(Omega) * P)^-1
# Formula per la media a posteriori: posterior_mean = posterior_cov_matrix * (inv(tau * Sigma) * Pi + P.T * inv(Omega) * Q)
inv_sigma = np.linalg.inv(tau * cov_matrix.values)
print("Inversa di Sigma:")
print(inv_sigma)
print()

inv_omega = np.linalg.inv(Omega)
print("Inversa di Omega:")
print(inv_omega)
print()

posterior_cov_matrix = np.linalg.inv(inv_sigma + P.T @ inv_omega @ P)
print("Matrice di covarianza a posteriori:")
print(posterior_cov_matrix)
print()

posterior_mean = posterior_cov_matrix @ (inv_sigma @ pi_vector + P.T @ inv_omega @ Q)
print("Media a posteriori:")
print(posterior_mean)


# %%
# Step 8: Calcolo dei pesi aggiornati usando la formula finale
# Formula per i pesi del portafoglio: w_new = (Sigma^-1 * posterior_mean) / sum(Sigma^-1 * posterior_mean)
sigma_new_inv_pi_new = np.linalg.inv(cov_matrix.values) @ posterior_mean
print("Sigma^-1 * posterior_mean:")
print(sigma_new_inv_pi_new.round(5))
print()

portfolio_weights = sigma_new_inv_pi_new / sigma_new_inv_pi_new.sum()
print("Pesi del portafoglio aggiornati:")
print(portfolio_weights.round(5))


# %%
# Step 9: Creazione di un DataFrame per visualizzare i risultati
final_weights = pd.DataFrame({
    'Stock': ['NI', 'VZ', 'DFS', 'FSLR', 'GWW'],
    'Posterior Mean': posterior_mean.flatten().round(5),
    'Portfolio Weights': portfolio_weights.flatten().round(5)
})
print(final_weights)    
print()

# Controllo della somma dei pesi
if not np.isclose(final_weights['Portfolio Weights'].sum(), 1, atol=1e-6):
    print("Errore: La somma dei pesi non è uguale a 1.")
else:
    print("La somma dei pesi è uguale a 1.")

# %%
# Salvataggio dei risultati
output_file = os.path.join(current_dir, "black_litterman_results_view_1.csv")
final_weights.to_csv(output_file, index=False)
print(f"Risultati salvati in: {output_file}")

# %%
# Punto 7 View 2

# %%
stocks = ['NI', 'VZ', 'DFS', 'FSLR', 'GWW']

# Definizione dei rendimenti attesi dal CAPM ottenuti dal punto 5
capm_returns = {
    "NI": 0.0336,
    "VZ": 0.0297,
    "DFS": 0.0709,
    "FSLR": 0.0741,
    "GWW": 0.0505,
}

# Mensilizzazione dei rendimenti CAPM considerando la crescita composta
capm_returns_monthly = {stock: (1 + r)**(1/12) - 1 for stock, r in capm_returns.items()}

# %%
# Scarica i dividendi per ciascun titolo
def download_dividends(stocks, start_date, end_date, output_dir):
    for stock in stocks:
        ticker = yf.Ticker(stock)
        dividends = ticker.dividends
        dividends.index = dividends.index.tz_localize(None)
        dividends = dividends[(dividends.index >= start_date) & (dividends.index <= end_date)]

        if dividends.empty:
            print(f"Nessun dividendo trovato per {stock} dal {start_date} al {end_date}")
            continue

        file_path = os.path.join(output_dir, f"{stock}_dividends.csv")
        dividends.to_csv(file_path)
        print(f"Dividendi salvati: {file_path}")

# Scarica i dividendi
start_date = '2014-01-01'
end_date = '2024-12-31'
output_dir = os.getcwd()
download_dividends(stocks, start_date, end_date, output_dir)

# %%
# Calcolo dividendi mensili
def calculate_monthly_dividends(file_path):
    df = pd.read_csv(file_path)
    df['Date'] = pd.to_datetime(df['Date'])
    df['Anno'] = df['Date'].dt.year
    df = df.sort_values(by="Date")
    df['Dividends'] = df['Dividends'].fillna(method='ffill')

    dividendi_per_anno = df.groupby('Anno')['Dividends'].sum()
    dividendi_mensili = dividendi_per_anno / 12

    # Salva i dividendi mensili in un file CSV per ogni titolo
    file_name = os.path.basename(file_path)
    output_file = os.path.join(output_dir, f"{file_name.split('.')[0]}_monthly_dividends.csv")
    dividendi_mensili.to_csv(output_file)
    print(f"Dividendi mensili salvati: {output_file}")

    return df, dividendi_mensili

# Calcolo crescita dei dividendi
def calculate_monthly_cmgr(monthly_dividends, years):
    initial_dividend = monthly_dividends.iloc[0]
    final_dividend = monthly_dividends.iloc[-1]
    n_months = 12 * years
    return ((final_dividend / initial_dividend) ** (1 / n_months) - 1) * 100

# Modello di Gordon Growth
def calculate_gordon_growth(d0, g, r):
    d1 = d0 * (1 + g)
    value_per_share = d1 / (r - g)
    monthly_return = (d1 / value_per_share) * 100
    return d1, value_per_share, monthly_return

# %%
gordon_results = []
for stock in stocks:
    file_path = os.path.join(output_dir, f"{stock}_dividends.csv")
    if not os.path.exists(file_path):
        continue

    _, dividendi_mensili = calculate_monthly_dividends(file_path)
    cmgr_mensile = calculate_monthly_cmgr(dividendi_mensili, years=18)

    d0 = dividendi_mensili.iloc[-1]
    g = cmgr_mensile / 100
    r = capm_returns_monthly[stock]

    d1, value_per_share, monthly_return = calculate_gordon_growth(d0, g, r)
    gordon_results.append({
        'Stock': stock,
        'D0 (Dividendo Recente)': d0,
        'D1 (Dividendo Futuro)': d1,
        'g (Dividend Growth Rate)': g.round(4),
        'r (Rate of Return)': r,  
        'Value per Share': value_per_share.round(4),
        'Monthly Return (%)': monthly_return.round(4)
    })

print("Risultati del modello di Gordon Growth:")
gordon_results_df = pd.DataFrame(gordon_results)
print(gordon_results_df)

# Salva i risultati in un file CSV
gordon_results_file = os.path.join(current_dir, "gordon_growth_results.csv")
gordon_results_df.to_csv(gordon_results_file, index=False)
print(f"Risultati salvati in: {gordon_results_file}")

# %%
Q_2 = np.array([0.001412, 0.001087]) # VZ salirà dello 0.1412%, GWW del 0.1087%
P_2 = np.array([
    [0, 1, 0, 0, 0], # View su VZ
    [0, 0, 0, 0, 1]  # View su GWW
])

print("Opinioni (Q):", Q_2)
print("Matrice P:", P_2)

Omega = np.diag(np.diag(P_2 @ (tau * cov_matrix.values) @ P_2.T))
print("Omega:")
print(Omega)


inv_sigma = np.linalg.inv(tau * cov_matrix.values)
print("Inversa di Sigma:")
print(inv_sigma)
print()

inv_omega = np.linalg.inv(Omega)
print("Inversa di Omega:")
print(inv_omega)
print()

posterior_cov_matrix = np.linalg.inv(inv_sigma + P_2.T @ inv_omega @ P_2)
print("Matrice di covarianza a posteriori:")
print(posterior_cov_matrix)
print()

posterior_mean = posterior_cov_matrix @ (inv_sigma @ pi_vector + P_2.T @ inv_omega @ Q_2)
print("Rendimenti attesi a posteriori:", posterior_mean)
print()

sigma_new_inv_pi_new = np.linalg.inv(cov_matrix.values) @ posterior_mean
print("Sigma^-1 * posterior_mean:")
print(sigma_new_inv_pi_new)
print()

portfolio_weights = sigma_new_inv_pi_new / sigma_new_inv_pi_new.sum()
print("Pesi ottimali del portafoglio:", portfolio_weights)

final_weights = pd.DataFrame({
    'Stock': stocks,
    'Posterior Mean': posterior_mean.flatten().round(5),
    'Portfolio Weights': portfolio_weights.flatten().round(5)
})
print(final_weights)

# Salvataggio dei risultati
output_file = os.path.join(current_dir, "black_litterman_results_view_2.csv")
final_weights.to_csv(output_file, index=False)
print(f"Risultati salvati in: {output_file}")



