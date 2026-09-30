// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MediaStore {
    struct Media {
        uint id;
        string cid;
        string name;
        address author;
        uint created_at;
        bool deleted;
    }

    Media[] private pics;

    function new_file(string memory cid, string memory name) external {
        pics.push(Media(pics.length, cid, name, msg.sender, block.timestamp, false));
    }

    function delete_file(uint id) external {
        require(id < pics.length, "File not found");
        require(pics[id].author == msg.sender, "Only author can delete");
        require(!pics[id].deleted, "Already deleted");
        pics[id].deleted = true;
    }

    function get_files() external view returns (Media[] memory) {
        uint count;
        for (uint i = 0; i < pics.length; i++) {
            if (!pics[i].deleted) count++;
        }

        Media[] memory result = new Media[](count);
        uint j;
        for (uint i = 0; i < pics.length; i++) {
            if (!pics[i].deleted) {
                result[j++] = pics[i];
            }
        }
        return result;
    }

    function get_file(uint idx) external view returns (Media memory) {
        require(idx < pics.length && !pics[idx].deleted, "File not found");
        return pics[idx];
    }
}
