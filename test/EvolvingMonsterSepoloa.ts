// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { ethers, fhevm } from "hardhat";
// import {
//   EvolvingMonster,
//   EvolvingMonster__factory,
//   GeneMarketplace,
//   GeneMarketplace__factory,
//   FightingRoom,
//   FightingRoom__factory,
//   Inventory,
//   Inventory__factory,
//   Minter,
//   Minter__factory,
// } from "../types";
// import { expect } from "chai";
// import { FhevmType } from "@fhevm/hardhat-plugin";

// type Signers = {
//   deployer: HardhatEthersSigner;
//   alice: HardhatEthersSigner;
//   bob: HardhatEthersSigner;
// };

// async function deployFixture() {
//   const factory = (await ethers.getContractFactory("EvolvingMonster")) as EvolvingMonster__factory;
//   const EvolvingMonsterContract = (await factory.deploy()) as EvolvingMonster;
//   const EvolvingMonsterContractAddress = await EvolvingMonsterContract.getAddress();
//   console.log(`EvolvingMonster contract: `, EvolvingMonsterContractAddress);

//   const factoryMarket = (await ethers.getContractFactory("GeneMarketplace")) as GeneMarketplace__factory;
//   const GeneMarketplaceContract = (await factoryMarket.deploy(EvolvingMonsterContractAddress)) as GeneMarketplace;
//   const GeneMarketplaceContractAddress = await GeneMarketplaceContract.getAddress();
//   console.log(`GeneMarketplace contract: `, GeneMarketplaceContractAddress);

//   const factoryInventory = (await ethers.getContractFactory("Inventory")) as Inventory__factory;
//   const InventoryContract = (await factoryInventory.deploy()) as Inventory;
//   const InventoryContractAddress = await InventoryContract.getAddress();
//   console.log(`Inventory contract: `, InventoryContractAddress);

//   const factoryFightingRoom = (await ethers.getContractFactory("FightingRoom")) as FightingRoom__factory;
//   const FightingRoomContract = (await factoryFightingRoom.deploy(
//     EvolvingMonsterContractAddress,
//     InventoryContractAddress,
//   )) as FightingRoom;
//   const FightingRoomContractAddress = await FightingRoomContract.getAddress();
//   console.log(`FightingRoom contract: `, FightingRoomContractAddress);

//   const factoryMinter = (await ethers.getContractFactory("Minter")) as Minter__factory;
//   const MinterContract = (await factoryMinter.deploy(
//     EvolvingMonsterContractAddress,
//     GeneMarketplaceContractAddress,
//     FightingRoomContractAddress,
//     InventoryContractAddress,
//   )) as Minter;
//   const MinterAddress = await MinterContract.getAddress();
//   console.log(`Minter contract: `, MinterAddress);

//   console.log("setup evolingMonster");
//   let receipt = await EvolvingMonsterContract.setup(
//     MinterAddress,
//     GeneMarketplaceContractAddress,
//     FightingRoomContractAddress,
//   );
//   console.log("setup evolingMonster tx", receipt.blockHash);

//   receipt = await EvolvingMonsterContract.transferOwnership(MinterAddress);
//   console.log("transferOwnership tx", receipt.blockHash, "\r\n");

//   return {
//     EvolvingMonsterContract,
//     EvolvingMonsterContractAddress,
//     GeneMarketplaceContract,
//     GeneMarketplaceContractAddress,
//     InventoryContract,
//     InventoryContractAddress,
//     FightingRoomContract,
//     FightingRoomContractAddress,
//     MinterContract,
//     MinterAddress,
//   };
// }

// describe("EvolMonster test", function () {
//   let signers: Signers;

//   let player1: HardhatEthersSigner;
//   let player2: HardhatEthersSigner;

//   let EvolvingMonsterContract: EvolvingMonster;
//   let EvolvingMonsterContractAddress: string;

//   let GeneMarketplaceContract: GeneMarketplace;
//   let GeneMarketplaceContractAddress: string;

//   let InventoryContract: Inventory;
//   let InventoryContractAddress: string;

//   let FightingRoomContract: FightingRoom;
//   let FightingRoomContractAddress: string;

//   let MinterContract: Minter;
//   let MinterAddress: string;

//   before(async function () {
//     const ethSigners: HardhatEthersSigner[] = await ethers.getSigners();
//     player1 = ethSigners[0];
//     player2 = ethSigners[1];
//     signers = { deployer: ethSigners[0], alice: ethSigners[1], bob: ethSigners[2] };
//   });

//   beforeEach(async function () {
//     // Check whether the tests are running against an FHEVM mock environment
//     if (!fhevm.isMock) {
//       console.warn(`This hardhat test suite cannot run on Sepolia Testnet`);
//       this.skip();
//     }
//     if (EvolvingMonsterContract) {
//       return;
//     }
//     console.log("===beforeEach");
//     ({
//       EvolvingMonsterContract,
//       EvolvingMonsterContractAddress,
//       GeneMarketplaceContract,
//       GeneMarketplaceContractAddress,
//       InventoryContract,
//       InventoryContractAddress,
//       FightingRoomContract,
//       FightingRoomContractAddress,
//       MinterContract,
//       MinterAddress,
//     } = await deployFixture());
//   });

//   it("Mint Monster", async function () {
//     const tx = await MinterContract.connect(player1).mintMonsterEgg("test1");
//     await tx.wait();
//     await EvolvingMonsterContract.getProperty(player1.address);
//     //console.log(tx.hash, prop);

//     const tx1 = await MinterContract.connect(player2).mintMonsterEgg("test2");
//     await tx1.wait();
//     await EvolvingMonsterContract.getProperty(player2.address);
//     //console.log(tx1.hash, prop1);
//     //console.log(await EvolvingMonsterContract.tokenURI(1));
//   });

//   it("Make Monster Battle", async function () {
//     let prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     let prop2 = await EvolvingMonsterContract.getProperty(player2.address);
//     //console.log(prop1, prop2);
//     let tx = await FightingRoomContract.connect(player1).attack(prop2[5]);
//     await tx.wait();

//     tx = await FightingRoomContract.connect(player2).attack(prop1[5]);
//     await tx.wait();
//     prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     prop2 = await EvolvingMonsterContract.getProperty(player2.address);
//     //console.log(prop1, prop2);
//     // console.log(await EvolvingMonsterContract.tokenURI(prop1[5]));
//     // console.log(await EvolvingMonsterContract.tokenURI(prop2[5]));
//   });

//   it("Make Gene Exchage Request", async function () {
//     const prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     const prop2 = await EvolvingMonsterContract.getProperty(player2.address);
//     let tx = await GeneMarketplaceContract.connect(player1).makeCrossOverRequest(prop2[5], {
//       value: ethers.parseEther("0.1"),
//     });
//     await tx.wait();

//     tx = await GeneMarketplaceContract.connect(player2).makeCrossOverRequest(prop1[5], {
//       value: ethers.parseEther("0.1"),
//     });
//     await tx.wait();

//     let po = await GeneMarketplaceContract.palyerOffers(0);
//     let lo = await GeneMarketplaceContract.palyerOwnerOffers(0);
//     //console.log(po, lo);

//     tx = await GeneMarketplaceContract.connect(player1).acceptCrossOverRequest(po[0][5]);
//     await tx.wait();

//     tx = await GeneMarketplaceContract.connect(player2).acceptCrossOverRequest(lo[0][5]);
//     await tx.wait();

//     po = await GeneMarketplaceContract.palyerOffers(0);
//     lo = await GeneMarketplaceContract.palyerOwnerOffers(0);
//     //console.log(po, lo);
//   });

//   it("Use Manta", async function () {
//     await MinterContract.connect(player1).gm();
//     await MinterContract.connect(player2).gm();

//     let prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     let prop2 = await EvolvingMonsterContract.getProperty(player2.address);

//     console.log(await InventoryContract.tokenURI(1));

//     let m1 = await InventoryContract.balanceOfType(player1.address, 1);
//     let m2 = await InventoryContract.balanceOfType(player2.address, 1);
//     console.log(m1, m2);
//     m1 = await InventoryContract.balanceOfType(player1.address, 2);
//     m2 = await InventoryContract.balanceOfType(player2.address, 2);
//     console.log(m1, m2);
//     await MinterContract.connect(player1).makeMutation(1);
//     await MinterContract.connect(player2).makeMutation(3);

//     prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     prop2 = await EvolvingMonsterContract.getProperty(player2.address);
//     console.log(prop1, prop2);
//   });

//   it("Decode Property", async function () {
//     const prop1 = await EvolvingMonsterContract.getProperty(player1.address);
//     const prop2 = await EvolvingMonsterContract.getProperty(player2.address);
//     for (let i = 0; i < 3; i++) {
//       let decVar = await fhevm.userDecryptEuint(
//         FhevmType.euint64,
//         prop1[0][i],
//         EvolvingMonsterContractAddress,
//         player1,
//       );
//       console.log("p1=" + decVar);

//       decVar = await fhevm.userDecryptEuint(FhevmType.euint64, prop2[0][i], EvolvingMonsterContractAddress, player2);
//       console.log("p2=" + decVar);
//     }
//   });

//   // it("increment the counter by 1", async function () {
//   //   const encryptedCountBeforeInc = await fheCounterContract.getCount();
//   //   expect(encryptedCountBeforeInc).to.eq(ethers.ZeroHash);
//   //   const clearCountBeforeInc = 0;

//   //   // Encrypt constant 1 as a euint32
//   //   const clearOne = 1;
//   //   const encryptedOne = await fhevm
//   //     .createEncryptedInput(fheCounterContractAddress, signers.alice.address)
//   //     .add32(clearOne)
//   //     .encrypt();

//   //   const tx = await fheCounterContract
//   //     .connect(signers.alice)
//   //     .increment(encryptedOne.handles[0], encryptedOne.inputProof);
//   //   await tx.wait();

//   //   const encryptedCountAfterInc = await fheCounterContract.getCount();
//   //   const clearCountAfterInc = await fhevm.userDecryptEuint(
//   //     FhevmType.euint32,
//   //     encryptedCountAfterInc,
//   //     fheCounterContractAddress,
//   //     signers.alice,
//   //   );

//   //   expect(clearCountAfterInc).to.eq(clearCountBeforeInc + clearOne);
//   // });

//   // it("decrement the counter by 1", async function () {
//   //   // Encrypt constant 1 as a euint32
//   //   const clearOne = 1;
//   //   const encryptedOne = await fhevm
//   //     .createEncryptedInput(fheCounterContractAddress, signers.alice.address)
//   //     .add32(clearOne)
//   //     .encrypt();

//   //   // First increment by 1, count becomes 1
//   //   let tx = await fheCounterContract
//   //     .connect(signers.alice)
//   //     .increment(encryptedOne.handles[0], encryptedOne.inputProof);
//   //   await tx.wait();

//   //   // Then decrement by 1, count goes back to 0
//   //   tx = await fheCounterContract.connect(signers.alice).decrement(encryptedOne.handles[0], encryptedOne.inputProof);
//   //   await tx.wait();

//   //   const encryptedCountAfterDec = await fheCounterContract.getCount();
//   //   const clearCountAfterInc = await fhevm.userDecryptEuint(
//   //     FhevmType.euint32,
//   //     encryptedCountAfterDec,
//   //     fheCounterContractAddress,
//   //     signers.alice,
//   //   );

//   //   expect(clearCountAfterInc).to.eq(0);
//   // });
// });
