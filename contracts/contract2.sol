// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

contract Teacher {
    function role() public virtual pure returns(string memory) {
        return "Teacher";
    }
}

contract Student {
    function role() public virtual pure returns(string memory) {
        return "Student";
    }
}

contract Assistant is Teacher, Student {
    function role() public override(Teacher, Student) pure returns(string memory) {
        return "Assistant";
    }

    function base_role() public pure returns(string memory) {
        return super.role();
    }
}
