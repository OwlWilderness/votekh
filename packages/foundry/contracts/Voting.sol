// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//@notice imports
import { console2 } from "../lib/forge-std/src/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//@title Voting 
//@author quantumtekh.eth
//@notice Token Voting Contract - ETH Tech Tree challenge
//@notice smart contract that allows token holders to vote on a specific proposal.

//@notice voting contract
contract Voting{
    //@notice constuctor
    //@param address _tokenAddress - governance token address
    //@param uint256 _endBlockTimestamp - timestamp to end voting
    constructor(address _tokenAddress, uint256 _endBlockTimestamp){
        govToken = IERC20(_tokenAddress);
        voteOpenUntilBlockTimestamp = _endBlockTimestamp;
    }

    //@dev variables set in constructor
    IERC20  public  govToken;                               //governance token
    uint256 public  voteOpenUntilBlockTimestamp;            //Block Timestamp Voting Ends


    //@dev variables vote management 
    uint256 private totalVotesFor;                          //total votes for weight
    uint256 private totalVotesAgainst;                      //total votes against weight
    mapping(address => bool) public HasVoted;               //voter has voted
    mapping(address => uint256) public AddressVotesFor;     //voter for weight
    mapping(address => uint256) public AddressVotesAgainst; //voter against weight


    //@dev errors
    error Voting_ZeroGovernanceTokenBalance();              //sender has no voting token 
    error Voting_VoterAlreadyVoted();                       //sender already voted
    error Voting_VotingPeriodEnded();                       //voting period aready closed
                                                            // now > voteOpenPeriod                                                        
    error Voting_InvalidGovernanceTokenAddress();           //invalid drtoken contract address
    error Voting_VotePeriodHasNotEnded();                   //voting period not closed yet
                                                            // now <= voteOpenPeriod

    //@dev public view functions

    //@notice get votes for
    //@return uint256 total votes for proposal
    function votesFor() public view returns(uint256){
        return totalVotesFor;
    }

    //@notice get votes against
    //@return uint256 total votes against proposal
    function votesAgainst() public view returns(uint256){
        return totalVotesAgainst;
    }

    //@notice This function should revert if the vote period is not over yet. 
    //@notice It should return true or false depending on whether a simple majority is reached
    //@return bool proposal passed (votesFor > votesAgainst)
    function getResult() public view voteMustBeClosed returns(bool) {
        return totalVotesFor > totalVotesAgainst;
    }

    //@dev events
    event VoteCasted(address voter, bool vote, uint256 weight);
    event VotesRemoved(address voter, uint256 weight);

    //@dev modifiers
    
    //@notice revert if vote is closed
    modifier voteMustBeOpen(){
        //revert if voting period complete
        if(block.timestamp > voteOpenUntilBlockTimestamp){
            revert Voting_VotingPeriodEnded();   
        }
        _;
    }

    //@notice revert if vote is still open
    modifier voteMustBeClosed(){
        //revert if voting period not complete
        if(block.timestamp <= voteOpenUntilBlockTimestamp){
            revert Voting_VotePeriodHasNotEnded();   
        }
        _;
    }
    
    //@notice Define a function called vote that receives a bool as a parameter. 
    //@notice The bool represents whether the caller is voting "For" or "Against" the proposal.
    //@param bool _voteFor
    function vote(bool _voteFor) public voteMustBeOpen {
        
        //get sender voting weight
        uint256 weight = govToken.balanceOf(msg.sender);

        //revert if sender has no governance tokens
        if(weight == 0){
            revert Voting_ZeroGovernanceTokenBalance();
        }

        //revert if sender has already voted
        if(HasVoted[msg.sender]){
            revert Voting_VoterAlreadyVoted();
        }

        //update mappings and increment vote counter
        HasVoted[msg.sender] = true;
        if(_voteFor){
            AddressVotesFor[msg.sender] += weight;
            totalVotesFor += weight;
        }else{
            AddressVotesAgainst[msg.sender] += weight;
            totalVotesAgainst += weight;
        }

        emit VoteCasted(msg.sender, _voteFor, weight);
    }

    //@notice Define a function called removeVotes(address from) that receives an address. 
    //@notice The function should completely remove that addresses votes so that it is as if they never voted.
    //@param address voter
    function removeVotes(address voter) external voteMustBeOpen {
        //revert if not called from token contract
        if(msg.sender != address(govToken)){
            revert Voting_InvalidGovernanceTokenAddress();
        }

        //get voter vote weight
        uint256 weight = AddressVotesFor[voter] + AddressVotesAgainst[voter];

        //update totalVotesAgainst
        totalVotesFor -= AddressVotesFor[voter];
        totalVotesAgainst -= AddressVotesAgainst[voter];

        //reset vote weights and hasvoted for address
        AddressVotesFor[voter] = 0;
        AddressVotesAgainst[voter] = 0;
        HasVoted[voter] = false;
        
        emit VotesRemoved(voter, weight);
    }
}

//@notice test results
//  Ran 11 tests for test/Voting.t.sol:VotingTest
//  [PASS] testGetResultBeforeDeadline() (gas: 168601)
//  [PASS] testNoTokensToVote() (gas: 19589)
//  [PASS] testNotVotingCotractAddressCantCallRemoval() (gas: 177377)
//  [PASS] testTieVotingResult() (gas: 171941)
//  [PASS] testVoteAfterDeadline() (gas: 14315)
//  [PASS] testVoteRemovalOnTransfer() (gas: 97812)
//  [PASS] testVotingAgainst() (gas: 98793)
//  [PASS] testVotingFor() (gas: 98801)
//  [PASS] testVotingResultApproved() (gas: 169514)
//  [PASS] testVotingResultRejected() (gas: 171983)
//  Suite result: ok. 11 passed; 0 failed; 0 skipped; finished in 1.52ms (1.62ms CPU time)
//  
//  Ran 1 test suite in 317.69ms (1.52ms CPU time): 11 tests passed, 0 failed, 0 skipped (11 total tests)