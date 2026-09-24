// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

abstract contract Balance {
    uint internal total_supply;
    mapping(address => uint) internal balances;

    function _transfer(address from, address to, uint amount) internal virtual;

    function _mint(address to, uint amount) internal virtual;

    function transfer(address to, uint amount) external {
        _transfer(msg.sender, to, amount);
    }

    function balance_of(address account) external view returns(uint) {
        return balances[account];
    }

    function get_total_supply() external view returns(uint) {
        return total_supply;
    }
}

contract StableCoin is Balance {
    address public treasury;

    constructor(address treasury_wallet, uint initial_supply) {
        treasury = treasury_wallet;
        _mint(msg.sender, initial_supply);
    }

    function _mint(address to, uint amount) internal override {
        total_supply += amount;
        balances[to] += amount;
    }

    function _transfer(address from, address to, uint amount) internal override {
        require(balances[from] >= amount, "insufficient balance");

        uint fee = amount / 100;
        uint net_amount = amount - fee;

        balances[from] -= amount;
        balances[to] += net_amount;
        balances[treasury] += fee;
    }
}
