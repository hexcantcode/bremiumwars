# Berachain Token Price Comparison System

This system allows you to compare the price of BGT-related tokens against BERA on Berachain, showing their percentage differences in real-time using Pyth Network's USD price feeds.

## Features

- Fetches real-time USD price data from Pyth Network's oracle system
- Converts USD prices to BERA-based prices for comparison
- Compares BGT-related tokens (iBGT, LBGT, stBGT) against BERA
- Shows prices in BERA (native currency)
- Shows percentage differences between tokens
- Updates automatically every 10 seconds
- Uses on-chain data for maximum reliability and speed

## Setup

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

2. Create a `.env` file with your Berachain RPC URL:
```
BERACHAIN_RPC_URL=https://rpc.berachain.com
```

3. Run the script:
```bash
python token_price_comparison.py
```

## Configuration

The system is configured to compare:
- Main token: BERA (base currency)
- Comparison tokens:
  - iBGT (0xc929105a1af143cbfc887c4573947f54422a9ca88a9e622d151b8abdf5c2962f)
  - LBGT (0x7d80a0d7344c6632c5ed2b85016f32aed4f831294e274739d92bb9e32df5b22f)
  - stBGT (0xffd5448b844f5e7eeafbf36c47c7d4791a3cb86f5cefe02a7ba7864b22d81137)

## How It Works

1. Fetches USD prices for all tokens from Pyth Network
2. Uses BERA's USD price as the base for conversion
3. Converts all prices to BERA-based prices
4. Calculates percentage differences against BERA
5. Updates every 10 seconds

## Notes

- The script uses Pyth Network's USD price feeds
- All prices are converted to and shown in BERA
- Updates occur every 10 seconds for faster price tracking
- You can stop the script at any time by pressing Ctrl+C
- Make sure your Berachain RPC URL is properly configured in the `.env` file 