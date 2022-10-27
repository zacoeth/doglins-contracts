// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./lib/GIGADRIP20.sol";
import "./lib/Administration.sol";

contract ENERGY is Administration, GIGADRIP20 {


    address public doglinsContract;
   

   modifier onlyOwnerOrDoglinsContract(){
        require(_msgSender() == doglinsContract || _msgSender == owner());
        _;
   }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) GIGADRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    /**
     * @dev only scrolls can start dripping tokens (on mint or transfer).
     * owner can override and start dripping if theres any issue.
     * will remove ownership when not needed so extra tokens cannot be arbitrarily dripped.
     */
    function startDripping(address addr, uint128 multiplier) external onlyOwnerOrDoglinsContract {
        _startDripping(addr, multiplier);
    }

    /**
     * @dev only scrolls can stop dripping tokens (on burn or transfer).
     * owner can override and stop dripping if theres any issue.
     * will remove ownership when not needed so tokens cannot be arbitrarily stopped.
     */
    function stopDripping(address addr, uint128 multiplier) external onlyOwnerOrDoglinsContract {
        _stopDripping(addr, multiplier);
    }

    function burn(address from, uint256 value) external {
        uint256 allowed = allowance[from][_msgSender()]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max)
            allowance[from][_msgSender()] = allowed - value;
        _burn(from, value);
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    /**
     * @dev mint tokens to desired address.
     * may be used for prize pools, DEX liquidity, etc.
     * will remove ownership when not needed so extra tokens cannot be minted.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setDoglinsAddress(address doglinsContract_)
        external
        onlyOwner
    {
        doglinsContract = doglinsContract_;
    }
}