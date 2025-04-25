import time
import pandas as pd
from datetime import datetime
import os
from dotenv import load_dotenv
import requests
import json

# Load environment variables
load_dotenv()

class TokenPriceComparer:
    def __init__(self):
        # Pyth Price Feed IDs for Berachain (USD prices)
        self.price_feeds = {
            "BERA": "0x962088abcfdbdb6e30db2e340c8cf887d9efb311b1f2f17b155a63dbb6d40265",  # BERA/USD
            "iBGT": "0xc929105a1af143cbfc887c4573947f54422a9ca88a9e622d151b8abdf5c2962f",  # iBGT/USD
            "LBGT": "0x7d80a0d7344c6632c5ed2b85016f32aed4f831294e274739d92bb9e32df5b22f",  # LBGT/USD
            "stBGT": "0xffd5448b844f5e7eeafbf36c47c7d4791a3cb86f5cefe02a7ba7864b22d81137"   # stBGT/USD
        }
        
    def get_token_price(self, token_symbol):
        try:
            feed_id = self.price_feeds.get(token_symbol)
            if not feed_id:
                print(f"No price feed found for {token_symbol}")
                return None
                
            # Fetch price data from Pyth API
            url = f"https://hermes.pyth.network/v2/updates/price/latest?ids[]={feed_id}"
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            
            # Extract price and exponent from the response
            price_data = data['parsed'][0]
            price = float(price_data['price']['price'])
            expo = price_data['price']['expo']
            
            # Adjust for exponent
            price = price * (10 ** expo)
            
            return price
        except Exception as e:
            print(f"Error fetching price for {token_symbol}: {e}")
            return None

    def calculate_percentage_difference(self, base_price, comparison_price):
        if base_price and comparison_price:
            return ((comparison_price - base_price) / base_price) * 100
        return None

    def get_comparison_data(self):
        # Get BERA price as base
        bera_price = self.get_token_price("BERA")
        if not bera_price:
            return None

        results = []
        for token in ["iBGT", "LBGT", "stBGT"]:
            token_price = self.get_token_price(token)
            if token_price:
                # Calculate percentage difference against BERA
                percentage_diff = self.calculate_percentage_difference(bera_price, token_price)
                
                results.append({
                    "token": token,
                    "price": token_price,
                    "percentage_difference": percentage_diff
                })
        
        return {
            "base_token": "BERA",
            "base_price": bera_price,
            "comparisons": results,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

    def display_results(self, data):
        if not data:
            print("Error: Could not fetch price data")
            return

        print("\n" + "="*50)
        print(f"Price Comparison at {data['timestamp']}")
        print("="*50)
        print(f"Base Token: {data['base_token']}")
        print(f"Base Price: ${data['base_price']:.8f}")
        print("\nComparison Tokens:")
        print("-"*50)
        
        for comp in data['comparisons']:
            print(f"\nToken: {comp['token']}")
            print(f"Price: ${comp['price']:.8f}")
            print(f"Percentage Difference from BERA: {comp['percentage_difference']:.2f}%")

def main():
    comparer = TokenPriceComparer()
    
    try:
        while True:
            data = comparer.get_comparison_data()
            comparer.display_results(data)
            print("\nWaiting for next update...")
            time.sleep(10)  # Update every 10 seconds
    except KeyboardInterrupt:
        print("\nStopping price comparison...")

if __name__ == "__main__":
    main() 