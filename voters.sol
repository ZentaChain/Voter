// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract ChainVoting is Ownable {
   mapping(address=> Voter) _voterRegister;
   mapping(uint => Proposal) _proposalRegistered;
   
   uint[]_proposalIds;
   
   enum WorkflowStatus  {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    uint public winningProposalId;
    WorkflowStatus public workflowStatus = WorkflowStatus.RegisteringVoters;
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);
  
   function voterRegister(address voterAddress) public  {
       require(msg.sender == owner(), "You  are not the admin");
       require(workflowStatus == WorkflowStatus.RegisteringVoters, "Registering Voters are close");
       
       Voter memory voter;
       voter.isRegistered = true;
       voter.hasVoted = false;
       
       _voterRegister[voterAddress] = voter;
       
       emit VoterRegistered(voterAddress); 
    }
   
   function workflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus) internal {
       workflowStatus = newStatus;
       emit WorkflowStatusChange(previousStatus, newStatus);
    }
    
   function proposalRegistered(uint proposalId, string memory description) public {
       require(_voterRegister[msg.sender].isRegistered == true, "You  are not registered");
       require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Registering proposal are close");
       
       Proposal memory proposal;
       proposal.description = description;
       proposal.voteCount = 0;
       
       _proposalRegistered[proposalId] = proposal;
       _proposalIds.push(proposalId);
       emit ProposalRegistered(proposalId);
    }
    
   function proposalsRegistrationStarted() public {
       workflowStatusChange(WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
       emit ProposalsRegistrationStarted();
    }
    
   function proposalsRegistrationEnded() public{
       workflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
       emit ProposalsRegistrationEnded();
    }
   function votingSessionStarted() public{
       workflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded,WorkflowStatus.VotingSessionStarted);
       emit VotingSessionStarted();
    }
    
   function votingSessionEnded() public{
       workflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
              uint i;
       uint _winningProposalId = 0;
       if(_proposalIds.length > 1){
             for(i = 1;i < _proposalIds.length; i++ ){
               if(_winningProposalId != 0){
                   if(_proposalRegistered[_proposalIds[i]].voteCount > _proposalRegistered[_proposalIds[i-1]].voteCount ){
                   _winningProposalId = _proposalIds[i];
                       
                   }
               }else
                {
                   if(_proposalRegistered[_proposalIds[i]].voteCount > _proposalRegistered[_winningProposalId].voteCount ){
                   _winningProposalId = _proposalIds[i];

                }
            }
        }
        
       }else{
           _winningProposalId = _proposalIds[0];
       }
       
       winningProposalId = _winningProposalId;
       emit VotingSessionEnded();
   }
   
   function voted (address voter, uint proposalId) public{
       require(_voterRegister[voter].isRegistered == true, "You  are not registered");
       require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Voting are close");
       _voterRegister[voter].votedProposalId = proposalId;
       _proposalRegistered[proposalId].voteCount++;
       _voterRegister[voter].hasVoted = true;
       
       emit Voted(voter,proposalId);
    }
   
   function votesTallied() public returns(Proposal memory) {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Voting Session not end");
       workflowStatusChange(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
       emit VotesTallied();
       return _proposalRegistered[winningProposalId];
    }
}
