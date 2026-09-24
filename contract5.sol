// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

contract Subscription {
    address public owner;
    uint public price = 1000 wei;
    uint public constant PERIOD = 30 days;
    mapping(address => uint) public expires_at;

    constructor() {
        owner = msg.sender;
    }

    function subscribe() external payable {
        require(msg.value == price, "wrong payment amount");

        uint start = expires_at[msg.sender] > block.timestamp ? expires_at[msg.sender] : block.timestamp;
        expires_at[msg.sender] = start + PERIOD;
    }

    function is_active(address user) external view returns(bool) {
        return expires_at[user] > block.timestamp;
    }

    function set_price(uint new_price) external {
        require(msg.sender == owner, "only owner");
        price = new_price;
    }

    function withdraw() external {
        require(msg.sender == owner, "only owner");
        (bool result, ) = payable(owner).call{value: address(this).balance}("");
        require(result, "withdraw failed");
    }
}