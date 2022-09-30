import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { verify, updateDeployments, constants } from './utils';
import _ from 'lodash';

// It does not deploy, but registers assets to YieldBox
// Created as a separate file in case YieldBox is already there
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments } = hre;
    const chainId = await hre.getChainId();

    let yieldBoxAddress = constants[chainId].yieldBoxAddress;
    if (
        !hre.ethers.utils.isAddress(yieldBoxAddress!) ||
        yieldBoxAddress == hre.ethers.constants.AddressZero
    ) {
        const deployedYieldBox = await deployments.get('YieldBox');
        yieldBoxAddress = deployedYieldBox.address;
    }

    const yieldBoxContract = await hre.ethers.getContractAt(
        'YieldBox',
        yieldBoxAddress,
    );

    for (let i = 0; i < constants[chainId].assets; i++) {
        const asset = constants[chainId].assets[i];
        console.log(`\n   registering ${asset.name}`);
        await (
            await yieldBoxContract.registerAsset(
                1,
                asset.address,
                hre.ethers.constants.AddressZero,
                0,
            )
        ).wait();
        console.log(`   done`);
    }
};

export default func;
func.tags = ['YieldBoxAssets'];
