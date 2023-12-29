-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListStorageLocationChange
-- Description: Processes a ListStorageLocationChange event by decoding the
--              list storage location and updating the corresponding fields in
--              the list_nfts table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the NFT.
--   - p_token_id (BIGINT): The unique identifier of the NFT.
--   - p_list_storage_location (VARCHAR(174)): The list storage location to be
--                                             decoded and updated.
-- Returns: VOID
-- Notes: Uses the list_nfts and decode__list_storage_location functions for
--        storage and decoding respectively.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListStorageLocationChange (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_token_id BIGINT,
  p_list_storage_location VARCHAR(174)
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    -- {version, location_type, chain_id, contract_address, nonce}
    decoded_location types.efp_list_storage_location__v001__location_type_001;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);

    -- Decode the list storage location
    -- TODO: need to robustly handle list location versions, location_types
    decoded_location := public.decode__efp_list_storage_location__v001__location_type_001(p_list_storage_location);

    -- Update list_nfts with the decoded values
    UPDATE public.list_nfts nft
    SET
        list_storage_location = p_list_storage_location,
        list_storage_location_chain_id = decoded_location.chain_id,
        list_storage_location_contract_address = decoded_location.contract_address,
        list_storage_location_nonce = decoded_location.nonce
    WHERE
        nft.chain_id = p_chain_id
        AND nft.contract_address = normalized_contract_address
        AND nft.token_id = p_token_id;
END;
$$;

-- migrate:down
