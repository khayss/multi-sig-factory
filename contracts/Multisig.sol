// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisig {

    struct Transaction {
        uint256 id;
        uint256 amount;
        address sender;
        address recipient;
        bool isCompleted;
        uint256 timestamp;
        uint256 noOfApproval;
        address tokenAddress;
        address[] transactionSigners;
    }

    struct QuorumUpdate {
        uint256 id;
        uint8 newQuorum;
        uint8 noOfApprovals;
        bool isPending;
        address creator;
        uint256 duration;
        uint256 timestamp;
    }

    QuorumUpdate quorumUpdate;
    mapping(address => bool) isValidSigner;
    mapping(uint => Transaction) transactions; // txId -> Transaction
    // signer -> transactionId -> bool (checking if an address has signed)
    mapping(address => mapping(uint256 => bool)) hasSigned;
    mapping(address => mapping(uint256 => bool)) hasSignedQuorumUpdate;
    uint256 public noOfValidSigners;
    uint256 public quorum;
    uint256 public txCount;

    constructor(uint256 _quorum, address[] memory _validSigners) {
        require(_validSigners.length > 1, "few valid signers");
        require(_quorum > 1, "quorum is too small");

        for (uint256 i = 0; i < _validSigners.length; i++) {
            require(_validSigners[i] != address(0), "zero address not allowed");
            require(!isValidSigner[_validSigners[i]], "signer already exist");

            isValidSigner[_validSigners[i]] = true;
        }

        noOfValidSigners = _validSigners.length;

        if (!isValidSigner[msg.sender]) {
            isValidSigner[msg.sender] = true;
            noOfValidSigners += 1;
        }

        require(
            _quorum <= noOfValidSigners,
            "quorum greater than valid signers"
        );
        quorum = _quorum;
    }

    function transfer(
        uint256 _amount,
        address _recipient,
        address _tokenAddress
    ) external {
        require(msg.sender != address(0), "address zero found");
        require(isValidSigner[msg.sender], "invalid signer");

        require(_amount > 0, "can't send zero amount");
        require(_recipient != address(0), "address zero found");
        require(_tokenAddress != address(0), "address zero found");

        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "insufficient funds"
        );

        uint256 _txId = txCount + 1;
        Transaction storage trx = transactions[_txId];

        trx.id = _txId;
        trx.amount = _amount;
        trx.recipient = _recipient;
        trx.sender = msg.sender;
        trx.timestamp = block.timestamp;
        trx.tokenAddress = _tokenAddress;
        trx.noOfApproval += 1;
        trx.transactionSigners.push(msg.sender);
        hasSigned[msg.sender][_txId] = true;

        txCount += 1;
    }

    function approveTx(uint8 _txId) external {
        Transaction storage trx = transactions[_txId];

        require(trx.id != 0, "invalid tx id");

        require(
            IERC20(trx.tokenAddress).balanceOf(address(this)) >= trx.amount,
            "insufficient funds"
        );
        require(!trx.isCompleted, "transaction already completed");
        require(trx.noOfApproval < quorum, "approvals already reached");

        // for(uint256 i = 0; i < trx.transactionSigners.length; i++) {
        //     if(trx.transactionSigners[i] == msg.sender) {
        //         revert("can't sign twice");
        //     }
        // }

        require(isValidSigner[msg.sender], "not a valid signer");
        require(!hasSigned[msg.sender][_txId], "can't sign twice");

        hasSigned[msg.sender][_txId] = true;
        trx.noOfApproval += 1;
        trx.transactionSigners.push(msg.sender);

        if (trx.noOfApproval == quorum) {
            trx.isCompleted = true;
            IERC20(trx.tokenAddress).transfer(trx.recipient, trx.amount);
        }
    }

    function createQuorumUpdate(uint8 _newQuorum, uint256 _duration) external {
        require(msg.sender != address(0), "address zero not allowed");
        require(isValidSigner[msg.sender], "not a valid signer");
        require(_newQuorum > 0, "quorum can't be zero");
        require(_duration > 0, "duration too short");
        require(
            block.timestamp > quorumUpdate.timestamp + quorumUpdate.duration,
            "quorum update pending"
        );
        require(quorumUpdate.noOfApprovals < quorum, "quorum update pending");

        hasSignedQuorumUpdate[msg.sender][quorumUpdate.id] = true;
        quorumUpdate.creator = msg.sender;
        quorumUpdate.timestamp = block.timestamp;
        quorumUpdate.duration = _duration;
        quorumUpdate.isPending = true;
        quorumUpdate.noOfApprovals += 1;
        quorumUpdate.id += 1;
    }

    function approveQuorumUpdate() external {
        require(isValidSigner[msg.sender], "not a valid signer");
        require(
            block.timestamp < quorumUpdate.timestamp + quorumUpdate.duration,
            "duration has expired"
        );
        require(
            !hasSignedQuorumUpdate[msg.sender][quorumUpdate.id],
            "already signed"
        );
        require(quorumUpdate.isPending, "quorum update not pending");

        hasSignedQuorumUpdate[msg.sender][quorumUpdate.id] = true;

        quorumUpdate.noOfApprovals += 1;
    }

    function updateQuorum() external returns (bool success) {
        require(quorumUpdate.creator != address(0), "address zero not allowed");
        require(quorumUpdate.noOfApprovals >= quorum, "not enough approvals");
        require(quorumUpdate.isPending, "no pending quorum update");
        require(quorumUpdate.newQuorum > 0, "quorum cannot be zero");
        require(quorumUpdate.newQuorum <= noOfValidSigners, "quorum too high");

        uint8 _newQuorum = quorumUpdate.newQuorum;
        uint256 _quorumUpdateId = quorumUpdate.id;

        QuorumUpdate memory _quorumUpdate;
        quorumUpdate = _quorumUpdate;
        quorumUpdate.id = _quorumUpdateId + 1;

        quorum = _newQuorum;

        return true;
    }

    function getIsValidSigner(address _signer) external view returns (bool) {
        return isValidSigner[_signer];
    }
}
