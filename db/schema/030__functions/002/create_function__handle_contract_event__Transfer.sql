-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__Transfer
-- Description: Processes a transfer event by either inserting a new NFT into
--              the efp_list_nfts table or updating the owner of an existing
--              NFT. It throws an error if a duplicate insertion is attempted
--              for a new NFT (identified by 'from' address being '0x0').
--              For updates, it changes the owner of the NFT to the 'to'
--              address.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the NFT.
--   - p_token_id (BIGINT): The unique identifier of the NFT.
--   - p_from_address (VARCHAR(42)): The sender's address of the transfer.
--   - p_to_address (VARCHAR(42)): The receiver's address of the transfer.
-- Returns: VOID
-- Notes: Addresses are normalized to lowercase. Uses the efp_list_nfts table
--        for storage. Relies on external normalization functions for address
--        format validation.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__Transfer (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_token_id types.efp_list_nft_token_id,
  p_from_address VARCHAR(42),
  p_to_address VARCHAR(42)
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_from_address types.eth_address;
    normalized_to_address types.eth_address;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_from_address := public.normalize_eth_address(p_from_address);
    normalized_to_address := public.normalize_eth_address(p_to_address);

    IF normalized_from_address = '0x0000000000000000000000000000000000000000' THEN
        -- Insert new row
        INSERT INTO public.efp_list_nfts (
            chain_id,
            contract_address,
            token_id,
            owner
        )
        VALUES (
            p_chain_id,
            normalized_contract_address,
            p_token_id,
            normalized_to_address
        )
        ON CONFLICT (chain_id, contract_address, token_id) DO NOTHING;

        INSERT INTO public.efp_lists (
            nft_chain_id,
            nft_contract_address,
            token_id,
            owner,
            manager,
            "user"
        )
        VALUES (
            p_chain_id,
            normalized_contract_address,
            p_token_id,
            normalized_to_address,
            '0x0000000000000000000000000000000000000000'::types.eth_address,
            '0x0000000000000000000000000000000000000000'::types.eth_address
        )
        ON CONFLICT (nft_chain_id, nft_contract_address, token_id) DO NOTHING;

    ELSE
        -- Update existing row
        UPDATE public.efp_list_nfts
        SET owner = normalized_to_address
        WHERE chain_id = p_chain_id
        AND contract_address = normalized_contract_address
        AND token_id = p_token_id;

        -- Update existing row
        UPDATE public.efp_lists 
        SET owner = normalized_to_address
        WHERE nft_chain_id = p_chain_id
        AND nft_contract_address = normalized_contract_address
        AND token_id = p_token_id;
    END IF;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__Transfer
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__Transfer (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_token_id types.efp_list_nft_token_id,
    p_from_address VARCHAR(42),
    p_to_address VARCHAR(42)
  ) CASCADE;