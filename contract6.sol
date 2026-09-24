// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

contract CommunityFunding {
    struct Project {
        address owner;
        string description;
        uint goal;
        uint votes;
    }

    address public admin;
    bool public distributed;
    uint public total_votes;
    Project[] public projects;
    mapping(address => bool) public has_voted;

    constructor() {
        admin = msg.sender;
    }

    function donate() external payable {}

    function propose(string memory description, uint goal) external {
        require(!distributed, "already distributed");
        projects.push(Project(msg.sender, description, goal, 0));
    }

    function vote(uint project_id) external {
        require(!distributed, "already distributed");
        require(!has_voted[msg.sender], "already voted");
        require(project_id < projects.length, "no such project");

        has_voted[msg.sender] = true;
        projects[project_id].votes += 1;
        total_votes += 1;
    }

    function distribute() external {
        require(msg.sender == admin, "only admin");
        require(!distributed, "already distributed");
        require(total_votes > 0, "no votes");

        distributed = true;
        uint pool = address(this).balance;

        for (uint i = 0; i < projects.length; i++) {
            uint share = pool * projects[i].votes / total_votes;
            if (share > projects[i].goal) {
                share = projects[i].goal;
            }
            if (share > 0) {
                (bool result, ) = payable(projects[i].owner).call{value: share}("");
                require(result, "payment failed");
            }
        }
    }

    function get_projects() external view returns(Project[] memory) {
        return projects;
    }

    function get_pool() external view returns(uint) {
        return address(this).balance;
    }
}