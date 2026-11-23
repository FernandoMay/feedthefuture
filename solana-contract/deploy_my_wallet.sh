#!/bin/bash

# Feed the Future - Deploy to Devnet with User Wallet
# Wallet: 2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD
set -e

echo "🌱 Feed the Future - Devnet Deployment"
echo "======================================"
echo "👤 Wallet: 2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check prerequisites
print_step "Checking environment..."

# Source cargo environment
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Check Solana CLI
if ! command -v solana &> /dev/null; then
    echo "❌ Solana CLI not found. Install from: https://docs.solana.com/cli/install"
    exit 1
fi

print_success "Solana CLI: $(solana --version)"

# Configure for devnet
print_step "Configuring for Devnet..."
solana config set --url devnet
solana config set --keypair ~/.config/solana/id.json

# Show current configuration
echo ""
echo "📋 Current Configuration:"
solana config get

# Check wallet address matches
CURRENT_WALLET=$(solana address)
USER_WALLET="2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD"

if [ "$CURRENT_WALLET" != "$USER_WALLET" ]; then
    print_warning "Current wallet address doesn't match your specified wallet"
    echo "Current: $CURRENT_WALLET"
    echo "Expected: $USER_WALLET"
    echo ""
    echo "To use your wallet:"
    echo "1. Export your private key to ~/.config/solana/id.json"
    echo "2. Or set the correct keypair path in Solana config"
    echo ""
    read -p "Continue with current wallet? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "Wallet address matches!"
fi

# Check balance
print_step "Checking wallet balance..."
solana balance

# Request airdrop if needed
BALANCE=$(solana balance | grep -o '[0-9.]*' | head -1)
if [ -z "$BALANCE" ]; then
    BALANCE="0"
fi

if (( $(echo "$BALANCE < 2" | bc -l 2>/dev/null || echo "0") )); then
    print_step "Requesting devnet SOL..."
    solana airdrop 5
    print_success "Airdrop completed!"
    sleep 2
    echo "New balance:"
    solana balance
else
    print_success "Sufficient balance: $BALANCE SOL"
fi

# Build the program
print_step "Building Feed the Future contract..."
cd programs/feed-the-future

if command -v anchor &> /dev/null; then
    cd ../..
    print_step "Building with Anchor..."
    if anchor build; then
        print_success "Build completed!"
    else
        echo "❌ Anchor build failed, trying manual build..."
        cd programs/feed-the-future
        cargo build --release --target wasm32-unknown-unknown
    fi
else
    print_warning "Anchor not found, building manually..."
    cargo build --release --target wasm32-unknown-unknown
fi

if [ $? -eq 0 ]; then
    print_success "Contract built successfully!"
else
    echo "❌ Build failed!"
    exit 1
fi

cd ../..

# Deploy to devnet
print_step "Deploying to Devnet..."
PROGRAM_ID="B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p"

if command -v anchor &> /dev/null; then
    if anchor deploy --provider.cluster devnet; then
        print_success "Deployed with Anchor!"
    else
        print_warning "Anchor deploy failed, trying manual deployment..."
        MANUAL_DEPLOY=true
    fi
else
    MANUAL_DEPLOY=true
fi

# Manual deployment if needed
if [ "$MANUAL_DEPLOY" = true ]; then
    print_step "Manual deployment instructions:"
    echo ""
    echo "📦 Your program is built at: target/deploy/feed_the_future.so"
    echo ""
    echo "To deploy manually:"
    echo "1. Create program keypair:"
    echo "   solana-keygen new --outfile ~/.config/solana/feed_the_future.json --no-bip39-passphrase"
    echo ""
    echo "2. Deploy program:"
    echo "   solana program deploy target/deploy/feed_the_future.so --program-id ~/.config/solana/feed_the_future.json"
    echo ""
    echo "3. Get your new Program ID:"
    echo "   solana address -k ~/.config/solana/feed_the_future.json"
    echo ""
    echo "4. Update Program ID in:"
    echo "   - Anchor.toml"
    echo "   - lib.rs"
    echo "   - Flutter app"
fi

# Verify deployment
if [ "$MANUAL_DEPLOY" != true ]; then
    print_step "Verifying deployment..."
    if solana program show "$PROGRAM_ID" 2>/dev/null; then
        print_success "Program verified on Devnet!"
        echo ""
        echo "🔗 Solana Explorer: https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
        echo "👤 Your Wallet: https://explorer.solana.com/address/$USER_WALLET?cluster=devnet"
    else
        print_warning "Program verification failed"
    fi
fi

# Final summary
echo ""
echo "🎉 Deployment Summary"
echo "====================="
echo "Network: Devnet"
echo "Your Wallet: $USER_WALLET"
echo "Program ID: $PROGRAM_ID"
echo "Explorer: https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
echo "Wallet Explorer: https://explorer.solana.com/address/$USER_WALLET?cluster=devnet"
echo ""

echo "📱 Next Steps for Flutter:"
echo "1. Update your Flutter app with Program ID: $PROGRAM_ID"
echo "2. Configure RPC: https://api.devnet.solana.com"
echo "3. Test with your wallet: $USER_WALLET"
echo ""

print_success "Devnet setup completed! 🚀"
