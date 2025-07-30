# Adding New Chain Support to EFP Indexer

This guide outlines the steps required to add support for indexing EFP contract events on a new blockchain network.

## Prerequisites

- The new chain must be EVM-compatible with JSON-RPC support
- An unmodified EFP List Records contract must be deployed on the target chain
- RPC endpoints (primary and secondary) for the new chain must be available

## Required Changes

### 1. Update Viem Client Configuration

**File:** `src/clients/viem/index.ts`

Add a new client configuration for your chain:

```typescript
import { newChain } from 'viem/chains' // Import your chain from viem/chains

export const evmClients = {
  // ... existing clients
  'CHAIN_ID': () =>
    createPublicClient({
      key: 'new-chain-client',
      name: 'New Chain Client', 
      chain: newChain,
      transport: fallback([http(env.PRIMARY_RPC_NEW), http(env.SECONDARY_RPC_NEW)], { rank: false }),
      batch: { multicall: true }
    }).extend(walletActions)
}
```

### 2. Update Environment Variable Types

**File:** `environment.d.ts`

Add the new chain ID to the allowed CHAIN_ID values:

```typescript
interface EnvironmentVariables {
  readonly CHAIN_ID: '1' | '10' | '8453' | 'NEW_CHAIN_ID' // Add your chain ID
  // Add RPC endpoint variables:
  readonly PRIMARY_RPC_NEW: string
  readonly SECONDARY_RPC_NEW: string
  // ... existing variables
}
```

### 3. Update Environment Configuration

**File:** `src/env.ts`

Add RPC endpoint configuration for the new chain:

```typescript
export const env = Object.freeze({
  // ... existing config
  PRIMARY_RPC_NEW: getEnvVariable('PRIMARY_RPC_NEW'),
  SECONDARY_RPC_NEW: getEnvVariable('SECONDARY_RPC_NEW'),
})
```

### 4. Update Docker Compose (Optional)

**File:** `compose.yml`

If running via Docker, add environment variables for the new chain:

```yaml
environment:
  - PRIMARY_RPC_NEW=${PRIMARY_RPC_NEW}
  - SECONDARY_RPC_NEW=${SECONDARY_RPC_NEW}
  - EFP_CONTRACT_LIST_RECORDS=${EFP_CONTRACT_LIST_RECORDS_NEW}
```

## Environment Variables Required

Set these environment variables in your `.env` file:

```bash
# Chain Configuration
CHAIN_ID=NEW_CHAIN_ID

# RPC Endpoints
PRIMARY_RPC_NEW=https://your-primary-rpc-endpoint
SECONDARY_RPC_NEW=https://your-secondary-rpc-endpoint

# Contract Addresses (after deployment)
EFP_CONTRACT_ACCOUNT_METADATA=0x...
EFP_CONTRACT_LIST_REGISTRY=0x...
EFP_CONTRACT_LIST_RECORDS=0x...

# Other required variables
DATABASE_URL=postgresql://...
START_BLOCK=1234567
BATCH_SIZE=1000
RECOVER_HISTORY=false
HEARTBEAT_URL=optional
RECORDS_ONLY=false
```

## Database Considerations

**No database schema changes are required.** The existing schema already supports multiple chains:

- The `events` table uses `chain_id` field to differentiate between chains
- All EFP-related tables include `chain_id` for multi-chain support
- Database functions and views handle chain-specific queries automatically

## Contract Deployment Requirements

The **EFP List Records Contract** must be deployed on the new chain

**Important:** Use the same contract implementations as existing chains. Do not modify the contract code, as this could break event processing.

## Testing the Integration

1. **Start the database:**
   ```bash
   bun database
   ```

2. **Set environment variables for the new chain**

3. **Run the indexer:**
   ```bash
   bun dev
   ```

4. **Verify connectivity:**
   - Check logs for successful RPC connection
   - Confirm database migration completion
   - Watch for event processing from the new chain

## Common Issues and Solutions

### RPC Connection Issues
- Verify RPC endpoints are accessible and support required methods
- Check if RPC has rate limiting that might affect batch requests
- Ensure WebSocket support if using WebSocket transport

### Contract Event Issues  
- Confirm contract addresses are correct for the target chain
- Verify contracts were deployed with expected ABIs
- Check that START_BLOCK is set to the deployment block or earlier

### Chain ID Conflicts
- Ensure the chain ID doesn't conflict with existing supported chains
- Verify chain ID in environment matches the actual network chain ID

## Architecture Notes

The indexer is designed to be chain-agnostic:

- **Event Processing:** The same event processing pipeline works for any EVM chain
- **Contract Interaction:** Uses standard viem clients for blockchain interaction
- **Database Storage:** Multi-chain support is built into the schema from the ground up
- **Configuration:** Chain-specific settings are externalized to environment variables

The indexer automatically:
- Handles chain reconnection and fault tolerance
- Processes events in chronological order across all configured contracts
- Stores chain-specific metadata for proper data segregation
- Supports running in "records only" mode for reduced resource usage

## Support

After adding a new chain, the indexer will:
- Start processing events from the START_BLOCK
- Handle historical event recovery if RECOVER_HISTORY=true
- Provide the same API functionality as existing chains
- Support all existing database views and functions for the new chain data