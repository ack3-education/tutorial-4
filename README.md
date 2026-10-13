# Tutorial 4: Writing a correct contract

You need:

- [VS Code](https://code.visualstudio.com/): a popular code editor that supports extensions
- the [Solidity (Wake) extension](https://marketplace.visualstudio.com/items?itemName=AckeeBlockchain.tools-for-solidity)
  for VS Code: it compiles the contracts and lets you deploy and call them

Open this folder in VS Code. Compiler 0.8.26.

## 1. Play with LabLending

`contracts/LabLending.sol` is finished. In the extension's Deploy & Interact panel:

1. Deploy `LabLending` from the first account. That account is the admin.
2. Call `addStudent` with the second account's address, then add two items:
   `addItem("Oscilloscope")` and `addItem("Multimeter")`.
3. Switch to the second account. Call `borrow(0, 60)`, then `getLoan(0)`: it returns two values.
4. Call `borrowBatch([1, 0], [60, 60])`. It reverts, and item 1 is still available.
5. Wait a minute, send any transaction, then call `getOverdueItems()`.

Then break it on purpose:

- Borrow for 8 days (`691200` seconds). Which error?
- Borrow for 90 seconds. Why does that fail too?
- Return item 0 from the admin account.
- Call `addItem` from the second account.
- In `borrow`, change `Item storage item` to `Item memory item`. Redeploy, borrow, and read the item.

## 2. Build: Attendance

Fill in the functions marked TODO in `contracts/Attendance.sol`, one at a time.
To try it by hand, deploy it with `900` (a 15-minute session).

After each TODO, check it: open `checks/AttendanceChecks.sol`, deploy the check with the
TODO's number (`Check1Enroll`, `Check2Sessions`, `Check3CheckIn`, `Check4Batch`,
`Check5Percent`, or `Check6AtRisk` for the extra) and call `run()`. If it goes through,
the TODO works. If it reverts, the message says what to fix.

Redeploy the check after every change to `Attendance.sol`. A check can't see events
(no contract can), so look for your events in the transaction log yourself.
