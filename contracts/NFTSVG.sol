// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./utils/DateTime.sol";
import "./utils/DecimalString.sol";
import "./NFTDescriptor.sol";

library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        string owner;
        string unlockStartTime;
        string unlockEndTime;
        uint256 liquidCantoAmount;
        uint256 cantoAmount;
        string exchangeRate;
    }

    function generateSVGImage(
        SVGParams memory params
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(),
                    generateCantoAmountText(params),
                    generateUnlockStartTime(params),
                    generateUnlockEndTime(params),
                    generateExchangeRateText(params),
                    generateLiquidCantoAmount(params),
                    generateNFTOwnerInfo(params),
                    "</svg>"
                )
            );
    }

    function generateSVGDefs() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="290" height="500" viewBox="0 0 290 500" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_28_340)"><rect width="290" height="500" fill="white"/><rect x="0.5" y="0.5" width="289" height="499" rx="14.5" fill="white" stroke="url(#paint0_linear_28_340)"/><g filter="url(#filter0_f_28_340)"><path d="M170.578 245.941C174.788 234.091 176.638 219.221 174.118 201.101C178.308 166.091 184.448 120.551 151.458 104.421C140.718 99.6806 132.278 90.2006 121.538 87.3506C113.868 84.5006 110.028 99.6806 113.098 109.171C116.938 119.611 124.608 129.091 123.838 141.431C122.308 153.761 111.558 153.761 104.578 158.081C61.0383 173.231 57.7683 243.321 87.3383 270.371C93.2783 275.801 100.278 279.271 107.598 281.151C108.648 299.251 112.628 316.351 117.928 333.941C125.358 361.341 83.9083 409.241 101.598 411.821C133.818 418.461 165.278 386.201 196.258 368.391C241.258 333.331 222.168 248.731 170.578 245.951V245.941Z" fill="url(#paint1_linear_28_340)"/></g><path d="M0.178894 298.063C6.07889 292.413 12.3589 287.123 17.4489 281.703C61.0889 235.223 26.3989 236.693 0.178894 211.143V217.243C25.7589 240.383 58.6789 238.403 3.72889 288.623C-0.741106 292.703 0.178894 290.673 0.178894 298.063V298.063ZM194.739 144.923C201.249 114.503 178.689 87.2932 184.289 58.1432C189.649 30.2732 227.009 13.7232 249.339 0.133205C244.319 0.133205 247.349 -0.876795 236.649 5.19321C214.909 17.5432 187.029 33.3532 182.329 57.7632C176.629 87.4332 199.139 114.823 192.789 144.493C186.369 174.503 162.319 188.143 123.349 168.423C61.6989 137.253 16.8989 76.0632 4.34889 4.77321C3.73889 5.41321 3.17889 6.09321 2.68889 6.83321C24.4189 136.353 175.719 233.823 194.739 144.923ZM154.169 93.0432C165.219 59.7132 126.629 36.5232 180.669 0.133205H173.649C125.089 35.1232 160.079 62.5132 150.379 91.7832C144.049 110.893 128.739 118.853 102.239 104.533C62.8989 83.3332 34.0989 44.7632 23.1389 0.133205C18.1189 0.133205 18.5189 -1.31679 20.4589 5.74321C42.2189 84.6632 134.409 152.683 154.169 93.0432ZM0.178894 240.363V265.943C5.96889 257.063 7.73889 247.803 0.178894 240.363ZM174.469 118.943C185.039 78.2832 135.829 48.7232 204.419 6.20321C216.719 -1.43679 216.659 0.133205 208.629 0.133205C129.609 47.5132 182.189 77.3532 171.569 118.183C153.969 185.843 44.4089 111.963 17.2989 17.4132C12.3389 0.103205 14.6589 -0.536795 10.2789 0.973205C31.3389 109.613 154.949 193.993 174.469 118.943ZM133.799 67.3032C143.869 45.2332 122.089 25.1932 149.729 0.143205H142.559C118.869 24.8832 137.729 46.6332 129.249 65.2332C122.949 79.0532 111.919 84.1532 91.7189 72.6132C64.6489 57.2032 43.8689 31.0832 33.7489 0.133205H28.4889C44.3889 50.7532 112.109 114.873 133.799 67.2932V67.3032ZM281.799 1.69321C281.699 1.64321 280.759 1.15321 280.659 1.21321C212.569 42.0432 182.939 48.2432 205.739 119.363C210.999 135.763 217.259 152.923 214.019 170.783C196.349 267.953 35.6589 171.433 0.178894 31.7332C0.178894 48.5832 35.5689 154.343 132.789 202.093C178.789 224.693 209.179 207.873 215.729 171.883C219.019 153.773 213.569 136.483 208.279 119.963C185.369 48.5232 214.739 41.9132 281.799 1.69321V1.69321ZM29.6889 125.513C21.3089 107.863 13.4589 88.6932 0.178894 75.2432C0.178894 80.6532 3.92889 73.2232 22.5889 115.363C40.0189 154.703 60.8189 182.813 112.089 209.633C153.559 231.333 132.899 262.213 97.0589 292.303C38.6789 341.323 18.6389 351.843 31.8489 410.313C39.1989 442.873 47.3389 480.713 37.3989 500.133H38.4989C50.9689 474.673 32.2989 419.853 29.3389 387.333C23.6889 325.273 121.889 297.293 135.119 246.473C146.999 200.813 71.7889 214.193 29.6889 125.503V125.513ZM0.178894 433.433C8.74889 421.313 5.02889 399.083 1.09889 375.553C-0.131106 368.173 0.178894 363.953 0.178894 390.963C4.37889 420.093 0.178894 418.383 0.178894 433.443V433.433ZM102.879 247.163C110.859 209.173 48.3689 220.383 12.7389 145.803C8.55889 137.063 4.83889 127.723 0.178894 119.033C0.178894 125.493 -0.851106 120.953 6.24889 136.813C47.1189 228.133 110.199 208.713 100.469 248.003C95.8589 266.563 72.6689 286.233 53.0789 302.643C4.6689 343.203 8.01889 355.983 16.0089 399.293C22.7489 435.813 29.5189 472.133 0.848894 476.063C-0.0411059 476.183 0.178894 475.663 0.178894 478.303C36.0589 474.873 22.5489 424.083 16.2789 388.693C12.3889 366.763 10.0789 351.763 26.2989 331.263C46.9789 305.113 96.4589 277.783 102.879 247.153V247.163ZM70.2689 249.413C76.2989 218.943 30.4789 225.913 0.178894 171.683V178.243C11.9489 197.193 28.4189 212.063 52.1289 225.393C101.189 252.993 18.2289 293.623 0.178894 326.163C0.178894 340.883 -1.92111 333.023 8.26889 320.043C24.7589 298.993 65.2989 274.813 70.2689 249.403V249.413Z" fill="url(#paint2_radial_28_340)"/><path d="M140.943 271.632C166.373 219.822 188.972 232.432 211.582 217.042L180.573 186.023C160.543 165.993 128.053 165.993 108.023 186.023C87.9925 206.053 87.9925 238.543 108.023 258.573L133.882 284.433C136.312 280.513 138.682 276.262 140.952 271.632H140.943Z" fill="white"/><path d="M225.69 446.76C220.89 429.13 209.2 418.11 178.67 395.9C163.57 384.92 140.25 376.06 119.67 368.25C77.12 352.09 69.15 348.8 98.56 324.92C158.21 276.48 135.95 244.55 189.57 227.62C273.38 201.16 210.19 107.88 210.01 81.1C209.77 46.73 245.21 18.48 278.7 12.74C307.48 7.80999 260.92 8.04 230.65 35.04C215.84 48.25 207.75 64.44 207.86 80.64C207.93 90.57 211.18 98.31 215.31 108.11C231.29 146.1 243.44 194.39 209.15 217.25C186.81 232.14 163.98 220.74 138.6 272.44C114.2 322.14 78.53 328.3 79.54 347.63C80.2 360.41 146.87 374 178.1 396.72C208.42 418.77 220.03 429.69 224.75 447.03C229.34 463.91 232.72 474.57 240.87 480.36C252.51 488.64 288.21 486.53 288.21 484.31C237.59 489.04 234.4 478.65 225.72 446.77L225.69 446.76ZM288.18 79.53V76.43C269.28 85.45 253.42 102.37 253.02 122.85C252.66 140.9 290.03 202.74 252.69 229.33C235.93 241.27 218.54 233.33 199.33 273.46C181.01 311.42 154.2 316.3 155.09 332.22C156.02 347.98 248.5 357.96 267.29 415.98C272.08 430.76 276.51 437.18 288.18 439.13V436.46C278.54 434.65 274.38 428.91 269.91 415.14C250.89 356.48 158.58 344.7 157.84 332.06C157.08 318.41 183.62 312.35 201.81 274.65C220.01 236.63 237.7 243.39 254.28 231.57C293.68 203.5 255.41 140.31 255.76 122.9C256.13 104.4 270.55 88.39 288.17 79.53H288.18ZM248.81 434.55C243.5 417.23 243.12 410.75 205.1 382.78C178.65 363.29 119.72 349.7 119.18 339.81C118.32 323.79 149.41 317.35 170.65 273.76C192.54 228.67 212.03 238.83 231.92 225.16C277.38 194.02 232.25 121.67 232.31 101.76C232.5 73.43 260.64 50.59 288.18 43.93V42C259.47 48.77 230.63 72.49 230.43 101.75C230.35 126.79 285.3 208.05 213.16 231.49C164.67 247.25 183.68 273.88 132.36 318.36C104.17 342.79 117.63 346.2 152.88 359.9C170.73 366.83 190.96 374.69 203.99 384.3C230.57 403.85 240.78 413.51 245.16 428.77C252.54 454.52 256.62 463.01 282.88 463.01C288.92 463.01 288.19 463.45 288.19 461.02C260.05 461.89 255.28 455.85 248.82 434.56L248.81 434.55ZM257.99 356.56C239.48 342.35 196.91 330.9 196.51 324.3C195.82 313.04 217.97 307.33 232.99 275.54C252.71 233.8 275.29 252.06 288.19 224.12C292.48 214.82 293 202.86 290.08 186.9C288.82 180.02 288.35 175.35 288.2 179.49C288.2 178.99 288.2 178.5 288.2 177.98C283.48 158.3 270.66 143.35 288.2 122.33V116.85C272.8 132.52 273.93 146.98 279.79 163.3C285.21 178.4 287.38 192.7 288.16 198.72C288.16 201.46 288.18 204.51 288.18 207.9C287.2 226.3 277.9 235.15 262.05 241.47C227.56 255.24 239.08 274.93 204.23 306.95C183.08 326.38 192.75 330 219.93 341.3C232.46 346.51 246.66 352.42 255.8 359.44C284.67 381.44 283.52 385.87 288.2 398.55C288.2 387.1 291.8 382.31 258 356.56H257.99ZM243.24 304.49C272.33 276.42 261.39 263.03 288.18 250.63C288.18 244.65 288.78 245.4 286.39 246.5C278.01 250.38 269.35 254.39 260.07 274.51C248.04 300.62 229.85 304.49 230.67 316.82C231.34 326.93 263.48 331.68 288.18 352.26V346.44C278.3 338.43 272.71 335.62 255.26 327.94C231.9 317.66 230.2 317.07 243.24 304.49V304.49ZM275.95 295.58C261.23 310.92 269.25 314.34 288.18 323.42V317.46C264.22 305.96 273.87 309.18 288.18 289.65C288.18 272.71 291.35 279.55 275.95 295.59V295.58Z" fill="url(#paint3_radial_28_340)"/><rect width="290" height="500" rx="15" fill="url(#paint4_linear_28_340)"/><path d="M25.75 336.75H249C257.422 336.75 264.25 343.578 264.25 352C264.25 360.422 257.422 367.25 249 367.25H25.75V336.75ZM25.75 373.75H249C257.422 373.75 264.25 380.578 264.25 389C264.25 397.422 257.422 404.25 249 404.25H25.75V373.75ZM25.75 441.25V410.75H249C257.422 410.75 264.25 417.578 264.25 426C264.25 434.422 257.422 441.25 249 441.25H25.75ZM25.75 447.75H249C257.422 447.75 264.25 454.578 264.25 463C264.25 471.422 257.422 478.25 249 478.25H25.75V447.75Z" fill="white" stroke="url(#paint5_linear_28_340)" stroke-width="1.5"/><path d="M0 15C0 6.71571 6.71573 0 15 0H30V500H15C6.71573 500 0 493.284 0 485V15Z" fill="#D9D9D9"/><path d="M0 15C0 6.71571 6.71573 0 15 0H30V500H15C6.71573 500 0 493.284 0 485V15Z" fill="url(#paint6_linear_28_340)"/><rect x="1" y="1" width="288" height="498" rx="14" stroke="url(#paint7_linear_28_340)" stroke-width="2"/></g>',
                "<defs>",
                '<filter id="filter0_f_28_340" x="18" y="37" width="253.538" height="425.707" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="25" result="effect1_foregroundBlur_28_340"/></filter>',
                '<linearGradient id="paint0_linear_28_340" x1="4.50011" y1="499.5" x2="4.50021" y2="0.999959" gradientUnits="userSpaceOnUse"><stop stop-color="#6666FF"/><stop offset="1" stop-color="#FF66AD"/></linearGradient>',
                '<linearGradient id="paint1_linear_28_340" x1="129.498" y1="199.351" x2="152.328" y2="319.221" gradientUnits="userSpaceOnUse"><stop stop-color="#FFD2E7"/><stop offset="1" stop-color="#D2F2FF"/></linearGradient>'
                '<radialGradient id="paint2_radial_28_340" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(74.7589 10.4432) scale(251.05)"><stop stop-color="#FF66AD"/><stop offset="1" stop-color="#C9C9FF"/></radialGradient><radialGradient id="paint3_radial_28_340" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(324.54 347.11) scale(220.66 220.66)"><stop stop-color="#C9C9FF"/><stop offset="1" stop-color="#6666FF"/></radialGradient>',
                '<linearGradient id="paint4_linear_28_340" x1="145" y1="0" x2="145" y2="500" gradientUnits="userSpaceOnUse"><stop offset="0.125" stop-color="white"/><stop offset="0.479167" stop-color="white" stop-opacity="0"/><stop offset="0.479267" stop-color="white" stop-opacity="0"/><stop offset="0.90625" stop-color="white"/></linearGradient>',
                '<linearGradient id="paint5_linear_28_340" x1="23.9171" y1="463" x2="265.958" y2="463" gradientUnits="userSpaceOnUse"><stop stop-color="#6666FF"/><stop offset="1" stop-color="#FF66AD"/></linearGradient>',
                '<linearGradient id="paint6_linear_28_340" x1="0" y1="500" x2="0" y2="0" gradientUnits="userSpaceOnUse"><stop stop-color="#6666FF"/><stop offset="1" stop-color="#FF66AD"/></linearGradient>',
                '<linearGradient id="paint7_linear_28_340" x1="4.50011" y1="499.5" x2="4.50021" y2="0.999959" gradientUnits="userSpaceOnUse"><stop stop-color="#6666FF"/><stop offset="1" stop-color="#FF66AD"/></linearGradient>',
                '<clipPath id="clip0_28_340"><rect width="290" height="500" fill="white"/></clipPath>',
                "</defs>"
            )
        );
    }

    function generateCantoAmountText(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        uint256 fontSize = 20;
        uint256 cantoAmountRounded = params.cantoAmount;

        // round down cantoAmount to the nearest 2 decimal place
        if (params.cantoAmount > 1e16) {
            cantoAmountRounded =
                params.cantoAmount -
                (params.cantoAmount % 1e16);
        }

        DecimalString.Result memory decimalString = DecimalString.decimalString(
            cantoAmountRounded,
            18,
            false
        );

        if (decimalString.length < 12) {
            fontSize = 36;
        } else if (decimalString.length < 18) {
            fontSize = 25;
        }

        svg = string(
            abi.encodePacked(
                '<text y="50px" x="45px" fill="#1D0063" font-family="Arial" font-weight="800" font-size="36px" font-style="italic">Canto </text>',
                '<text y="90px" x="45px" fill="#1D0063" font-family="Arial" font-weight="800" font-size="',
                fontSize.toString(),
                'px" font-style="italic">',
                decimalString.result,
                "</text>"
            )
        );
    }

    function generateLiquidCantoAmount(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        uint256 fontSize = 10;
        uint256 liquidCantoAmountRounded = params.liquidCantoAmount;

        // round down cantoAmount to the nearest 2 decimal place
        if (params.liquidCantoAmount > 1e16) {
            liquidCantoAmountRounded =
                params.liquidCantoAmount -
                (params.liquidCantoAmount % 1e16);
        }

        DecimalString.Result memory decimalString = DecimalString.decimalString(
            liquidCantoAmountRounded,
            18,
            false
        );

        if (decimalString.length < 20) {
            fontSize = 12;
        } else if (decimalString.length < 22) {
            fontSize = 11;
        }

        svg = string(
            abi.encodePacked(
                '<text y="468px" x="45px" fill="black" font-family="Arial" font-weight="800" font-size="12px">LCanto amount:</text>',
                '<text y="468px" x="135px" fill="black" font-family="Arial" font-size="',
                fontSize.toString(),
                'px">',
                decimalString.result,
                "</text>"
            )
        );
    }

    function generateExchangeRateText(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text y="430px" x="45px" fill="black" font-family="Arial" font-weight="800" font-size="12px">Exchange rate:</text>',
                '<text y="430px" x="135px" fill="black" font-family="Arial" font-size="12px">',
                params.exchangeRate,
                " Canto",
                "</text>"
            )
        );
    }

    function generateNFTOwnerInfo(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text word-spacing="6px" x="75px" y="-10px" fill="#FFFFFF" font-family="Arial" transform="rotate(90)" font-size="13px" font-weight="700">',
                params.owner,
                " LCanto",
                "</text>"
            )
        );
    }

    function generateUnlockStartTime(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text y="355px" x="45px" fill="black" font-family="Arial" font-weight="800" font-size="12px">Mint date:</text>',
                '<text y="355px" x="105px" fill="black" font-family="Arial" font-size="12px">',
                params.unlockStartTime,
                "</text>"
            )
        );
    }

    function generateUnlockEndTime(
        SVGParams memory params
    ) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text y="393px" x="45px" fill="black" font-family="Arial" font-weight="800" font-size="12px">Unlock date:</text>',
                '<text y="393" x="120px" fill="black" font-family="Arial" font-size="12px">',
                params.unlockEndTime,
                "</text>"
            )
        );
    }
}
