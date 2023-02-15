import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: "canto_testnet",
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {},
    canto_testnet: {
      accounts: {
        mnemonic: "resist behave much blade grunt code chapter gorilla prosper sure shiver until"
      },
      chainId: 740,
      url: "https://eth.plexnode.wtf/"
    }
  }
};

export default config;
