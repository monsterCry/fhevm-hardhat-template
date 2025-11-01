import { DeployFunction, SimpleTx } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy, execute } = hre.deployments;

  const deployedFHECounter = await deploy("FHECounter", {
    from: deployer,
    log: true,
  });

  console.log(`FHECounter contract: `, deployedFHECounter.address, deployer);

  const deployedCat = await deploy("EvolvingMonster", {
    from: deployer,
    log: true,
  });
  console.log(`EvolvingMonster contract: `, deployedCat.address, deployer);

  const deployedCatMarket = await deploy("GeneMarketplace", {
    from: deployer,
    log: true,
    args: [deployedCat.address],
  });
  console.log(`GeneMarketplace contract: `, deployedCatMarket.address, deployer);

  const deployedInentory = await deploy("Inventory", {
    from: deployer,
    log: true,
  });
  console.log(`Inventory contract: `, deployedInentory.address, deployer);

  const deployedFightingRoom = await deploy("FightingRoom", {
    from: deployer,
    log: true,
    args: [deployedCat.address, deployedInentory.address],
  });
  console.log(`FightingRoom contract: `, deployedFightingRoom.address, deployer);

  const deployedMinter = await deploy("Minter", {
    from: deployer,
    log: true,
    args: [deployedCat.address, deployedCatMarket.address, deployedFightingRoom.address, deployedInentory.address],
  });
  console.log(`Minter contract: `, deployedMinter.address, deployer);

  console.log("setup evolingMonster");
  let receipt = await execute(
    "EvolvingMonster",
    { from: deployer },
    "setup",
    deployedMinter.address,
    deployedCatMarket.address,
    deployedFightingRoom.address,
  );
  console.log("setup evolingMonster tx", receipt.blockHash);

  receipt = await execute("EvolvingMonster", { from: deployer }, "transferOwnership", deployedMinter.address);
  console.log("transferOwnership tx", receipt.blockHash);
};
export default func;
func.id = "deploy_fheCounter"; // id required to prevent reexecution
func.tags = ["FHECounter"];
