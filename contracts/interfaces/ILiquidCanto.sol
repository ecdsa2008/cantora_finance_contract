// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILiquidCanto {
    enum UnbondingStatus {
        PENDING_BOT, // batch is waiting for bot process
        PROCESSING, // bot started processing, new unbonding request will be in next batch
        UNBONDING, // bot finished processing unbonding request for this batch，bot has successfully informed validator to start unbonding
        UNBONDED // batch is unbonded, user can redeem canto
    }

    /// @notice Emitted when user stake Canto
    event Stake(
        address indexed receiver,
        uint256 CantoAmount,
        uint256 shareAmount
    );

    /// @notice Emitted when a user request to unbond their staked Canto
    event RequestUnbond(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 shareAmount,
        uint256 liquidCanto2CantoExchangeRate,
        uint256 batchNo
    );

    /// @notice Emitted when a user redeems the NFT for Canto
    event Unbond(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 CantoAmount,
        uint256 CantoFeeAmount
    );

    /// @notice Emitted when the bot has an update for an unbonding batch
    event SetUnbondingBatchStatus(uint256 batchNo, UnbondingStatus status);

    /// @notice Emitted when the bot claim reward from Canto cosmos layer
    event AccrueReward(uint256 indexed amount, string indexed txnHash);

    /// @notice Emitted when a slash happen on unbonding request
    event SlashRequest(
        uint256 tokenId,
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );

    /// @notice Emitted when a slash happen on Canto cosmos layer
    event Slash(
        string indexed validatorAddress,
        uint256 indexed amount,
        uint256 time
    );

    /// @notice Emitted when new unbonding fee is set
    event SetUnbondingFee(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when new treasury is set
    event SetTreasury(address oldTreasury, address newTreasury);

    /// @notice Emitted when the unbonding duration is updated
    event SetUnbondingDuration(
        uint256 oldUnbondingDuration,
        uint256 newUnbondingDuration
    );

    /// @notice Emitted when unbonding processing time is updated
    event SetUnbondingMaxProcessingTime(
        uint256 oldUnbondingMaxProcessingDuration,
        uint256 newUnbondingMaxProcessingDuration
    );

    /// @notice Emitted when AccrueNFT is created
    event AccrueNFTCreate(address creator, address addr);

    /// @notice Emitted when gather canto for delegate
    event GatherCantoForDelegate(uint256 amount);

    /// @notice Emitted when bot send canto in
    event Deposit(uint256 amount);

    function stake(address receiver) external payable returns (uint256);

    function requestUnbond(
        uint256 shareAmount,
        address receiver
    ) external returns (uint256);

    function batchRedeem(
        uint256[] calldata _tokenIds,
        address _receiver
    ) external returns (uint256);

    function redeemCanto(
        uint256 tokenId,
        address receiver
    ) external returns (uint256);

    function accrueReward(uint256 amount, string calldata txnHash) external;

    function gatherForDelegate(uint256 amount) external;

    function slash(
        string calldata validatorAddress,
        uint256 amount,
        uint256 time
    ) external;

    function slashUnbondingRequests(
        uint256[] calldata _tokenIds,
        uint256[] calldata _exchangeRates
    ) external;

    function deposit() external payable;

    function setUnbondingBatchStatus(
        uint256 _batchNo,
        UnbondingStatus _status
    ) external;

    function setUnbondingFee(uint256 _unbondingFee) external;

    function setTreasury(address _treasury) external;

    function setUnbondingDuration(uint256 _unbondingDuration) external;

    function setUnbondingProcessingTime(
        uint256 _unbondingProcessingTime
    ) external;

    function convertToShare(
        uint256 cantoAmount
    ) external view returns (uint256);

    function convertToAsset(
        uint256 shareAmount
    ) external view returns (uint256);

    function convertToAssetWithUnbondingFee(
        uint256 shareAmount
    ) external view returns (uint256 cantoAmt, uint256 unbondingFeeAmt);

    function getUnbondRequestLength() external view returns (uint256);

    function getUnbondRequests(
        uint256 limit,
        uint256 offset
    ) external view returns (uint256[] memory);

    function getUnbondUnlockDate() external returns (uint256);
}
