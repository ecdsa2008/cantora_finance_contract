// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./NFTSVG.sol";

library NFTDescriptor {
    using Strings for uint256;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        address owner;
        uint128 unlockStartTime;
        uint128 unlockEndTime;
        // total liquidCanto amount pending unlock
        uint256 liquidCantoAmount;
        // liquidCanto to canto rate - this can decrease in the event of slashing, require divide by 1e18
        uint256 liquidCanto2CantoExchangeRate;
        uint8 exchangeRateDecimal;
    }

    function generateNFTParams(
        ConstructTokenURIParams memory params
    ) private pure returns (NFTSVG.SVGParams memory) {
        uint256 cantoAmount = getCantoAmount(
            params.liquidCantoAmount,
            params.liquidCanto2CantoExchangeRate,
            params.exchangeRateDecimal
        );
        uint256 liquidCantoAmount = getLiquidCantoAmount(
            params.liquidCantoAmount
        );

        string memory exchangeRate = DecimalString
            .decimalString(
                params.liquidCanto2CantoExchangeRate,
                params.exchangeRateDecimal,
                false
            )
            .result;

        NFTSVG.SVGParams memory params = NFTSVG.SVGParams({
            tokenId: params.tokenId,
            owner: addressToString(params.owner),
            unlockStartTime: getTimeInFormat(params.unlockStartTime),
            unlockEndTime: getTimeInFormat(params.unlockEndTime),
            liquidCantoAmount: liquidCantoAmount,
            cantoAmount: cantoAmount,
            exchangeRate: exchangeRate
        });

        return params;
    }

    function constructTokenURI(
        ConstructTokenURIParams memory params
    ) public pure returns (string memory) {
        NFTSVG.SVGParams memory svgParams = generateNFTParams(params);

        DecimalString.Result memory cantoAmountString = DecimalString
            .decimalString(svgParams.cantoAmount, 18, false);

        string memory name = string(
            abi.encodePacked(
                "Accrue Finance - Claim ",
                cantoAmountString.result,
                " Canto @ ",
                svgParams.unlockEndTime
            )
        );

        DecimalString.Result memory liquidCantoAmountString = DecimalString
            .decimalString(svgParams.liquidCantoAmount, 18, false);

        string memory descriptionPart1 = generateDescriptionPart1(
            cantoAmountString.result,
            svgParams.unlockEndTime,
            svgParams.owner
        );
        // To bypass compilation error, variable length is too long have to separate to two variables.
        string memory descriptionPart2 = generateDescriptionPart2(
            cantoAmountString.result,
            liquidCantoAmountString.result,
            svgParams.unlockEndTime,
            svgParams.tokenId
        );

        string memory image = Base64.encode(bytes(generateSVGImage(svgParams)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPart1,
                                descriptionPart2,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage(
        NFTSVG.SVGParams memory params
    ) internal pure returns (string memory) {
        return NFTSVG.generateSVGImage(params);
    }

    function generateDescriptionPart1(
        string memory cantoAmount,
        string memory unlockEndTime,
        string memory owner
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents a claim to ",
                    cantoAmount,
                    " Canto that will be available after ",
                    unlockEndTime,
                    "\\n",
                    "LCanto Address: ",
                    owner,
                    "\\n"
                )
            );
    }

    function generateDescriptionPart2(
        string memory cantoAmount,
        string memory liquidCantoAmount,
        string memory unlockEndTime,
        uint256 tokenId
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "LCanto burned: ",
                    liquidCantoAmount,
                    "\\n",
                    "Canto to claim: ",
                    cantoAmount,
                    "\\n",
                    "Est. unbound date: ",
                    unlockEndTime,
                    "\\n",
                    "TokenId: ",
                    tokenId.toString()
                )
            );
    }

    function getTimeInFormat(
        uint256 time
    ) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(
            time
        );

        return
            string(
                abi.encodePacked(
                    year.toString(),
                    "/",
                    month.toString(),
                    "/",
                    day.toString()
                )
            );
    }

    function getCantoAmount(
        uint256 liquidCantoAmount,
        uint256 liquidCanto2CantoExchangeRate,
        uint8 exchangeRateDecimal
    ) private pure returns (uint256) {
        uint256 cantoAmount = (liquidCantoAmount *
            liquidCanto2CantoExchangeRate) / 10 ** exchangeRateDecimal;
        uint256 cantoAmountRounded = cantoAmount;

        // round down cantoAmount to the nearest 2 decimal place
        if (cantoAmount > 1e16) {
            cantoAmountRounded = cantoAmount - (cantoAmount % 1e16);
        }
        return cantoAmountRounded;
    }

    function getLiquidCantoAmount(
        uint256 liquidCantoAmount
    ) private pure returns (uint256) {
        uint256 liquidCantoAmountRounded = liquidCantoAmount;

        // round down cantoAmount to the nearest 2 decimal place
        if (liquidCantoAmount > 1e16) {
            liquidCantoAmountRounded =
                liquidCantoAmount -
                (liquidCantoAmount % 1e16);
        }

        return liquidCantoAmountRounded;
    }

    function addressToString(
        address addr
    ) private pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }
}
