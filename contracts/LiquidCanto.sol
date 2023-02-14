// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./AccrueNFT.sol";
import "./interfaces/ILiquidCanto.sol";

contract LiquidCanto is
    ILiquidCanto,
    ERC20,
    Pausable,
    AccessControl,
    ReentrancyGuard
{
    AccrueNFT private accrueNFT;

    /// @dev includes action such as accrueReward, bridge, pause
    bytes32 public constant ROLE_BOT = keccak256("ROLE_BOT");

    address public treasury;
    address public immutable nft;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet internal unbondRequests;

    // Batch no for new unbonding request, batch no will increase when current batch is processing
    // Update with ROLE BOT
    uint256 public currentUnbondingBatchNo;

    // The total amount in protocol,include slash、rewards、amount user staked in
    uint256 public totalPooledCanto;

    // The total amount about user staked in,rewards/slash not included
    uint256 public totalCantoStaked;

    uint8 public constant EXCHANGE_RATE_DECIMAL = 18;
    // exchange rate = totalSupply() / totalPooledCanto which could be 1.01
    // multiply by 1e8 to get up to 8 decimals precision
    uint256 public constant EXCHANGE_RATE_PRECISION =
        10 ** EXCHANGE_RATE_DECIMAL;

    // Unbonding fee  100 = 0.1%, 200 = 0.2%
    uint256 public unbondingFee;

    // Unbonding time by the bot, eg. 3 days 15 mins at the worst case
    // 1. 3 days from max 7 unbonding per validator
    // 2. 15 mins from bot processing (gather unbonding request)
    uint256 public unbondingProcessingTime;

    // Unbonding duration - eg. 21 days on canto network
    uint256 public unbondingDuration;

    // 1000 = 1% for unbonding fee, thus 100_000 represent 100%
    uint256 public constant UNBONDING_FEE_DENOMINATOR = 100_000;
    // Last time when bot unbond from delegator
    uint256 public lastUnbondTime;

    // tokenId to withdrawal request
    mapping(uint256 => UnbondRequest) public nftToken2UnbondRequest;
    // Unbonding Batch no => unbonding status
    mapping(uint256 => UnbondingStatus) public batch2UnbondingStatus;
    // Canto cosmos layer txn hash ==> reward accrued
    mapping(string => uint256) public txnHash2AccrueRewardAmount;
    // validator address => time => amount
    mapping(string => mapping(uint256 => uint256))
        public validator2Time2AmountSlashed;

    struct UnbondRequest {
        // timestamp of when unlock request starts
        uint128 unlockStartTime;
        // timestamp of when unlock request ends
        uint128 unlockEndTime;
        // total liquidCanto amount pending unlock
        uint256 liquidCantoAmount;
        // liquidCanto to canto rate - this can decrease in the event of slashing, require divide by 1e18
        uint256 liquidCanto2CantoExchangeRate;
        // unbond request batch
        uint256 batchNo;
    }

    constructor(
        address bot,
        address _treasury
    ) ERC20("Liquid Canto", "LCanto") {
        require(
            address(bot) != address(0) && address(_treasury) != address(0),
            "ZERO ADDRESS"
        );

        treasury = _treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_BOT, bot);

        accrueNFT = new AccrueNFT(address(this));
        nft = address(accrueNFT);
        emit AccrueNFTCreate(address(this), address(accrueNFT));

        batch2UnbondingStatus[currentUnbondingBatchNo] = UnbondingStatus
            .PENDING_BOT;

        // Default 0.2%
        unbondingFee = 200;
        unbondingDuration = 21 days;
        unbondingProcessingTime = 3 days + 12 hours;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function stake(
        address _receiver
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(_receiver != address(0), "ZERO_ADDRESS");
        require(msg.value > 0, "ZERO_DEPOSIT");

        uint256 shareAmount = convertToShare(msg.value);
        _mint(_receiver, shareAmount);

        totalPooledCanto += msg.value;
        totalCantoStaked += msg.value;

        emit Stake(_receiver, msg.value, shareAmount);
        return shareAmount;
    }

    // Caller is user , will mint a NFT for user , and burn the shareAmount of LCanto
    function requestUnbond(
        uint256 _shareAmount,
        address _receiver
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(_receiver != address(0), "ZERO_ADDRESS");
        require(_shareAmount > 0, "ZERO_SHAREAMOUNT");

        uint256 unlockTime = getUnbondUnlockDate();
        uint256 tokenId = accrueNFT.mint(_receiver);
        unbondRequests.add(tokenId);

        uint256 liquidCanto2CantoExchangeRate = (totalPooledCanto *
            EXCHANGE_RATE_PRECISION) / totalSupply();
        nftToken2UnbondRequest[tokenId] = UnbondRequest({
            unlockStartTime: uint128(block.timestamp),
            unlockEndTime: uint128(unlockTime),
            liquidCantoAmount: _shareAmount,
            liquidCanto2CantoExchangeRate: liquidCanto2CantoExchangeRate,
            batchNo: currentUnbondingBatchNo
        });

        // Reduce totalPooledCanto in protocol and burn share
        totalPooledCanto -=
            (_shareAmount * liquidCanto2CantoExchangeRate) /
            EXCHANGE_RATE_PRECISION;
        _burn(msg.sender, _shareAmount);

        emit RequestUnbond(
            _receiver,
            tokenId,
            _shareAmount,
            liquidCanto2CantoExchangeRate,
            currentUnbondingBatchNo
        );
        return tokenId;
    }

    /**
     * Caller is user
     * Burn the user nft to get back canto
     */
    function redeemCanto(
        uint256 _tokenId,
        address _receiver
    ) public nonReentrant whenNotPaused returns (uint256) {
        require(_receiver != address(0), "ZERO_ADDRESS");
        require(accrueNFT.isApprovedOrOwner(msg.sender, _tokenId), "NOT_OWNER");

        UnbondRequest storage unbondRequest = nftToken2UnbondRequest[_tokenId];
        require(
            unbondRequest.unlockEndTime <= block.timestamp,
            "NOT_UNLOCK_YET"
        );

        UnbondingStatus status = batch2UnbondingStatus[unbondRequest.batchNo];
        require(status == UnbondingStatus.UNBONDED, "NOT_UNBONDED_YET");

        // Burn NFT
        accrueNFT.burn(_tokenId);
        unbondRequests.remove(_tokenId);

        uint256 totalCantoAmount = (unbondRequest.liquidCantoAmount *
            unbondRequest.liquidCanto2CantoExchangeRate) /
            EXCHANGE_RATE_PRECISION;

        // Send canto fee amount to treasury
        uint256 cantoFeeAmount = (totalCantoAmount * unbondingFee) /
            UNBONDING_FEE_DENOMINATOR;
        payable(treasury).transfer(cantoFeeAmount);

        // Send canto amount to user
        uint256 redeemAmount = totalCantoAmount - cantoFeeAmount;
        payable(_receiver).transfer(redeemAmount);

        emit Unbond(_receiver, _tokenId, redeemAmount, cantoFeeAmount);
        return redeemAmount;
    }

    function batchRedeem(
        uint256[] calldata _tokenIds,
        address _receiver
    ) public returns (uint256) {
        uint256 totalCantoAmt;
        for (uint256 i; i < _tokenIds.length; i++) {
            totalCantoAmt += redeemCanto(_tokenIds[i], _receiver);
        }
        return totalCantoAmt;
    }

    function deposit() external payable {
        emit Deposit(msg.value);
    }

    /*********************************************************************************
     *                                                                               *
     *                    BOT AND ADMIN-ONLY FUNCTIONS                               *
     *                                                                               *
     *********************************************************************************/

    function accrueReward(
        uint256 amount,
        string calldata txnHash
    ) external onlyRole(ROLE_BOT) {
        require(amount > 0, "ZERO_AMOUNT");
        require(txnHash2AccrueRewardAmount[txnHash] == 0, "ACCRUE_RECORDED");

        totalPooledCanto += amount;
        txnHash2AccrueRewardAmount[txnHash] = amount;

        emit AccrueReward(amount, txnHash);
    }

    function gatherForDelegate(uint256 amount) external onlyRole(ROLE_BOT) {
        require(
            amount <= totalCantoStaked,
            "amount must be smaller than totalCantoStaked"
        );

        totalCantoStaked -= amount;
        payable(msg.sender).transfer(amount);

        emit GatherCantoForDelegate(amount);
    }

    function setUnbondingBatchStatus(
        uint256 _batchNo,
        UnbondingStatus _status
    ) external onlyRole(ROLE_BOT) {
        require(
            _status != UnbondingStatus.PENDING_BOT,
            "PENDING_BOT set by contract only"
        );
        require(_batchNo <= currentUnbondingBatchNo, "Cannot set future batch");
        UnbondingStatus batchStatus = batch2UnbondingStatus[_batchNo];

        if (_status == UnbondingStatus.PROCESSING) {
            // Processing - When bot started to process the unbonding requests
            require(
                _batchNo == currentUnbondingBatchNo,
                "Should process only current batch number"
            );
            require(
                batchStatus == UnbondingStatus.PENDING_BOT,
                "batchStatus should be PENDING_BOT"
            );

            if (_batchNo > 0) {
                // theres a previous batch, double check previous batch status is unbonding or unbonded
                UnbondingStatus prevStatus = batch2UnbondingStatus[
                    _batchNo - 1
                ];
                require(
                    prevStatus == UnbondingStatus.UNBONDING ||
                        prevStatus == UnbondingStatus.UNBONDED,
                    "previous batch should be unbonding or unbonded"
                );
            }

            // new unbonding request will be in next batch
            currentUnbondingBatchNo += 1;

            batch2UnbondingStatus[_batchNo] = UnbondingStatus.PROCESSING;
            emit SetUnbondingBatchStatus(_batchNo, UnbondingStatus.PROCESSING);

            // Set the new batch to PENDING_BOT status
            batch2UnbondingStatus[currentUnbondingBatchNo] = UnbondingStatus
                .PENDING_BOT;
            emit SetUnbondingBatchStatus(
                currentUnbondingBatchNo,
                UnbondingStatus.PENDING_BOT
            );
        } else if (_status == UnbondingStatus.UNBONDING) {
            // Unbonding - When bot has successfully informed validator to start unbonding
            require(
                batchStatus == UnbondingStatus.PROCESSING,
                "batchStatus should be PROCESSING"
            );

            // Also update lastUnbondTime
            lastUnbondTime = block.timestamp;

            batch2UnbondingStatus[_batchNo] = UnbondingStatus.UNBONDING;
            emit SetUnbondingBatchStatus(_batchNo, UnbondingStatus.UNBONDING);
        } else if (_status == UnbondingStatus.UNBONDED) {
            require(
                batchStatus == UnbondingStatus.UNBONDING,
                "batchStatus should be UNBONDING"
            );

            batch2UnbondingStatus[_batchNo] = UnbondingStatus.UNBONDED;
            emit SetUnbondingBatchStatus(_batchNo, UnbondingStatus.UNBONDED);
        }
    }

    // TODO need test
    function pauseDueSlashing() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function togglePause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    //TODO Need offchain work ensure new exchange rate cannot drop more than 20 percent.
    function slashUnbondingRequests(
        uint256[] calldata _tokenIds,
        uint256[] calldata _newRates
    ) external onlyRole(ROLE_BOT) {
        require(
            _tokenIds.length == _newRates.length,
            "Both input length must match"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            UnbondRequest storage request = nftToken2UnbondRequest[
                _tokenIds[i]
            ];
            require(
                request.liquidCanto2CantoExchangeRate > _newRates[i],
                "New exchange rate must be lower"
            );
            require(
                (request.liquidCanto2CantoExchangeRate * 8) / 10 <=
                    _newRates[i],
                "New exchange rate cannot drop more than 20 percent"
            );
            uint256 oldRate = request.liquidCanto2CantoExchangeRate;
            request.liquidCanto2CantoExchangeRate = _newRates[i];

            emit SlashRequest(_tokenIds[i], oldRate, _newRates[i]);
        }
    }

    /**
     * @dev see interface on detailed instruction, only execute this after calculating how much
     *      canto to slash between unbonding users / protocol (both parties should slash by equal percentage)
     */
    function slash(
        string calldata _validatorAddress,
        uint256 _amount,
        uint256 _time
    ) external onlyRole(ROLE_BOT) {
        require(
            validator2Time2AmountSlashed[_validatorAddress][_time] == 0,
            "SLASH_RECORDED"
        );
        require(_amount > 0, "ZERO_AMOUNT");
        // totalPooledCanto cannot go to 0, otherwise convertToShare will not mint the correct share for new stakers
        require(
            _amount < totalPooledCanto,
            "amount must be less than totalPooledCanto"
        );

        validator2Time2AmountSlashed[_validatorAddress][_time] = _amount;
        totalPooledCanto -= _amount;

        emit Slash(_validatorAddress, _amount, _time);
    }

    /// @param _unbondingFee - 100 = 0.1%
    function setUnbondingFee(
        uint256 _unbondingFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_unbondingFee <= 1000, "Fee must be 1% or lower");

        uint256 oldUnbondingFee = unbondingFee;
        unbondingFee = _unbondingFee;
        emit SetUnbondingFee(oldUnbondingFee, unbondingFee);
    }

    function setTreasury(
        address _treasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasury != address(0), "EMPTY_ADDRESS");

        address oldTreasury = treasury;
        treasury = _treasury;
        emit SetTreasury(oldTreasury, treasury);
    }

    /**
     * @dev only called if canto network cosmos layer has a new proposal which changes the unbonding duration
     */
    function setUnbondingDuration(
        uint256 _unbondingDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _unbondingDuration <= 21 days,
            "_unbondingDuration is too high"
        );

        uint256 oldUnbondingDuration = unbondingDuration;
        unbondingDuration = _unbondingDuration;

        emit SetUnbondingDuration(oldUnbondingDuration, _unbondingDuration);
    }

    /**
     * @dev Set unbonding processing time. Together with unbondingDuration, they will be used to
     *      estimate the unlock time for user's unbonding request.
     */
    function setUnbondingProcessingTime(
        uint256 _unbondingProcessingTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _unbondingProcessingTime <= 7 days,
            "_unbondingProcessingTime is too high"
        );

        uint256 oldUnbondingProcessingTime = unbondingProcessingTime;
        unbondingProcessingTime = _unbondingProcessingTime;

        emit SetUnbondingMaxProcessingTime(
            oldUnbondingProcessingTime,
            _unbondingProcessingTime
        );
    }

    function convertToShare(uint256 cantoAmount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) return cantoAmount;
        uint256 share = (cantoAmount * totalSupply) / totalPooledCanto;
        // Protect user in the case where user deposit in small amount resulting in 0 share
        require(share > 0, "Invalid share");

        return share;
    }

    function convertToAsset(uint256 shareAmount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) return 0;
        return (shareAmount * totalPooledCanto) / totalSupply;
    }

    function convertToAssetWithUnbondingFee(
        uint256 shareAmount
    ) public view returns (uint256 cantoAmt, uint256 unbondingFeeAmt) {
        uint256 totalCantoAmount = convertToAsset(shareAmount);

        unbondingFeeAmt =
            (totalCantoAmount * unbondingFee) /
            UNBONDING_FEE_DENOMINATOR;
        cantoAmt = totalCantoAmount - unbondingFeeAmt;
    }

    function getUnbondRequestLength() external view returns (uint256) {
        return unbondRequests.length();
    }

    function getUnbondRequests(
        uint256 limit,
        uint256 offset
    ) external view returns (uint256[] memory) {
        uint256[] memory elements = new uint256[](limit);

        for (uint256 i = 0; i < elements.length; i++) {
            elements[i] = unbondRequests.at(i + offset);
        }

        return elements;
    }

    // TODO check this function ,to make sure all the time durations
    /**
     * @notice This is an estimation unlock date
     * @return unboundUnlockDate if the user unbond now
     */
    function getUnbondUnlockDate() public view returns (uint256) {
        // Check if previous batch is in PROCESSx'x'x'xING status. If processing, assume unbonding will be successful
        // soon and thus return unlockTime as block.timestamp + unbondingProcessingTime + unbondingDuration;
        // Note: If this is not in place, it means that protocol will promise an earlier unlock date than possible
        //       during this window of processing -> unbonding (1 hour)
        if (currentUnbondingBatchNo > 0) {
            if (
                batch2UnbondingStatus[currentUnbondingBatchNo - 1] ==
                UnbondingStatus.PROCESSING
            ) {
                return
                    block.timestamp +
                    unbondingProcessingTime +
                    unbondingDuration;
            }
        }
        uint256 nextUnbondTime = lastUnbondTime + unbondingProcessingTime;
        if (nextUnbondTime < block.timestamp) {
            // This happen when contract just deployed (lastUnbondTime = 0) or when the bot has not unbonded
            // since 3 days 12 hours ago (unbondingProcessingTime), could be bot issue.
            // If this is not in place, it means that the protocol will promise an earlier unlock date than possible
            return
                block.timestamp + unbondingProcessingTime + unbondingDuration;
        }
        return nextUnbondTime + unbondingDuration;
    }

    fallback() external payable {}

    receive() external payable {}
}
