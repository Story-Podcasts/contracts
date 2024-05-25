// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import { IPAssetRegistry } from "lib/protocol-core-v1/contracts/registries/IPAssetRegistry.sol";
import { LicensingModule } from "lib/protocol-core-v1/contracts/modules/licensing/LicensingModule.sol";
import { PILicenseTemplate } from "lib/protocol-core-v1/contracts/modules/licensing/PILicenseTemplate.sol";
import {RoyaltyModule} from "lib/protocol-core-v1/contracts/modules/royalty/RoyaltyModule.sol";
import {IPAccountRegistry} from "lib/protocol-core-v1/contracts/registries/IPAccountRegistry.sol";
import {IIPAccount} from "lib/protocol-core-v1/contracts/interfaces/IIPAccount.sol";
import {RoyaltyPolicyLAP} from "";
import { StoryPod } from "./StoryPod.sol";

/// @notice Register content as an NFT with an IP Account.License,remix and enjoy shared revenue from your creation.
contract PodcastCore {
    IPAssetRegistry public immutable IP_ASSET_REGISTRY;
    IPAccountRegistry public immutable IP_ACCOUNT_REGISTRY;
    LicensingModule public immutable LICENSING_MODULE;
    PILicenseTemplate public immutable PIL_TEMPLATE;
    RoyaltyModule public immutable ROYALTY_MODULE;
    StoryPod public immutable STORYPOD_NFT;
    

   struct IpDetails {
        uint256 tokenId;
        address ipId;
    }

    mapping (address => string) internal userNames;
    mapping (address => IpDetails[]) internal ipDetails;

    event remixRequest(address indexed ipOwner, uint256 requestedLtAmount, address indexed recipient, string message);
    event remixPermissionGranted(address indexed ipId, uint256 ltAmount, address indexed recipient, string message);

    constructor(address ipAssetRegistry,address licensingModule, address pilTemplate) {
        IP_ASSET_REGISTRY = IPAssetRegistry(ipAssetRegistry);
       LICENSING_MODULE = LicensingModule(licensingModule);
        PIL_TEMPLATE = PILicenseTemplate(pilTemplate);
        STORYPOD_NFT = new StoryPod(msg.sender);
    }

    /// @notice Mint an IP NFT, register it as an IP Account and attach license terms via Story Protocol core.
    /// @param uri of the episode from ipfs
    /// @return ipId The address of the IP Account
    /// @return tokenId The token ID of the IP NFT

    function mintUniqueIp(string memory uri) external returns (address ipId, uint256 tokenId) {
        tokenId = STORYPOD_NFT.safeMint(address(this), uri);
        ipId = IP_ASSET_REGISTRY.register(block.chainid, address(STORYPOD_NFT), tokenId);
        //commercial license with remix royalty, so 3
        LICENSING_MODULE.attachLicenseTerms(ipId, address(PIL_TEMPLATE), 3);
        STORYPOD_NFT.transferFrom(address(this), msg.sender, tokenId);
         ipDetails[msg.sender].push((
            tokenId,
            ipId
        ));
    }
    

    function requestRemixFromIPOwner(address ipId, uint256 ltAmount, string memory message) external {
        // find ip owner
        emit remixRequest(address(0), ltAmount, msg.sender, message);
    }

    /// @notice Mint License tokens to the recipient who wants to remix your content.
    ///@param ipId The address of the IP Account
    /// @param ltAmount amount of license token to be minted
    /// @param  ltRecipient address of the recipient whom you grant the license to remix
    /// @param message a short message to the recipient
    /// @return startLicenseTokenId

    function mintLicenseTokenForUniqueIP(address ipId ,uint256 ltAmount,address ltRecipient, string memory message) 
    external returns (uint256 startLicenseTokenId)
    {
        startLicenseTokenId = LICENSING_MODULE.mintLicenseTokens({
            licensorIpId: ipId,
            licenseTemplate: address(PIL_TEMPLATE),
            licenseTermsId: 3,
            amount: ltAmount,
            receiver: ltRecipient,
            royaltyContext: "" 
        });
        emit remixPermissionGranted(ipId, ltAmount, ltRecipient, message);
    }

    ///@notice Remix IP :Register a derived episode IP NFT and mint License Tokens


    function registerAndMintTokenForRemixIP(
        uint256 ltAmount,
        address ltRecipient,string memory uri
    ) external returns (address ipId, uint256 tokenId, uint256 startLicenseTokenId) {
        
        address current= address(this);
        tokenId =  STORYPOD_NFT.safeMint(current,uri);
        ipId = IP_ASSET_REGISTRY.register(block.chainid, address(STORYPOD_NFT), tokenId);

        LICENSING_MODULE.attachLicenseTerms(ipId, address(PIL_TEMPLATE), 3);

        startLicenseTokenId = LICENSING_MODULE.mintLicenseTokens({
            licensorIpId: ipId,
            licenseTemplate: address(PIL_TEMPLATE),
            licenseTermsId: 3,
            amount: ltAmount,
            receiver: ltRecipient,
            royaltyContext: "" 
        });
         STORYPOD_NFT.transferFrom(address(this), msg.sender, tokenId);
         ipDetails[msg.sender].push((
            tokenId,
            ipId
        ));
    }



    //---Royalty----//

    function tipEpisode(address ipId) external payable {
        require(msg.value > 0, "Please tip more than zero");

        ROYALTY_MODULE.payRoyaltyOnBehalf(
         ipId,
         payerIpId,//ask jacob what to do when a user tips, why ipid for user
         token,
         amount);


    }

    function collectFirstRoyalty(address ipId)
    {
       address ipVaultAddress =  ROYALTYPOLICYLAP.getRoyaltyData(
        address ipId);
        IPROYALTYVAULT.collectRoyaltyTokens(address ipId);
    
    }


    function withdrawEarnings(address ipId, address tokenaddress) external payable{
        //check msg.sender == ipid owner
        //balance greater than 0
       uint256 snapshotid = IPROYALTYVAULT.snapshot();
       claimRevenueBySnapshotBatch(snapshotid,tokenaddress);
    }

    function registerUser(string memory _userName) external {
        userNames[msg.sender] = _userName;
    }

    function getUserName() public view returns (string memory) {
        string memory userName = userNames[msg.sender];
        require(bytes(userName).length > 0, "Username is not set");
        return userName;
    }
    function getIpDetails() public view returns (IpDetails[]) {
        return ipDetails[msg.sender];
    }
   function owner(tokenId) public view returns (address) {
        IPACCOUNTIMPL.owner();//no param in protocol file, check again
    }

    }

