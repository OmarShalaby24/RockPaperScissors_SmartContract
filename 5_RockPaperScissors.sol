// SPDX-License-Identifier: GPL-3.0
//pragma solidity ^0.8.4;
pragma solidity >=0.7.0 <0.9.0;

contract RockPaperScissors{
    address payable player1_addr;
    address payable player2_addr;
    
    bool ended;
    address winner;
    bool tie;
    uint public reward;

    mapping(address=>bytes32) public commitments;
    mapping(address=>bool) public committed;
    mapping(address=>bool) public revealed;
    mapping(address=>uint) public decisions;
    mapping(address=>uint) public rewards;


    uint public revealingEnd;                   //customizable


    error InvalidReveal();
    error TooEarly(uint time);  
    error TooLate(uint time);

    modifier NonZeroReward(uint value){
        require(value>0, "need to pay a real reward");
        _;
    }
    modifier checkAddress(address caller){
        require(caller == player1_addr || caller == player2_addr,"you are not a participant");
        _;
    }
    modifier onlyBefore(uint time){
        if (block.timestamp >= time) revert TooLate(time);
        _;                                                                                  //no idea
    }
    modifier onlyAfter(uint time){
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor (
    address payable participant_1,
    address payable participant_2
    ) 
    payable
    NonZeroReward(msg.value)
    {
        player1_addr = participant_1;
        player2_addr = participant_2;
        reward = msg.value;

    }

    //this function is only used for testing. don't use it in the contract
    function Generate_Commitmint(string calldata decision, string calldata nonce)
    external
    view
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender,decision,nonce));
    }

    function MakeCommitment(bytes32 commitment)
    external
    checkAddress(msg.sender)
    {
        if(!committed[msg.sender]){
            commitments[msg.sender] = commitment;
            committed[msg.sender] = true;
        }
        if(committed[player1_addr] && committed[player2_addr]){
            revealingEnd = block.timestamp + 60*3;
        }
            
    }

    function Reveal(string calldata decision, string calldata nonce)
    external
    onlyBefore(revealingEnd)
    {
        if(commitments[msg.sender] == keccak256(abi.encodePacked(msg.sender,decision,nonce))){
            revealed[msg.sender] = true;
            if(keccak256(abi.encodePacked(decision)) == keccak256(abi.encodePacked("rock"))){
                decisions[msg.sender] = 1;
            }
            else if(keccak256(abi.encodePacked(decision)) == keccak256(abi.encodePacked("paper"))){
                decisions[msg.sender] = 2;
            }
            else if(keccak256(abi.encodePacked(decision)) == keccak256(abi.encodePacked("scissors"))){
                decisions[msg.sender] = 3;
            }
            if(revealed[player1_addr] && revealed[player2_addr] && !ended){
                ended = true;                                       //prevent double revealing and winning
                revealingEnd = 0;
                fight(decisions[player1_addr], decisions[player2_addr]);
                
            }
        }
        else revert InvalidReveal();
    }

    function withdraw()
    external
    onlyAfter(revealingEnd)
    {
        if (revealed[player1_addr] && !revealed[player2_addr]){
            Player1_wins();
            ended = true;
        }
        else if(!revealed[player1_addr] && revealed[player2_addr]){
            Player2_wins();
            ended = true;
        }
        uint amount = rewards[msg.sender];
        if(amount>0){
            rewards[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function fight(uint d1, uint d2)
    internal
    {
        if(d1 == d2){
            tie_();
        }
        if (d1 == 1){
            if (d2 == 2){                                       //          rock        paper
                Player2_wins();
            }
            else if (d2 == 3){                                  //          rock        scissors
                Player1_wins();
            }
        }
        else if (d1 == 2){
            if (d2 == 3){                                       //          paper       scissors
                Player2_wins();
            }
            else if (d2 == 1){                                  //          paper       rock
                Player1_wins();
            }
        }
        else if (d1 == 3){
            if (d2 == 1){                                       //          scissors    rock
                Player2_wins();
            }
            else if (d2 == 2){                                  //          scissors    paper
                Player1_wins();
            }
        }
    }

    function Player1_wins()
    internal
    {
        tie = false;
        winner = player1_addr;
        rewards[player1_addr] = reward;
        rewards[player2_addr] = 0;
        reward = 0;

    }
    function Player2_wins()
    internal
    {
        tie = false;
        winner = player2_addr;
        rewards[player1_addr] = 0;
        rewards[player2_addr] = reward;
        reward = 0;

    }

    function tie_()
    internal
    {
        tie = true;
        winner = address(0);
        rewards[player1_addr] = reward/2;
        rewards[player2_addr] = reward/2;
        reward = 0;
    }
}