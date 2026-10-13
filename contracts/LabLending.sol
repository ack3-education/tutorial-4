// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Lab equipment lending
/// @notice The lab admin adds students and equipment.
///         Students borrow items for up to 7 days and return them.
contract LabLending {
    enum Status { Available, Borrowed }

    struct Item {
        string name;
        Status status;
        address borrower;   // address(0) when nobody has it
        uint256 dueAt;      // 0 when not borrowed
    }

    uint256 public constant MAX_LOAN = 7 days;
    address public immutable admin;

    Item[] private items;                        // item id = index in the array
    mapping(address => bool) public isStudent;
    address[] private students;                  // keys of isStudent, in order added

    event StudentAdded(address indexed student);
    event ItemAdded(uint256 indexed itemId, string name);
    event Borrowed(uint256 indexed itemId, address indexed student, uint256 dueAt);
    event Returned(uint256 indexed itemId, address indexed student);

    error NotAdmin();
    error NotStudent();
    error AlreadyStudent(address student);
    error ItemNotFound(uint256 itemId);
    error NotAvailable(uint256 itemId);
    error NotBorrower(uint256 itemId);
    error InvalidDuration(uint256 duration);
    error LengthMismatch();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier onlyStudent() {
        if (!isStudent[msg.sender]) revert NotStudent();
        _;
    }

    modifier itemExists(uint256 itemId) {
        if (itemId >= items.length) revert ItemNotFound(itemId);
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addStudent(address student) external onlyAdmin {
        if (isStudent[student]) revert AlreadyStudent(student);
        isStudent[student] = true;
        students.push(student);
        emit StudentAdded(student);
    }

    function addItem(string calldata name) external onlyAdmin {
        items.push(Item({name: name, status: Status.Available, borrower: address(0), dueAt: 0}));
        emit ItemAdded(items.length - 1, name);
    }

    function borrow(uint256 itemId, uint256 duration) public onlyStudent itemExists(itemId) {
        if (duration == 0 || duration > MAX_LOAN || duration % 1 minutes != 0) revert InvalidDuration(duration);   // whole minutes only

        Item storage item = items[itemId];       // a pointer: writes are saved
        if (item.status != Status.Available) revert NotAvailable(itemId);

        item.status = Status.Borrowed;
        item.borrower = msg.sender;
        item.dueAt = block.timestamp + duration;
        emit Borrowed(itemId, msg.sender, item.dueAt);
    }

    /// @notice Borrow several items at once. One failure reverts all of them.
    function borrowBatch(uint256[] calldata itemIds, uint256[] calldata durations) external {
        if (itemIds.length != durations.length) revert LengthMismatch();
        for (uint256 i = 0; i < itemIds.length; i++) {
            borrow(itemIds[i], durations[i]);
        }
    }

    function returnItem(uint256 itemId) external itemExists(itemId) {
        Item storage item = items[itemId];
        if (item.borrower != msg.sender) revert NotBorrower(itemId);

        item.status = Status.Available;
        item.borrower = address(0);
        item.dueAt = 0;
        emit Returned(itemId, msg.sender);
    }

    function getItem(uint256 itemId) external view itemExists(itemId) returns (Item memory) {
        return items[itemId];
    }

    /// @notice Who has the item and until when: two return values.
    function getLoan(uint256 itemId)
        public view itemExists(itemId)
        returns (address borrower, uint256 dueAt)
    {
        Item storage item = items[itemId];
        return (item.borrower, item.dueAt);
    }

    function getItemCount() external view returns (uint256) {
        return items.length;
    }

    function getStudents() external view returns (address[] memory) {
        return students;
    }

    /// @notice Whole days until the item is due, rounded down. 0 if not borrowed or overdue.
    function daysLeft(uint256 itemId) external view itemExists(itemId) returns (uint256) {
        uint256 due = items[itemId].dueAt;
        if (due <= block.timestamp) return 0;
        return _toDays(due - block.timestamp);
    }

    /// @notice Ids of all overdue items. Memory arrays can't grow: count, allocate, fill.
    function getOverdueItems() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (_isOverdue(items[i])) count++;
        }
        uint256[] memory result = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (_isOverdue(items[i])) result[j++] = i;
        }
        return result;
    }

    function _isOverdue(Item storage item) internal view returns (bool) {
        return item.status == Status.Borrowed && block.timestamp > item.dueAt;
    }

    function _toDays(uint256 secs) private pure returns (uint256) {
        return secs / 1 days;                    // integer division rounds down
    }
}
