# 🏦 KipuBank

Decentralized bank vault smart contract developed in Solidity that allows users to deposit and withdraw ETH and USDC securely.

## 📋 Contract Description

KipuBank is a contract that implements a personal vault for each user

## 🚀 Deployment Instructions

### Using Remix IDE

1. **Access Remix**
   - Go to [remix.ethereum.org](https://remix.ethereum.org/)
   - Create a new file: `KipuBank.sol`
   - Copy and paste the contract code

2. **Compile**
   - Go to the "Solidity Compiler" tab
   - Select version: 0.8.20 or higher
   - Click on "Compile KipuBank.sol"

3. **Configure MetaMask**
   - Make sure you're on Sepolia Testnet
   - Verify that you have Sepolia ETH (use a faucet if necessary)

4. **Deploy**
   - Go to "Deploy & Run Transactions"
   - Environment: "Injected Provider - MetaMask"
   - Enter the constructor parameters:
     - `FEED`: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
     - `USDC`: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
   - Click on "Deploy" and confirm in MetaMask
   - Save the deployed contract address
