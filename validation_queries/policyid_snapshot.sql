------------------------------------------------------------------------------------
-- PolicyID Snapshot
--  this query must be run prior to running the vote_results_policyid.sql script
--  it takes a proposal_id as input and will take a snapshot for the associated
--  policyid an epoch
--  WARNING: this may take a while to run, depending on the power of your dbsync
--   instance, sometimes upwards of 10-30 minutes depending on the number of assets
--   in the policy.
--  NOTE: this assumes a single policy id associted with the ballot proposal
-------------------------------------------------------------------------------------

-- first take snapshot of assets at proper epoch
-- WARNING, this may take a while depending on the power of your dbsync instance
drop table tmp_voteaire_snapshot;

WITH constants as (
    select snapshot_epoch::int as epoch_no,
	policy_id as policyid
    from voteaire_proposals
    where proposal_id = 'c3e7e1cc-f5e1-4144-8a36-0da025c37d76'
)
select 
    b.block_no,
    b.epoch_no,
    b.time,
    encode(tx.hash, 'hex') as tx_hash,
    o.address, 
    o.stake_address_id,
    o.address_has_script,
    convert_from(ma.name, 'utf8') as token_name,
    mo.quantity,
    encode(ma.policy, 'hex') as policy,
    sa.view as stake_address
into tmp_voteaire_snapshot
from tx_out o
    inner join constants c on true
    inner JOIN tx ON tx.id = o.tx_id
    LEFT JOIN block b ON tx.block_id = b.id
    inner join ma_tx_out mo on o.id = mo.tx_out_id
    inner join multi_asset ma on mo.ident = ma.id
    left join stake_address sa on o.stake_address_id = sa.id
    -- associated txs where these outputs are used as inputs - filtered by transaction before or during our desired epoch
    LEFT JOIN (
        select i.id, i.tx_in_id, i.tx_out_id, i.tx_out_index, bi.epoch_no
        from tx_in i 
            LEFT JOIN tx txi ON txi.id = i.tx_in_id
            LEFT JOIN block bi ON txi.block_id = bi.id
    ) i ON o.tx_id = i.tx_out_id AND o.index::smallint = i.tx_out_index::smallint and i.epoch_no < c.epoch_no -- will take snapshot at the beginning of the epoch (end of the previous epoch)

where  i.tx_in_id IS NULL -- where it's not already spent
    and encode(ma.policy, 'hex') = c.policyid
    -- filter to only outputs created before or during our desired epoch
    and b.epoch_no < c.epoch_no  -- will take snapshot at the beginning of the epoch (end of the previous epoch)
order by stake_address_id;