// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
 
import "hardhat/console.sol";
 
library ArrayLibrary {
    error IndexOutOfBounds(uint index, uint length);
    error ValueNotFound(uint value);
 
    function indexOf(
        uint[] memory arr,
        uint value
    ) internal pure returns (bool found, uint index) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return (true, i);
            }
        }
        return (false, 0);
    }
 
    function sort(
        uint[] memory arr
    ) internal pure returns (uint[] memory) {
        for (uint i = 0; i < arr.length; i++) {
            for (uint j = 0; j < arr.length - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
                }
            }
        }
        return arr;
    }
 
    function removeAt(
        uint[] memory arr,
        uint index
    ) internal pure returns (uint[] memory result) {
        if (index >= arr.length) {
            revert IndexOutOfBounds(index, arr.length);
        }
        result = new uint[](arr.length - 1);
        for (uint i = 0; i < index; i++) {
            result[i] = arr[i];
        }
        for (uint i = index + 1; i < arr.length; i++) {
            result[i - 1] = arr[i];
        }
    }
}