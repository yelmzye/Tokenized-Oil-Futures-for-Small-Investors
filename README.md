# 🛢️ Tokenized Oil Futures for Small Investors

> **Democratizing oil futures trading through blockchain technology** 🚀

## 📋 Overview

This smart contract enables everyday investors to participate in oil futures markets through fractional, tokenized contracts. Instead of requiring massive capital and institutional access, small investors can now trade oil futures with minimal investment amounts.

## ✨ Key Features

- 🔥 **Fractional Oil Futures** - Buy portions of oil contracts, not full barrels
- 💰 **Low Minimum Investment** - Start with as little as 1 STX  
- 📊 **Real-time Price Tracking** - Live oil price updates and historical data
- 🔄 **Transferable Contracts** - Trade your positions with other users
- ⏰ **Automated Settlement** - Contracts settle automatically at expiry
- 🛡️ **Secure & Transparent** - Built on Stacks blockchain

## 🏗️ Contract Architecture

The contract implements a fungible token (`oil-future-token`) that represents ownership in oil futures positions. Key components:

- **Futures Contracts**: Individual contract records with strike price, expiry, and settlement status
- **User Positions**: Track total investment, active contracts, and returns per user  
- **Price Oracle**: Maintains current oil prices and historical data
- **Settlement Engine**: Handles contract expiry and profit distribution

## 🚀 Usage Instructions

### For Contract Owner

**Initialize the contract:**
```clarity
(contract-call? .Tokenized-Oil-Futures initialize-contract u1440) ;; 1440 blocks ≈ 10 days
```

**Update oil prices:**
```clarity
(contract-call? .Tokenized-Oil-Futures update-oil-price u76000) ;; $76/barrel in cents
```

### For Investors

**Create a futures position:**
```clarity
(contract-call? .Tokenized-Oil-Futures create-futures-contract u100 u75000)
;; Buy 100 units at $75 strike price
```

**Transfer your contract:**
```clarity
(contract-call? .Tokenized-Oil-Futures transfer-contract u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

**Settle at expiry:**
```clarity
(contract-call? .Tokenized-Oil-Futures settle-contract u1)
```

### Read-Only Functions

**Check contract info:**
```clarity
(contract-call? .Tokenized-Oil-Futures get-contract-info)
```

**View your position:**
```clarity
(contract-call? .Tokenized-Oil-Futures get-user-position tx-sender)
```

**Get current oil price:**
```clarity
(contract-call? .Tokenized-Oil-Futures get-current-oil-price)
```

## 💡 How It Works

1. **📈 Price Setting**: Contract owner updates oil prices periodically
2. **🎯 Contract Creation**: Investors specify amount and strike price 
3. **💳 Payment**: STX is locked as collateral based on position size
4. **🪙 Token Minting**: Oil future tokens are minted to represent ownership
5. **📊 Profit Calculation**: At expiry, profit = (current_price - strike_price) × amount
6. **💸 Settlement**: Profitable positions receive STX payouts automatically

## 🔧 Technical Details

- **Token Standard**: Clarity fungible tokens (SIP-010)
- **Price Format**: USD cents (e.g., 75000 = $750.00)  
- **Minimum Investment**: Configurable (default 1000 microSTX)
- **Contract Expiry**: Set during initialization
- **Settlement**: Automatic based on final oil price

## 🛡️ Security Features

- Owner-only price updates and admin functions
- Contract expiry enforcement  
- Balance verification before operations
- Emergency shutdown capability
- Prevents double settlement of contracts

## 📊 Example Scenarios

### Bullish Position
- Current oil price: $75/barrel
- You buy 100 units at $75 strike  
- Oil rises to $80 at expiry
- **Profit**: 100 × ($80 - $75) = $500 💰

### Bearish Market  
- Current oil price: $75/barrel
- You buy 100 units at $75 strike
- Oil falls to $70 at expiry  
- **Loss**: Limited to initial investment 📉

## 🔍 Error Codes

- `u100`: Owner only operation
- `u101`: Contract not found
- `u102`: Insufficient balance  
- `u103`: Contract expired
- `u104`: Contract not yet expired
- `u105`: Insufficient payment
- `u106`: Invalid amount
- `u107`: Unauthorized operation

## 🎯 Getting Started

1. Deploy the contract to Stacks testnet
2. Initialize with desired expiry period
3. Set initial oil price
4. Configure minimum investment amount
5. Start creating futures positions! 🚀

## 📝 License

MIT License - Trade responsibly! 

---

*Built with ❤️ on Stacks blockchain*
