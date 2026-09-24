// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

interface IVault {
    function deposit(address user) external payable;
    function withdraw(address user, uint amount) external;
    function balance_of(address user) external view returns(uint);
}

contract Vault is IVault {
    address public owner;
    address public broker;
    mapping(address => uint) private balances;

    constructor() {
        owner = msg.sender;
    }

    function set_broker(address new_broker) external {
        require(msg.sender == owner, "only owner");
        broker = new_broker;
    }

    function deposit(address user) external payable {
        require(msg.sender == broker, "only broker");
        balances[user] += msg.value;
    }

    function withdraw(address user, uint amount) external {
        require(msg.sender == broker, "only broker");
        require(balances[user] >= amount, "insufficient balance");

        balances[user] -= amount;
        (bool result, ) = payable(user).call{value: amount}("");
        require(result, "withdraw failed");
    }

    function balance_of(address user) external view returns(uint) {
        return balances[user];
    }
}

contract Broker {
    IVault public vault;

    constructor(address vault_address) {
        vault = IVault(vault_address);
    }

    function deposit() external payable {
        vault.deposit{value: msg.value}(msg.sender);
    }

    function withdraw(uint amount) external {
        vault.withdraw(msg.sender, amount);
    }

    function my_balance() external view returns(uint) {
        return vault.balance_of(msg.sender);
    }
}
