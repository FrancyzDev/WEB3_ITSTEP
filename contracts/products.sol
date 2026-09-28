// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Products {
    struct Product {
        string name;
        string description;
        uint price;
        address creator;
        uint createdAt;
        string imageUrl;
        address buyer;
    }

    Product[] private products;

    event ProductBought(uint indexed id, address indexed buyer, uint price);

    function create_product(
        string calldata _name,
        string calldata _description,
        uint _price,
        string calldata _imageUrl
    ) external {
        products.push(Product(_name, _description, _price, msg.sender, block.timestamp, _imageUrl, address(0)));
    }

    function buy_product(uint _id) external payable {
        require(_id < products.length, "Product not found");
        Product storage p = products[_id];
        require(p.buyer == address(0), "Already sold");
        require(msg.sender != p.creator, "Creator cannot buy own product");
        require(msg.value == p.price, "Wrong price");

        p.buyer = msg.sender;
        (bool ok, ) = payable(p.creator).call{value: msg.value}("");
        require(ok, "Payment failed");

        emit ProductBought(_id, msg.sender, msg.value);
    }

    function get_products() external view returns (Product[] memory) {
        return products;
    }

    function get_products_count() external view returns (uint) {
        return products.length;
    }
}
