#!/bin/bash

# Deploy Feed the Future Contract to Solana Devnet
set -e

echo "🚀 Deploying Feed the Future to Solana Devnet..."

# Source cargo environment
source "$HOME/.cargo/env"

# Check if Solana CLI is available
if ! command -v solana &> /dev/null; then
    echo "❌ Solana CLI not found. Please install Solana CLI."
    exit 1
fi

# Switch to devnet
echo "📡 Switching to Devnet..."
solana config set --url devnet

# Show current configuration
echo "📋 Current Solana Configuration:"
solana config get

# Check wallet balance
echo "💰 Wallet Balance:"
solana balance

# Get sufficient devnet SOL if needed
BALANCE=$(solana balance | grep -o '[0-9.]*' | head -1)
if (( $(echo "$BALANCE < 2" | bc -l) )); then
    echo "⚠️  Balance is low. Requesting devnet SOL..."
    solana airdrop 5
    echo "✅ Airdrop completed"
fi

# Build the program
echo "🔨 Building program..."
cd programs/feed-the-future
cargo build-bpf --manifest-path=Cargo.toml --bpf-out-dir=../../target/deploy

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Deploy to devnet
echo "🚀 Deploying to Devnet..."
cd ../..

# Try to deploy with anchor if available
if command -v anchor &> /dev/null; then
    anchor deploy --provider.cluster devnet
else
    echo "⚠️  Anchor CLI not available. Manual deployment required."
    echo "📦 Program built at: target/deploy/feed_the_future.so"
    echo "🔑 Program ID: B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p"
    echo ""
    echo "To deploy manually:"
    echo "1. Create a new keypair: solana-keygen new --outfile ~/.config/solana/feed_the_future.json"
    echo "2. Deploy program: solana program deploy target/deploy/feed_the_future.so --program-id ~/.config/solana/feed_the_future.json"
    echo "3. Update the program ID in lib.rs and Anchor.toml"
fi

echo "🎉 Devnet deployment process completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Update your Flutter app to use the deployed Program ID"
echo "2. Test the contract functions on Devnet"
echo "3. Monitor with Solana Explorer: https://explorer.solana.com/?cluster=devnet"
