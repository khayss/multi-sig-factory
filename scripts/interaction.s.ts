import hre from "hardhat";

const factoryContractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const tokenContractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

const iFactory = new hre.ethers.Interface([
  "function createMultisigWallet(uint256 _quorum,address[] memory _validSigners) external returns (address newMulsig_, uint256 length_)",
  "event MultisigWalletCreate(address indexed newMultisig, uint256 indexed length)",
]);

async function main() {
  const multisigFactory = await hre.ethers.getContractAt(
    "MultisigFactory",
    factoryContractAddress
  );
  const myToken = await hre.ethers.getContractAt(
    "MyToken",
    tokenContractAddress
  );

  const [account1, account2, account3, account4] =
    await hre.ethers.getSigners();

  console.log("Creating a new multisig wallet");

  const multisigCreateTx = await multisigFactory.createMultisigWallet(2, [
    account1.address,
    account2.address,
    account3.address,
  ]);
  const multiSigCreateRes = await multisigCreateTx.wait();
  console.log("Multisig wallet created at", multisigCreateTx.hash);
  console.log(multisigCreateTx);

  



//   const decodedData = iFactory.decodeEventLog("MultisigWalletCreate", multiSigCreateRes.d);

//   console.log("Decoded data", decodedData);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
