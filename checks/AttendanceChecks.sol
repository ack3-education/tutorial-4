// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../contracts/Attendance.sol";

// ============================================================================
// Checks for contracts/Attendance.sol
//
// Deploy the check for the TODO you finished (no constructor arguments) and
// call run(). If your function works, the call goes through and returns
// "TODO n works". If not, it reverts with a message saying what is wrong.
// Each run() deploys a fresh Attendance, so redeploy the check after editing.
//
// Contracts can't read events, so check your events yourself in the
// transaction log when you try your functions by hand.
// ============================================================================

/// @notice A separate account the checks can use to call as another person.
contract Actor {
    function exec(address target, bytes calldata data) external returns (bool ok, bytes memory result) {
        (ok, result) = target.call(data);
    }
}

abstract contract AttendanceCheckBase {
    function _revertedWith(bool ok, bytes memory result, bytes4 selector) internal pure returns (bool) {
        return !ok && result.length >= 4 && bytes4(result) == selector;
    }

    function _selector(bytes memory result) internal pure returns (bytes4) {
        return result.length >= 4 ? bytes4(result) : bytes4(0);
    }

    function _checkInAs(Actor who, Attendance att) internal returns (bool ok, bytes memory result) {
        return who.exec(address(att), abi.encodeCall(Attendance.checkIn, ()));
    }

    /// @dev Quick test of the earlier TODOs, so a missing one gets a clear message.
    function _requireDone(uint256 last) internal {
        Attendance t = new Attendance(15 minutes);
        try t.enroll(address(this)) {} catch { revert("Finish TODO 1 first"); }
        if (t.getStudents().length != 1) revert("Finish TODO 1 first");
        if (last < 2) return;
        try t.openSession() {} catch { revert("Finish TODO 2 first"); }
        if (!t.isSessionOpen()) revert("Finish TODO 2 first");
        if (last < 3) return;
        try t.checkIn() {} catch { revert("Finish TODO 3 first"); }
        try t.getAttendance(address(this)) returns (uint256 n) {
            if (n != 1) revert("Finish TODO 3 first");
        } catch {
            revert("Finish TODO 3 first");
        }
        if (last < 4) return;
        address other = address(0xBEEF);
        t.enroll(other);
        address[] memory list = new address[](1);
        list[0] = other;
        try t.checkInBatch(list) {} catch { revert("Finish TODO 4 first"); }
        if (t.getAttendance(other) != 1) revert("Finish TODO 4 first");
    }
}

contract Check1Enroll is AttendanceCheckBase {
    function run() external returns (string memory) {
        Attendance att = new Attendance(15 minutes);
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        att.enroll(alice);
        att.enroll(bob);
        address[] memory list = att.getStudents();
        require(list.length == 2 && list[0] == alice && list[1] == bob,
            "TODO 1: getStudents() should list enrolled students in the order they were enrolled");
        try att.getAttendance(alice) returns (uint256 n) {
            require(n == 0, "TODO 1: a new student should have attended 0 sessions");
        } catch {
            revert("TODO 1: enroll must mark the student as enrolled");
        }
        try att.enroll(alice) {
            revert("TODO 1: enrolling the same student twice must revert");
        } catch (bytes memory r) {
            require(_selector(r) == Attendance.AlreadyEnrolled.selector,
                "TODO 1: enrolling twice must revert with AlreadyEnrolled");
        }
        return "TODO 1 works. Look for StudentEnrolled in the log when you enroll by hand.";
    }
}

contract Check2Sessions is AttendanceCheckBase {
    function run() external returns (string memory) {
        Attendance att = new Attendance(15 minutes);
        require(!att.isSessionOpen(), "TODO 2: no session is open before openSession is called");

        att.openSession();
        require(att.closesAt() == block.timestamp + 15 minutes, "TODO 2: closesAt should be now + sessionLength");
        require(att.sessionCount() == 1, "TODO 2: openSession should add 1 to sessionCount");
        require(att.isSessionOpen(), "TODO 2: a session should be open right after openSession");
        try att.openSession() {
            revert("TODO 2: opening a session while one is open must revert");
        } catch (bytes memory r) {
            require(_selector(r) == Attendance.SessionStillOpen.selector,
                "TODO 2: opening while open must revert with SessionStillOpen");
        }

        // A session of length 0 closes the second it opens: closesAt itself is not open.
        Attendance zero = new Attendance(0);
        zero.openSession();
        require(!zero.isSessionOpen(), "TODO 2: at exactly closesAt the session is closed (use <, not <=)");
        zero.openSession();
        require(zero.sessionCount() == 2, "TODO 2: after a session closes, a new one can be opened");
        return "TODO 2 works. Look for SessionOpened in the log when you open one by hand.";
    }
}

contract Check3CheckIn is AttendanceCheckBase {
    function run() external returns (string memory) {
        _requireDone(2);
        Attendance att = new Attendance(15 minutes);
        Actor alice = new Actor();
        Actor bob = new Actor();
        Actor carol = new Actor();
        att.enroll(address(alice));
        att.enroll(address(bob));

        (bool ok, bytes memory r) = _checkInAs(alice, att);
        require(_revertedWith(ok, r, Attendance.NoOpenSession.selector),
            "TODO 3: checking in with no open session must revert with NoOpenSession");

        att.openSession();
        (ok, r) = _checkInAs(alice, att);
        require(ok, "TODO 3: an enrolled student should be able to check in to an open session");
        require(att.checkedIn(0, address(alice)), "TODO 3: record the check-in in checkedIn[sessionId][student]");
        require(att.getAttendance(address(alice)) == 1,
            "TODO 3: attended should be 1 after one check-in. Writing to a memory copy?");

        (ok, r) = _checkInAs(alice, att);
        require(_revertedWith(ok, r, Attendance.AlreadyCheckedIn.selector),
            "TODO 3: checking in twice must revert with AlreadyCheckedIn");
        (ok, r) = _checkInAs(carol, att);
        require(_revertedWith(ok, r, Attendance.NotEnrolled.selector),
            "TODO 3: a student who isn't enrolled must get NotEnrolled");

        att.closeSession();
        (ok, r) = _checkInAs(bob, att);
        require(_revertedWith(ok, r, Attendance.NoOpenSession.selector),
            "TODO 3: a session that has closed must revert with NoOpenSession");

        att.openSession();
        (ok, r) = _checkInAs(alice, att);
        require(ok && att.getAttendance(address(alice)) == 2, "TODO 3: a new session allows a new check-in");
        return "TODO 3 works. Look for CheckedIn in the log when you check in by hand.";
    }
}

contract Check4Batch is AttendanceCheckBase {
    function run() external returns (string memory) {
        _requireDone(3);
        Attendance att = new Attendance(15 minutes);
        address a = address(0xA11CE);
        address b = address(0xB0B);
        address c = address(0xCA201);
        att.enroll(a);
        att.enroll(b);
        att.enroll(c);
        att.openSession();

        address[] memory list = new address[](2);
        list[0] = a;
        list[1] = b;
        att.checkInBatch(list);
        require(att.getAttendance(a) == 1 && att.getAttendance(b) == 1,
            "TODO 4: every student in the batch should be checked in");

        list[0] = c;   // fine
        list[1] = a;   // already checked in
        try att.checkInBatch(list) {
            revert("TODO 4: a batch with one invalid student must revert");
        } catch {}
        require(att.getAttendance(c) == 0, "TODO 4: when a batch reverts, nobody in it is checked in");
        return "TODO 4 works.";
    }
}

contract Check5Percent is AttendanceCheckBase {
    function run() external returns (string memory) {
        _requireDone(3);
        Attendance att = new Attendance(15 minutes);
        Actor alice = new Actor();
        address bob = address(0xB0B);
        att.enroll(address(alice));
        att.enroll(bob);

        try att.attendancePercent(address(alice)) returns (uint256 p) {
            require(p == 0, "TODO 5: with no sessions yet, the percentage is 0");
        } catch {
            revert("TODO 5: with no sessions yet, return 0 instead of dividing by zero");
        }

        for (uint256 i = 0; i < 3; i++) {
            att.openSession();
            if (i < 2) _checkInAs(alice, att);
            att.closeSession();
        }
        require(att.attendancePercent(address(alice)) == 66,
            "TODO 5: 2 of 3 sessions should give 66. Multiply first, then divide");
        require(att.attendancePercent(bob) == 0, "TODO 5: a student with no visits has 0 percent");
        try att.attendancePercent(address(0xCA201)) {
            revert("TODO 5: an address that isn't enrolled must revert");
        } catch (bytes memory r) {
            require(_selector(r) == Attendance.NotEnrolled.selector,
                "TODO 5: an address that isn't enrolled must revert with NotEnrolled");
        }
        return "TODO 5 works.";
    }
}

contract Check6AtRisk is AttendanceCheckBase {
    function run() external returns (string memory) {
        _requireDone(4);
        Attendance att = new Attendance(15 minutes);
        address a = address(0xA11CE);
        address b = address(0xB0B);
        address c = address(0xCA201);
        att.enroll(a);
        att.enroll(b);
        att.enroll(c);

        address[] memory list = new address[](2);
        list[0] = a;
        list[1] = c;
        att.openSession();
        att.checkInBatch(list);       // a and c attend session 0
        att.closeSession();
        list = new address[](1);
        list[0] = a;
        att.openSession();
        att.checkInBatch(list);       // only a attends session 1
        att.closeSession();

        address[] memory risk = att.getAtRisk(2);
        require(risk.length == 2 && risk[0] == b && risk[1] == c,
            "EXTRA: getAtRisk(2) should return the students with fewer than 2 visits, in enrollment order");
        risk = att.getAtRisk(1);
        require(risk.length == 1 && risk[0] == b, "EXTRA: getAtRisk(1) should return only the student with 0 visits");
        require(att.getAtRisk(0).length == 0, "EXTRA: nobody has fewer than 0 visits");
        return "EXTRA works.";
    }
}
