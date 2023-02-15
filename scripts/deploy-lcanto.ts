import { ethers } from "hardhat";
async function main() {
    const [admin, bot, treasury] = await ethers.getSigners();
    console.log("admin is ", admin.address)
    console.log("bot is ", bot.address);
    console.log("treasury is ", treasury.address);

    const nftDescriptor = await deployNFTDescriptor();
    console.log("nftDescriptor contract is ", nftDescriptor);

    const liquidCantoFactory = await ethers.getContractFactory("LiquidCanto", {
        libraries: {
            "NFTDescriptor": nftDescriptor
        }
    });
    const liquidCanto = await liquidCantoFactory.deploy(bot.address, treasury.address);
    console.log("liquidCanto contract is ",liquidCanto.address)
}

async function deployNFTDescriptor(): Promise<string> {
    const factory = await ethers.getContractFactory("NFTDescriptor");
    const nft = await factory.deploy();
    return nft.address
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
