// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
 
import "hardhat/console.sol";

contract Shop {
    struct Product {
        string name;
        uint256 price;
    }

    Product[] private products;

    function addProduct(string calldata _name, uint256 _price) external {
        if (bytes(_name).length == 0) revert("Name is empty");
        if (_price == 0) revert("Price must be > 0");

        products.push(Product(_name, _price));
    }

    function buyProduct(uint256 _id) external payable {
        uint256 price = products[_id].price;
        if (msg.value < price) revert("Not enough ETH sent");

        uint256 change = msg.value - price;
        if (change > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: change}("");
            if (!refunded) revert("Refund failed");
        }
    }

    function getAvailableProducts() external view returns (Product[] memory) {
        return products;
    }
}