// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
 
import "hardhat/console.sol";
 
contract Counter {
    uint256 public counter;
 
    constructor(uint256 initial_value) {
        counter = initial_value;
    }
 
    function increment() public {
        counter += 1;
    }
 
    function decrement() public {
        counter -= 1;
    }
 
    function getCounter() public returns (uint256) {
        return counter;
    }
}