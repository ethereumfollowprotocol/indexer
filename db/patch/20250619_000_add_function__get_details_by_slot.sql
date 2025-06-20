-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_details_by_slot
-- Description: This function retrieves detailed information about a specific 
--              list using its storage location slot
--              
---------------

CREATE
OR REPLACE FUNCTION query.get_list_details_by_slot ( 
    p_chain_id types.eth_chain_id,
    p_contract_address types.eth_address,
    p_slot varchar(66)
) RETURNS TABLE (
    list_chain_id bigint,
    list_contract_address TYPES.eth_address,
    list_token_id types.efp_list_nft_token_id,
    list_owner TYPES.eth_address,
    list_manager TYPES.eth_address,
    list_user TYPES.eth_address,
    list_user_name TEXT,
    list_user_avatar TEXT,
    list_user_header TEXT,
    is_primary_list BOOLEAN
) LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY
    SELECT 
        list_storage_location_chain_id AS chain_id,
        list_storage_location_contract_address AS contract_address,
        token_id,
        owner,
        manager,
        "user",
        lb.name AS user_name,
        lb.avatar AS user_avatar,
        lb.header AS user_header,
        (token_id::numeric = public.convert_hex_to_bigint(acctmeta.value)::numeric) AS is_primary_list
    FROM public.view__join__efp_lists_with_metadata listmeta
    LEFT JOIN public.efp_account_metadata acctmeta ON acctmeta.address = "user"
    LEFT JOIN public.efp_leaderboard lb ON lb.address = "user"
    WHERE listmeta.list_storage_location_slot = unhexlify(p_slot)
    AND listmeta.list_storage_location_chain_id = p_chain_id
    AND listmeta.list_storage_location_contract_address = p_contract_address
    AND acctmeta.key = 'primary-list';
END;
$$;    


-- migrate:down