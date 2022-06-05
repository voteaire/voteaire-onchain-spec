---------------------------------------------------------------------------
-- BASE VIEWS
--  These are the base views required to run the validation queries
--  they are also useful if you want to explore the results
--  run this script prior to running any others in this directory
---------------------------------------------------------------------------

-------------------------------------------------------------
-- proposals
--  note this view assumes only one policyid per proposal
--  although the spec allows multiple
-------------------------------------------------------------

-- drop view voteaire_proposals;
create or replace view voteaire_proposals 
as
select 
    json ->> 'Title' as title,
    json ->> 'NetworkId' as network,
    json -> 'BallotType' ->> 'Name' as ballot_type,
    json -> 'BallotType' -> 'PolicyId'->>0 as policy_id,
    json -> 'BallotType' ->> 'PoolId' as pool_id,
    json ->> 'ProposalId' as proposal_id,
    json ->> 'VoteStartEpoch' as vote_start_epoch,
    json ->> 'VoteEndEpoch' as vote_end_epoch,
    json ->> 'SnapshotEpoch' as snapshot_epoch,
    json
from tx_metadata tm
where key = 1916
    and json ->> 'ObjectType' = 'BallotProposal';

-------------------------------------------------------------
-- questions
-------------------------------------------------------------

-- drop view voteaire_questions;
create or replace view voteaire_questions
as
select 
	tm.json ->> 'ProposalId' as proposal_id,
	opt."QuestionId" as question_id,
	opt."Question" as question,
	opt."Choices" as choices
from tx_metadata tm,
	jsonb_to_recordset(json -> 'Questions')
		as opt("QuestionId" varchar, "Question" varchar, "Description" varchar, "Choices" jsonb)
where key = 1916
	and json ->> 'ObjectType' = 'BallotProposal';

-------------------------------------------------------------
-- choices
-------------------------------------------------------------

-- drop view voteaire_choices;
create or replace view voteaire_choices
as
select 
	q.proposal_id,
	q.question_id,
	q.question,
	opt."ChoiceId" as choice_id,
	opt."Name" as choice
from voteaire_questions q,
	jsonb_to_recordset(q.choices)
		as opt("ChoiceId" varchar, "Name" varchar, "Description" varchar);

-------------------------------------------------------------
-- raw votes
-------------------------------------------------------------

-- drop view voteaire_votes_raw;
create or replace view voteaire_votes_raw
as
select 
	tm.json ->> 'ProposalId' as proposal_id,
	tm.json ->> 'VoteId' as vote_id,
	opt."QuestionId" as question_id,
	opt."ChoiceId" as choice_id,
	tx_id
from tx_metadata tm,
	jsonb_to_recordset(json -> 'Choices')
		as opt("QuestionId" varchar, "ChoiceId" varchar)
where key = 1916
	and json ->> 'ObjectType' = 'VoteBallot';

-------------------------------------------------------------
-- votes
--  this view adds extra info such as staking address 
--  and tx info
-------------------------------------------------------------

-- drop table voteaire_votes;
create or replace view voteaire_votes
as
select 
	*, 
	row_number() over (partition by proposal_id, stake_address order by block_no asc ) as vote_num
	from (
		select distinct
		sa.view as stake_address, 
		o.stake_address_id,
		encode(tx.hash, 'hex') as tx_hash,
		v.proposal_id,
		v.vote_id,
		v.question_id,
		v.choice_id,
		b.block_no
	from voteaire_votes_raw v
		--inner join proposals p on  v.proposal_id = p.proposal_id
		inner join tx on v.tx_id = tx.id
		inner join tx_in i on tx.id = i.tx_in_id
		inner join tx_out o on o.tx_id = i.tx_out_id and i.tx_out_index = o.index
		inner join stake_address sa on o.stake_address_id = sa.id
		inner join block b on tx.block_id = b.id
) a;