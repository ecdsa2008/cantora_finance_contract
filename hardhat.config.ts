import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork:"canto_testnet",
  solidity: "0.8.17",
  networks:{
    hardhat: {},
    canto_testnet: {
      accounts: {
        mnemonic:"resist behave much blade grunt code chapter gorilla prosper sure shiver until"
      },
      chainId:740,
      url:"https://eth.plexnode.wtf/"
    }
  }
};

export default config;
