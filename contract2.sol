// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
 
import "hardhat/console.sol";
 
contract TodoList {
    string[] public tasks;
 
    constructor() {}
 
    function addTask(string calldata task) external {
        tasks.push(task);
    }
 
    function removeTask(uint256 index) external {
        if(index >= tasks.length) {
            revert("Index greater than length of array");
        }
        delete tasks[index];
    }
 
    function getAllTasks() external view returns (string[] memory) {
        return tasks;
    }
}