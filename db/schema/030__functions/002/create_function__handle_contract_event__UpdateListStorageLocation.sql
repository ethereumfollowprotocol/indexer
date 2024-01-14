-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__UpdateListStorageLocation
-- Description: Processes a UpdateListStorageLocation event by decoding the
--              list storage location and updating the corresponding fields in
--              the list_nfts table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the NFT.
--   - p_token_id (types.efp_list_nft_token_id): The unique identifier of the
--                                               NFT.
--   - p_list_storage_location (VARCHAR(174)): The list storage location to be
--                                             decoded and updated.
-- Returns: VOID
-- Notes: Uses the list_nfts and decode__efp_list_storage_location functions
--        for storage and decoding respectively.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__UpdateListStorageLocation (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_token_id types.efp_list_nft_token_id,
  p_list_storage_location VARCHAR(174)
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    -- {version, location_type, chain_id, contract_address, slot}
    decoded_location types.efp_list_storage_location__v001__location_type_001;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);

    -- Decode the list storage location
    -- TODO: need to robustly handle list location versions, location_types
    decoded_location := public.decode__efp_list_storage_location__v001__location_type_001(p_list_storage_location);

    -- Update list_nfts with the decoded values
    UPDATE public.efp_lists l
    SET
        list_storage_location = DECODE(SUBSTRING(p_list_storage_location FROM 3), 'hex'),
        list_storage_location_chain_id = decoded_location.chain_id,
        list_storage_location_contract_address = decoded_location.contract_address,
        list_storage_location_slot = decoded_location.slot
    WHERE
        l.nft_chain_id = p_chain_id
        AND l.nft_contract_address = normalized_contract_address
        AND l.token_id = p_token_id;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__UpdateListStorageLocation
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__UpdateListStorageLocation (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_token_id BIGINT,
    p_list_storage_location VARCHAR(174)
  ) CASCADE;