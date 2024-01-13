-- migrate:up
-------------------------------------------------------------------------------
-- Trigger Function: handle_contract_event
-- Description: Processes a blockchain event as a trigger when a new event is
--              inserted into the events table. This function acts as a
--              dispatcher, calling specific event handler functions based on
--              the event type.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Use the NEW record to access the inserted row's data
    CASE NEW.event_name
        WHEN 'ListOp' THEN
            -- Call the specific handler for ListOp events
            PERFORM public.handle_contract_event__ListOp(
                NEW.chain_id,
                NEW.contract_address,
                DECODE(SUBSTRING(NEW.event_args->>'slot' FROM 3), 'hex')::types.efp_list_storage_location_slot,
                (NEW.event_args->>'op')::types.hexstring
            );
        WHEN 'OwnershipTransferred' THEN
            -- Call the specific handler for OwnershipTransferred events
            PERFORM public.handle_contract_event__OwnershipTransferred(
                NEW.chain_id,
                NEW.contract_address,
                -- NEW.contract_name,
                NULL,
                public.normalize_eth_address(NEW.event_args->>'previousOwner'),
                public.normalize_eth_address(NEW.event_args->>'newOwner')
            );

        WHEN 'Transfer' THEN
            -- Call the specific handler for Transfer events
            PERFORM public.handle_contract_event__Transfer(
                NEW.chain_id,
                NEW.contract_address,
                (NEW.event_args->>'tokenId')::types.efp_list_nft_token_id,
                public.normalize_eth_address(NEW.event_args->>'from'),
                public.normalize_eth_address(NEW.event_args->>'to')
            );

        WHEN 'UpdateAccountMetadata' THEN
            -- Call the specific handler for UpdateAccountMetadata events
            PERFORM public.handle_contract_event__UpdateAccountMetadata(
                NEW.chain_id,
                NEW.contract_address,
                public.normalize_eth_address(NEW.event_args->>'addr'),
                NEW.event_args->>'key',
                (NEW.event_args->>'value')::types.hexstring
            );

        WHEN 'UpdateListMetadata' THEN
            -- Call the specific handler for UpdateListMetadata events
            PERFORM public.handle_contract_event__UpdateListMetadata(
                NEW.chain_id,
                NEW.contract_address,
                DECODE(SUBSTRING(NEW.event_args->>'slot' FROM 3), 'hex')::types.efp_list_storage_location_slot,
                NEW.event_args->>'key',
                (NEW.event_args->>'value')::types.hexstring
            );

        WHEN 'UpdateListStorageLocation' THEN
            -- Call the specific handler for UpdateListStorageLocation events
            PERFORM public.handle_contract_event__UpdateListStorageLocation(
                NEW.chain_id,
                NEW.contract_address,
                (NEW.event_args->>'tokenId')::types.efp_list_nft_token_id,
                NEW.event_args->>'listStorageLocation'
            );

        ELSE
            -- Raise an exception if the event name is unrecognized
            -- RAISE EXCEPTION 'Unrecognized event name: %', NEW.event_name;
    END CASE;

    -- Always return NEW for AFTER triggers
    RETURN NEW;
END;
$$;



-------------------------------------------------------------------------------
-- Trigger: events_insert_trigger
-- Description: Trigger to handle new event entries in the events table.
--              It is fired after each insert operation on the events table.
-------------------------------------------------------------------------------
CREATE TRIGGER
  events_insert_trigger
AFTER
INSERT
  ON public.events FOR EACH ROW
EXECUTE
  FUNCTION public.handle_contract_event();



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Trigger: events_insert_trigger
-------------------------------------------------------------------------------
DROP TRIGGER
  IF EXISTS events_insert_trigger ON public.events CASCADE;



-------------------------------------------------------------------------------
-- Undo Trigger Function: handle_contract_event
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event() CASCADE;