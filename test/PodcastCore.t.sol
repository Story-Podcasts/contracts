// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";
import { IPAssetRegistry } from "lib/protocol-core-v1/contracts/registries/IPAssetRegistry.sol";
import { LicenseRegistry } from "lib/protocol-core-v1/contracts/registries/LicenseRegistry.sol";
import { LicenseToken } from "lib/protocol-core-v1/contracts/LicenseToken.sol";
import { PodcastCore } from "../src/PodcastCore.sol";
import { StoryPod } from "../src/StoryPod.sol";

contract PodcastCoreTest is Test {
    address internal alice = address(0xa11ce);
    address internal bob = address(0xb0b);


    address internal ipAssetRegistryAddr = 0xe34A78B3d658aF7ad69Ff1EFF9012ECa025a14Be;
    address internal licensingModuleAddr = 0xf49da534215DA7b48E57A41d41dac25C912FCC60;
    address internal licenseRegistryAddr = 0xF542AF9a5A6E4A85a4f084D38B322516ec336097;
    address internal licenseTokenAddr = 0xB31FE33De46A1FA5d4Ec669EDB049892E0A1EB4C;
    address internal pilTemplateAddr = 0x8BB1ADE72E21090Fc891e1d4b88AC5E57b27cB31;
    address internal royaltymoduleAddr = 0x968beb5432c362c12b5Be6967a5d6F1ED5A63F01;
    address internal iproyaltyvaultAddr = 0xfb5b5B61c9a437E06Ba87367aaBf3766d091E3D1; //dummy
    address internal royaltypolicylapAddr = 0x61A5c7570f5bDB118D65053Ba60DE87e050E664e;
    IPAssetRegistry public ipAssetRegistry;
    LicenseRegistry public licenseRegistry;
    LicenseToken public licenseToken;

    PodcastCore public podcastCore;
    StoryPod public storyPod;


    function setUp() public {
        ipAssetRegistry = IPAssetRegistry(ipAssetRegistryAddr);
        licenseRegistry = LicenseRegistry(licenseRegistryAddr);
        licenseToken = LicenseToken(licenseTokenAddr);
        podcastCore = new PodcastCore(ipAssetRegistryAddr, licensingModuleAddr, pilTemplateAddr, royaltymoduleAddr, iproyaltyvaultAddr, royaltypolicylapAddr);
        storyPod = StoryPod(podcastCore.STORYPOD_NFT());

        vm.label(address(ipAssetRegistryAddr), "IPAssetRegistry");
        vm.label(address(licensingModuleAddr), "LicensingModule");
        vm.label(address(licenseRegistryAddr), "LicenseRegistry");
        vm.label(address(licenseTokenAddr), "LicenseToken");
        vm.label(address(pilTemplateAddr), "PILicenseTemplate");
        vm.label(address(storyPod), "StoryPod");
        vm.label(address(0x000000006551c19487814612e58FE06813775758), "ERC6551Registry");
    }

    function test_registerandLicenseforUniqueIP() public {
         uint256 expectedTokenId = storyPod.nextTokenId();
        address expectedIpId = ipAssetRegistry.ipId(block.chainid, address(storyPod), expectedTokenId);

        vm.prank(alice);
        (address ipId, uint256 tokenId, uint256 startLicenseTokenId) = podcastCore.registerandLicenseforUniqueIP({
            uri: "abc", //dummy
            ltAmount: 2,
            ltRecipient: bob

        });

        assertEq(ipId, expectedIpId);
        assertEq(tokenId, expectedTokenId);
        assertEq(storyPod.ownerOf(tokenId), alice);

        assertEq(licenseToken.ownerOf(startLicenseTokenId), bob);
        assertEq(licenseToken.ownerOf(startLicenseTokenId + 1), bob);
    }
}
