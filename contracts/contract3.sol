// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract EducationGrant {
    struct Student {
        bool registered;
        bool goal_reached;
        bool paid;
        bool frozen;
        uint savings;
        uint deadline;
    }

    address public owner;
    uint public base_grant;
    uint public fund_pool;
    mapping(address => Student) public students;

    event StudentRegistered(address indexed student, uint deadline);
    event Invested(address indexed investor, uint amount);
    event SavingsDeposited(address indexed student, address indexed from, uint amount);
    event GoalConfirmed(address indexed student, uint grade);
    event GrantPaid(address indexed student, uint savings, uint bonus);
    event FundsFrozen(address indexed student);

    modifier only_owner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier student_exists(address student) {
        require(students[student].registered, "student not registered");
        _;
    }

    constructor(uint base_grant_) {
        owner = msg.sender;
        base_grant = base_grant_;
    }

    function register_student(address student, uint deadline) external only_owner {
        require(!students[student].registered, "already registered");
        students[student] = Student(true, false, false, false, 0, deadline);
        emit StudentRegistered(student, deadline);
    }

    function invest() external payable {
        fund_pool += msg.value;
        emit Invested(msg.sender, msg.value);
    }

    function deposit_savings(address student) external payable student_exists(student) {
        Student memory s = students[student];
        require(!s.paid, "already paid");

        s.savings += msg.value;
        students[student] = s;
        emit SavingsDeposited(student, msg.sender, msg.value);
    }

    function check_deadline(address student) external student_exists(student) {
        Student memory s = students[student];
        require(!s.goal_reached, "goal already reached");
        require(block.timestamp > s.deadline, "deadline not passed");

        s.frozen = true;
        students[student] = s;
        emit FundsFrozen(student);
    }

    function confirm_goal(address student, uint grade) external only_owner student_exists(student) {
        Student memory s = students[student];
        require(!s.goal_reached, "goal already reached");
        require(grade <= 100, "grade must be 0-100");

        uint bonus = base_grant * grade / 100;
        if (block.timestamp > s.deadline) {
            bonus = bonus / 2;
        }
        if (bonus > fund_pool) {
            bonus = fund_pool;
        }

        uint savings = s.savings;
        s.goal_reached = true;
        s.frozen = false;
        s.paid = true;
        s.savings = 0;
        students[student] = s;
        fund_pool -= bonus;
        emit GoalConfirmed(student, grade);

        (bool result, ) = payable(student).call{value: savings + bonus}("");
        require(result, "payment failed");
        emit GrantPaid(student, savings, bonus);
    }
}
