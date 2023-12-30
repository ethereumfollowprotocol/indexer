-- migrate:up
-- Table Creation: Define all necessary tables
SET
  default_tablespace = '';



SET
  default_table_access_method = HEAP;



-------------------------------------------------------------------------------
-- Table: contract_events
-------------------------------------------------------------------------------
CREATE TABLE public.contract_events (
  chain_id types.eth_chain_id NOT NULL,
  block_number BIGINT NOT NULL,
  transaction_index NUMERIC NOT NULL,
  log_index NUMERIC NOT NULL,
  contract_address types.eth_address NOT NULL,
  event_name VARCHAR(255) NOT NULL,
  event_args jsonb NOT NULL,
  block_hash types.eth_block_hash NOT NULL,
  transaction_hash types.eth_transaction_hash NOT NULL,
  sort_key TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    block_number,
    transaction_index,
    log_index
  )
);



COMMENT ON TABLE public.contract_events IS 'Stores EFP contract events across multiple blockchains.';



COMMENT ON COLUMN public.contract_events.chain_id IS 'Identifier for the blockchain network where the event occurred. This includes mainnets, testnets, and Layer 2 networks.';



COMMENT ON COLUMN public.contract_events.block_number IS 'The block number on the blockchain where the event was recorded.';



COMMENT ON COLUMN public.contract_events.transaction_index IS 'Index of the transaction within the block that emitted the event.';



COMMENT ON COLUMN public.contract_events.log_index IS 'Index of the log entry within the transaction, unique to each event.';



COMMENT ON COLUMN public.contract_events.contract_address IS 'Address of the contract that emitted the event.';



COMMENT ON COLUMN public.contract_events.event_name IS 'Name of the event as specified in the contract.';



COMMENT ON COLUMN public.contract_events.event_args IS 'JSON object containing arguments passed to the event.';



COMMENT ON COLUMN public.contract_events.block_hash IS 'Hash of the block in which the event was recorded.';



COMMENT ON COLUMN public.contract_events.transaction_hash IS 'Hash of the transaction in which the event was emitted.';



COMMENT ON COLUMN public.contract_events.created_at IS 'Timestamp when the record was created in the database.';



COMMENT ON COLUMN public.contract_events.updated_at IS 'Timestamp when the record was last updated in the database.';



-------------------------------------------------------------------------------
-- Triggers
-------------------------------------------------------------------------------
CREATE TRIGGER trigger__contract_events__update_updated_at_column BEFORE
UPDATE ON public.contract_events FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-- Comment on the trigger
COMMENT ON TRIGGER trigger__contract_events__update_updated_at_column ON public.contract_events IS 'Trigger to automatically update the updated_at timestamp column before any update operation on the contract_events table.';



-------------------------------------------------------------------------------
-- Indexes
-------------------------------------------------------------------------------
CREATE INDEX idx__contract_events__event_name ON public.contract_events (event_name);



COMMENT ON INDEX public.idx__contract_events__event_name IS 'Index on event_name to optimize queries filtering by specific event names in contract_events table.';



-- migrate:down