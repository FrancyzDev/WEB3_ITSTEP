// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

contract Voting {
    struct Candidate {
        string name;
        uint votes;
    }

    Candidate[] public candidates;
    mapping(address => bool) public has_voted;

    constructor() {
        candidates.push(Candidate("Alice", 0));
        candidates.push(Candidate("Bob", 0));
        candidates.push(Candidate("Charlie", 0));
    }

    function vote(uint candidate_id) external {
        require(!has_voted[msg.sender], "already voted");
        require(candidate_id < candidates.length, "no such candidate");

        has_voted[msg.sender] = true;
        candidates[candidate_id].votes += 1;
    }

    function get_results() external view returns(Candidate[] memory) {
        return candidates;
    }
}