// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
 
import "lib/ArrayLibrary.sol";
 
contract ArrayUtils {
    using ArrayLibrary for uint[];
 
    function find(
        uint[] memory arr,
        uint value
    ) external pure returns (bool found, uint index) {
        return arr.indexOf(value);
    }
 
    function sort(uint[] memory arr) external pure returns (uint[] memory) {
        return arr.sort();
    }
 
    function removeAt(
        uint[] memory arr,
        uint index
    ) external pure returns (uint[] memory) {
        return arr.removeAt(index);
    }
}