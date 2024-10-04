import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("MultiSig", () => {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  const deployMultiSigFixture = async () => {
    // Contracts are deployed using the first signer/account by default
    const [signer1, signer2, signer3, signer4, signer5, signer6] =
      await hre.ethers.getSigners();

    const initialSigners = [signer1.address, signer2.address, signer3.address];

    const MyToken = await hre.ethers.getContractFactory("MyToken");
    const MultiSig = await hre.ethers.getContractFactory("Multisig");

    const multiSig = await MultiSig.deploy(2, initialSigners);
    const myToken = await MyToken.deploy(signer1.address);

    return {
      myToken,
      multiSig,
      signer1,
      signer2,
      signer3,
      signer4,
      signer5,
      signer6,
    };
  };

  describe("Deployment", () => {
    it("Should set the right number of signers, quorum, and txCount", async () => {
      const { multiSig } = await loadFixture(deployMultiSigFixture);

      expect(await multiSig.noOfValidSigners()).to.equal(3);
      expect(await multiSig.quorum()).to.equal(2);
      expect(await multiSig.txCount()).to.equal(0);
    });

    it("Should set the right signers", async function () {
      const { multiSig, signer1, signer2, signer3 } = await loadFixture(
        deployMultiSigFixture
      );

      expect(await multiSig.getIsValidSigner(signer1.address)).to.be.true;
      expect(await multiSig.getIsValidSigner(signer2.address)).to.be.true;
      expect(await multiSig.getIsValidSigner(signer3.address)).to.be.true;
    });
  });

  describe("Transfer", () => {
    it("should revert if the transaction id is invalid", async () => {
      const { multiSig } = await loadFixture(deployMultiSigFixture);

      await expect(multiSig.approveTx(0)).to.be.revertedWith("invalid tx id");
    });
    it("should revert if msg.sender is address zero", async () => {
      const { multiSig, signer2 } = await loadFixture(deployMultiSigFixture);

      await expect(multiSig.connect(hre.ethers.).approveTx(0)).to.be.revertedWith(
        "address zero found"
      );
    });
  });
});
