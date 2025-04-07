# BasePool

BasePool is a provably fair pool game built on Base network using Coinbase's MiniKit for Farcaster integration. Players can participate by sending ETH to get assigned numbers, with the chance to win the pool when it reaches 0.5 ETH.

![BasePool Screenshot](https://basepool.miniapps.zone/gitHub.png)
![BasePool Screenshot](https://basepool.miniapps.zone/miniApp.png)

## 🎮 How It Works

1. **Participation**
   - For every 0.0005 ETH sent to the contract, you get assigned one number
   - There's no limit on the amount you can send per transaction
   - The only requirement is that the amount must be a multiple of 0.0005 ETH
   - Examples of participation:
     - Send 0.0005 ETH = Get 1 number
     - Send 0.001 ETH = Get 2 numbers
     - Send 0.005 ETH = Get 10 numbers
     - And so on...

2. **Pool Mechanics**
   - The pool accumulates ETH from all participants
   - When the pool reaches 0.5 ETH:
     - A random number is generated using Pyth Network
     - The next transaction triggers:
       - The pool balance is sent to the winning number
       - A new pool automatically starts
   - The game runs continuously and autonomously
   - Pool parameters (0.5 ETH target, 0.0005 ETH per number) are fixed and cannot be modified

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Yarn or npm
- A Base-compatible wallet (e.g., Coinbase Wallet)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/basepool.git
cd basepool
```

2. Install dependencies
```bash
yarn install
```

3. Set up environment variables
```bash
cp .env.example .env
```
Fill in your environment variables:
- NEXT_PUBLIC_ONCHAINKIT_PROJECT_NAME
- NEXT_PUBLIC_ONCHAINKIT_API_KEY=
- NEXT_PUBLIC_SPLASH_IMAGE_URL
- NEXT_PUBLIC_SPLASH_BACKGROUND_COLOR
- NEXT_PUBLIC_IMAGE_URL
- NEXT_PUBLIC_ICON_URL
- NEXT_PUBLIC_VERSION=next
- REDIS_URL=
- REDIS_TOKEN=
- FARCASTER_HEADER
- FARCASTER_PAYLOAD
- FARCASTER_SIGNATURE
- NEXT_PUBLIC_URL

4. Run the development server
```bash
yarn dev
```

Visit `http://localhost:3000` to see the app.

## 📐 Architecture

### Smart Contract
- Located in `/contracts/BasePool.sol`
- Deployed on Base: [0xF9f40e4a0d85A5F6aE758E4C40623A62EFC943f3](https://basescan.org/address/0xF9f40e4a0d85A5F6aE758E4C40623A62EFC943f3)
- Handles:
  - Number assignment
  - Pool management
  - Random number generation via Pyth Network
  - Prize distribution
  - Automatic pool reset

### Frontend Components
- `app/components/basepool.tsx`: Main game component
- `app/components/PoolModal.tsx`: Pool status display
- `app/components/WarningModal.tsx`: Wallet connection warnings
- `app/lib/contract.ts`: Contract configuration and types

### Features
- Real-time pool status updates
- Automatic Farcaster sharing on participation
- Mobile-responsive design
- Wallet integration with error handling
- Transaction status notifications

## 🔒 Security

- Contract verified on BaseScan
- Uses Pyth Network for secure randomness
- Emergency withdrawal system
- Standard security practices implementation

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Coinbase MiniKit](https://docs.base.org/building-with-base/guides/tools-and-resources/minikit)
- [Base Network](https://base.org)
- [Pyth Network](https://pyth.network)
- [Farcaster](https://www.farcaster.xyz)

## 🔗 Links

- [Live Demo](https://basepool.miniapps.zone)
- [Contract on BaseScan](https://basescan.org/address/0xF9f40e4a0d85A5F6aE758E4C40623A62EFC943f3)
