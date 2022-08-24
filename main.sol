// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Vizmesh {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract DecentralizedCurationToken is ERC20, ERC20Burnable, Ownable {
    uint256 converter = 1000000000000000000;
    uint256 supplyCap = 21000000 * converter;
    uint256 supplyMinted = 0;
    address public vizmeshSmartContractAddress;
    mapping(uint256 => uint256) public lastClaimTimestamps;
    

    uint256[] multiplierFrmIds;
    uint256[] multiplierAmountsHundreths;
    uint256 distributionRate = 1;
    uint256 startBlockTimestamp = 1646205522; //This is when the mainnet contract was deployed

    function resetMultipliers() public onlyOwner {
        delete multiplierFrmIds;
        delete multiplierAmountsHundreths;
    }

    function addMultiplier(uint256 _frmId, uint256 _multiplierAmountHundreths) public onlyOwner {
        multiplierFrmIds.push(_frmId);
        multiplierAmountsHundreths.push(_multiplierAmountHundreths);
    }

    function setVizmeshSmartContractAddress(address _vizmeshSmartContractAddress) public onlyOwner {
        vizmeshSmartContractAddress = _vizmeshSmartContractAddress;
    }

    function getMultiplier(uint256 _frmId) public view returns(uint256) {
        uint256 multiplier = distributionRate * converter;
        for(uint256 i=0;i<multiplierFrmIds.length;i++ ) {
            if(_frmId <= multiplierFrmIds[i]) {
                multiplier += multiplierAmountsHundreths[i] * converter;
            }
        }
        return multiplier;
    }

    function getClaimable(uint256 frmId) public view returns(uint256){
        uint256 lastClaimTimestamp = lastClaimTimestamps[frmId];
        if(lastClaimTimestamp == 0) {
            lastClaimTimestamp = startBlockTimestamp;
        }
        uint256 elapsed = block.timestamp - lastClaimTimestamp;
        if (elapsed < 0) {return 0;}
        uint256 multiplier = getMultiplier(frmId);
        return multiplier * elapsed / uint256(86400); //This returns an integer
    }

    function claimTokens(uint256 frmId) public {
        require(isOwnerOfFrm(frmId), "You must own the FRM to claim DCT.");
        uint256 claimable = getClaimable(frmId);
        lastClaimTimestamps[frmId] = block.timestamp;
        mint(msg.sender, claimable);
    }

    function claimTokens(uint256[] memory frmIds) public {
        require(isOwnerOfFrms(frmIds), "You must own the FRMs to claim DCT.");
        uint256 claimable = 0;
        for(uint256 i=0;i<frmIds.length;i++) {
            claimable += getClaimable(frmIds[i]);
            lastClaimTimestamps[frmIds[i]] = block.timestamp;
        }
        mint(msg.sender, claimable);
    }

    constructor() ERC20("DecentralizedCurationToken", "DCT") {
        vizmeshSmartContractAddress = 0x67555c802D8E319534c5532f8867625fa1756601;
    }

    function mint(address to, uint256 amount) private {
        _mint(to, amount);
    }

    function isOwnerOfFrms(uint256[] memory _frmIds) 
        public
        view
        returns(bool)
    {
        for(uint256 i = 0; i< _frmIds.length; i++) {
            if(!isOwnerOfFrm(_frmIds[i])) {
                return false;
            }
        }
        return true;
    }

    function isOwnerOfFrm(uint256 _frmId)
        public
        view
        returns(bool)
    {
        return Vizmesh(vizmeshSmartContractAddress).balanceOf(msg.sender, _frmId) == 1;
    }
}
