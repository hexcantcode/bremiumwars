import requests
import json
import time
import pandas as pd
from datetime import datetime
from typing import Dict, Optional, Tuple
from pathlib import Path
from dotenv import load_dotenv
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class PriceMonitor:
    def __init__(self, config_path: str = "config.json"):
        self.load_config(config_path)
        self.setup_logging()
        
    def load_config(self, config_path: str) -> None:
        """Load configuration from JSON file."""
        try:
            with open(config_path, 'r') as f:
                self.config = json.load(f)
        except FileNotFoundError:
            logging.error(f"Configuration file not found: {config_path}")
            raise
        except json.JSONDecodeError:
            logging.error(f"Invalid JSON in configuration file: {config_path}")
            raise

    def setup_logging(self) -> None:
        """Setup CSV logging for price comparisons."""
        self.log_file = Path(self.config['log_file'])
        if not self.log_file.exists():
            df = pd.DataFrame(columns=['timestamp', 'token', 'price', 'source'])
            df.to_csv(self.log_file, index=False)

    def fetch_price(self, feed_id: str) -> Optional[float]:
        """Fetch price from Pyth Network."""
        try:
            url = f"https://xc-mainnet.pyth.network/api/latest_price_feeds?ids[]={feed_id}"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if not data or not isinstance(data, list) or len(data) == 0:
                logging.error(f"Invalid response format for feed ID: {feed_id}")
                return None
                
            price = float(data[0]['price']['price']) * 10 ** float(data[0]['price']['expo'])
            return price
            
        except requests.RequestException as e:
            logging.error(f"Network error while fetching price: {str(e)}")
            return None
        except (KeyError, ValueError, TypeError) as e:
            logging.error(f"Error parsing price data: {str(e)}")
            return None

    def log_price(self, token: str, price: float, source: str) -> None:
        """Log price to CSV file."""
        try:
            new_row = pd.DataFrame([{
                'timestamp': datetime.now().isoformat(),
                'token': token,
                'price': price,
                'source': source
            }])
            new_row.to_csv(self.log_file, mode='a', header=False, index=False)
        except Exception as e:
            logging.error(f"Error logging price data: {str(e)}")

    def monitor_prices(self) -> None:
        """Main monitoring loop."""
        while True:
            try:
                for token, feed_id in self.config['price_feed_ids'].items():
                    price = self.fetch_price(feed_id)
                    if price is not None:
                        print(f"{token} Price: ${price:.2f}")
                        self.log_price(token, price, 'pyth')
                    else:
                        print(f"Failed to fetch price for {token}")
                
                time.sleep(self.config['update_interval'])
                
            except KeyboardInterrupt:
                logging.info("Price monitoring stopped by user")
                break
            except Exception as e:
                logging.error(f"Unexpected error in monitoring loop: {str(e)}")
                time.sleep(self.config['update_interval'])

def main():
    try:
        monitor = PriceMonitor()
        monitor.monitor_prices()
    except Exception as e:
        logging.error(f"Failed to initialize price monitor: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main() 