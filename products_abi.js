const products_abi = [
    "function create_product(string _name, string _description, uint256 _price, string _imageUrl) external",
    "function buy_product(uint256 _id) external payable",
    "function get_products() external view returns (tuple(string name, string description, uint256 price, address creator, uint256 createdAt, string imageUrl, address buyer)[])",
    "function get_products_count() external view returns (uint256)"
];
