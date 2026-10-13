// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Attendance register
/// @notice Fill in the functions marked TODO, one at a time.
///         After each one, deploy the matching check from checks/AttendanceChecks.sol
///         and call run(). It goes through when your function works.
contract Attendance {
    struct Student {
        bool enrolled;
        uint256 attended;                  // sessions attended
    }

    uint256 public immutable sessionLength;      // e.g. 900 for 15 minutes
    address public immutable teacher;

    mapping(address => Student) private students;
    address[] private studentList;         // keys of students, in the order enrolled
    uint256 public sessionCount;           // sessions opened so far
    uint256 public closesAt;               // end of the latest session
    mapping(uint256 => mapping(address => bool)) public checkedIn;   // session => student => done

    event StudentEnrolled(address indexed student);
    event SessionOpened(uint256 indexed sessionId, uint256 closesAt);
    event CheckedIn(uint256 indexed sessionId, address indexed student);

    error NotTeacher();
    error AlreadyEnrolled(address student);
    error NotEnrolled(address student);
    error SessionStillOpen();
    error NoOpenSession();
    error AlreadyCheckedIn(address student);

    modifier onlyTeacher() {
        if (msg.sender != teacher) revert NotTeacher();
        _;
    }

    constructor(uint256 length) {
        teacher = msg.sender;
        sessionLength = length;
    }

    /// TODO 1: enroll a student.
    /// Revert with AlreadyEnrolled(student) if they are enrolled already.
    /// Otherwise mark them enrolled, add them to studentList and emit StudentEnrolled.
    function enroll(address student) external onlyTeacher {
    }

    /// TODO 2a: is a session open right now?
    /// Open from the second it opens until, but not including, closesAt.
    function isSessionOpen() public view returns (bool) {
    }

    /// TODO 2b: open a session that lasts sessionLength seconds.
    /// Revert with SessionStillOpen() if one is still open.
    /// Set closesAt, emit SessionOpened(sessionCount, closesAt), then add 1 to sessionCount.
    function openSession() external onlyTeacher {
    }

    /// TODO 3: check a student in to the open session.
    /// Revert with NoOpenSession(), NotEnrolled(student) or AlreadyCheckedIn(student).
    /// Otherwise record the check-in, add 1 to their attended count and emit CheckedIn.
    /// Hint: the open session's id is sessionCount - 1.
    function _checkIn(address student) private {
    }

    function checkIn() external {
        _checkIn(msg.sender);
    }

    /// @notice Given: the teacher ends the open session early.
    function closeSession() external onlyTeacher {
        if (!isSessionOpen()) revert NoOpenSession();
        closesAt = block.timestamp;
    }

    /// TODO 4: the teacher checks in several students at once. One failure reverts all.
    function checkInBatch(address[] calldata list) external onlyTeacher {
    }

    /// TODO 5: percentage of all sessions a student attended, rounded down (0 to 100).
    /// Revert with NotEnrolled(student) for an address that isn't enrolled.
    /// Return 0 when no session has been opened yet.
    function attendancePercent(address student) external view returns (uint256) {
    }

    /// EXTRA: students who attended fewer than minAttendance sessions, in enrollment order.
    /// Memory arrays can't grow: count first, then allocate, then fill.
    function getAtRisk(uint256 minAttendance) external view returns (address[] memory) {
    }

    function getAttendance(address student) external view returns (uint256) {
        if (!students[student].enrolled) revert NotEnrolled(student);
        return students[student].attended;
    }

    function getStudents() external view returns (address[] memory) {
        return studentList;
    }
}
