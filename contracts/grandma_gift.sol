// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

contract GrandmaGift {
    event Claimed(address indexed grandchild, uint value);

    struct Grandchild {
        bool registered;
        bool claimed;
        uint birthday;
    }

    address public grandma;
    bool public deposited;
    uint public gift;
    uint public count;
    mapping(address => Grandchild) public grandchildren;

    constructor() {
        grandma = msg.sender;
    }

    function add_grandchild(address grandchild, uint birthday) external {
        require(msg.sender == grandma, "only grandma");
        require(!deposited, "deposit already made");
        require(!grandchildren[grandchild].registered, "already added");

        grandchildren[grandchild] = Grandchild(true, false, birthday);
        count += 1;
    }

    function deposit() external payable {
        require(msg.sender == grandma, "only grandma");
        require(!deposited, "deposit already made");
        require(count > 0, "no grandchildren");

        deposited = true;
        gift = msg.value / count;
    }

    function claim() external {
        Grandchild memory kid = grandchildren[msg.sender];
        require(kid.registered, "not a grandchild");
        require(deposited, "no deposit yet");
        require(!kid.claimed, "already claimed");
        require(block.timestamp >= kid.birthday, "birthday has not come yet");

        kid.claimed = true;
        grandchildren[msg.sender] = kid;

        (bool result, ) = payable(msg.sender).call{value: gift}("");
        require(result, "claim failed");

        emit Claimed(msg.sender, gift);
    }
}
