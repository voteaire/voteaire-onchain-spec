# Validation Queries
This directory contains queries which can be run against dbsync to query the results of a ballot proposal and validate the results you see in the front end. You need to have access to a running instance of cardano-node-db-sync to fetch transaction metadata.

## base views
The base views script ```base_views.sql``` provides a base to navigate the results of any given poll and also to validate its results, you must run this script first before executing any of the other validation queries

The views created are:
* Choices
* Proposals
* Questions
* Votes
* votes_raw

These views contain all the metadata extracted from the transactions on the blockchain that match our schemas. You can query any of them in order to extract the information you need.

In order to query the results of any proposal we need two important pieces of information, the ***type*** of the proposal and its ***id***.

If you don't know the proposal id you can take a look into the ***proposals*** view created previously and find it manually. Additionally you can look at the url of the Voteaire results page of the proposal to find the id. https://voteaire.io/results/[proposal_id]

With the ***type*** and ***id*** of the proposal you can select the appropriate script from this directory and add the proper ***id*** to it. executing this query will enable you to verify all the voting data associated to the proposal.

if the proposal you are trying to validate is of the type "policy ID" make sure you run the policyid_snapshot.sql script first.
