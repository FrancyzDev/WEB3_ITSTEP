// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract EmergencyFund {
    enum Purpose { Treatment, Accident, Other }

    struct Request {
        address beneficiary;
        uint amount;
        Purpose purpose;
        uint approvals;
        bool executed;
    }

    address public owner;
    address public medical_org;
    uint public threshold;
    uint public monthly_fee;
    uint public member_count;

    mapping(address => bool) public is_member;
    mapping(address => uint) public last_paid;
    Request[] public requests;
    mapping(uint => mapping(address => bool)) public approved;

    event MemberAdded(address indexed member);
    event Contributed(address indexed member, uint amount);
    event RequestCreated(uint indexed id, address indexed beneficiary, uint amount, Purpose purpose);
    event Approved(uint indexed id, address indexed by);
    event Paid(uint indexed id, address indexed beneficiary, uint amount);

    modifier only_owner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier only_member() {
        require(is_member[msg.sender], "only member");
        _;
    }

    constructor(address medical_org_, uint threshold_, uint monthly_fee_) {
        owner = msg.sender;
        medical_org = medical_org_;
        threshold = threshold_;
        monthly_fee = monthly_fee_;
    }

    function add_member(address member) external only_owner {
        require(!is_member[member], "already member");
        is_member[member] = true;
        member_count += 1;
        emit MemberAdded(member);
    }

    function contribute() external payable only_member {
        require(msg.value == monthly_fee, "wrong fee amount");
        require(block.timestamp >= last_paid[msg.sender] + 30 days, "already paid this month");

        last_paid[msg.sender] = block.timestamp;
        emit Contributed(msg.sender, msg.value);
    }

    function create_request(address beneficiary, uint amount, Purpose purpose) external only_member {
        requests.push(Request(beneficiary, amount, purpose, 0, false));
        emit RequestCreated(requests.length - 1, beneficiary, amount, purpose);
    }

    function approve(uint id) external only_member {
        Request memory r = requests[id];
        require(!r.executed, "already executed");
        require(!approved[id][msg.sender], "already approved");

        approved[id][msg.sender] = true;
        r.approvals += 1;
        requests[id] = r;
        emit Approved(id, msg.sender);

        if (r.approvals >= threshold) {
            _pay(id);
        }
    }

    function org_approve(uint id) external {
        require(msg.sender == medical_org, "only medical org");
        require(!requests[id].executed, "already executed");
        emit Approved(id, msg.sender);
        _pay(id);
    }

    function _pay(uint id) internal {
        Request memory r = requests[id];
        require(address(this).balance >= r.amount, "not enough funds");

        r.executed = true;
        requests[id] = r;
        (bool result, ) = payable(r.beneficiary).call{value: r.amount}("");
        require(result, "payment failed");
        emit Paid(id, r.beneficiary, r.amount);
    }

    function get_balance() external view returns(uint) {
        return address(this).balance;
    }
}
