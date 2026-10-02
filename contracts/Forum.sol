// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Forum {

    struct Post{
        uint id;
        string content;
        address author;
        uint timestamp;
        uint likeCount;
        bool deleted;
    }

    event PostCreated(address indexed author, uint id, uint timestamp);
    event PostDeleted(address indexed author, uint id);
    event PostsDeleted(address indexed by, uint count);
    event PostLiked(address indexed liker, uint id, bool liked);

    address public owner;
    Post[] posts;

    mapping(uint => mapping(address => bool)) public hasLiked;

    constructor(){
        owner = msg.sender;
    }

    function create_post(string memory content) external{
        uint id = posts.length;
        posts.push(
            Post(id, content, msg.sender, block.timestamp, 0, false)
        );
        emit PostCreated(msg.sender, id, block.timestamp);
    }

    function get_posts() external view returns (Post[] memory) {
        return _filter(address(0), false);
    }

    function get_posts_by_author(address author) external view returns (Post[] memory) {
        return _filter(author, true);
    }

    function _filter(address author, bool byAuthor) private view returns (Post[] memory) {
        uint count = 0;
        for(uint i = 0; i < posts.length; i++){
            if(posts[i].deleted) continue;
            if(byAuthor && posts[i].author != author) continue;
            count++;
        }

        Post[] memory result = new Post[](count);
        uint j = 0;
        for(uint i = 0; i < posts.length; i++){
            if(posts[i].deleted) continue;
            if(byAuthor && posts[i].author != author) continue;
            result[j] = posts[i];
            j++;
        }
        return result;
    }

    function get_post(uint id) external view returns(Post memory){
        require(id < posts.length, "Not found");
        require(!posts[id].deleted, "Not found");
        return posts[id];
    }

    function delete_post(uint id) external {
        require(id < posts.length, "Not found");
        require(!posts[id].deleted, "Not found");
        require(posts[id].author == msg.sender, "Not author");

        posts[id].deleted = true;

        emit PostDeleted(msg.sender, id);
    }

    function delete_all_posts() external {
        require(msg.sender == owner, "Not owner");

        uint count = 0;
        for(uint i = 0; i < posts.length; i++){
            if(!posts[i].deleted){
                posts[i].deleted = true;
                count++;
            }
        }

        emit PostsDeleted(msg.sender, count);
    }

    function toggle_like(uint id) external {
        require(id < posts.length, "Not found");
        require(!posts[id].deleted, "Not found");

        bool liked = hasLiked[id][msg.sender];

        if(liked){
            hasLiked[id][msg.sender] = false;
            posts[id].likeCount -= 1;
        } else {
            hasLiked[id][msg.sender] = true;
            posts[id].likeCount += 1;
        }

        emit PostLiked(msg.sender, id, !liked);
    }
}
