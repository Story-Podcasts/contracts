//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

contract Pod is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit, ERC20FlashMint {
    uint256 public immutable LISTEN_HOURS_PER_TOKEN = 1; // 1 token per listen hour
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 33; // 33% platform fee

    mapping(address => uint256) public listeningHours;

    constructor(address initialOwner)
        ERC20("Pod", "POD")
        Ownable(initialOwner)
        ERC20Permit("Pod")
    {
       
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintFromListening(address user, uint256 hr) external onlyOwner {
        listeningHours[user] += hr;
        uint256 tokensEarned = listeningHours[user] / LISTEN_HOURS_PER_TOKEN;
        if (tokensEarned > 0) {
            listeningHours[user] %= LISTEN_HOURS_PER_TOKEN;
            _mint(user, tokensEarned);
        }
        //api
    }
    function unlockPremiumContent(uint256 tokenAmount) public {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        uint256 burnAmount = (tokenAmount * (100 - PLATFORM_FEE_PERCENTAGE)) / 100;
        uint256 platformFee = tokenAmount - burnAmount;

        _burn(msg.sender, burnAmount);
        _transfer(msg.sender, owner(), platformFee);

    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}

