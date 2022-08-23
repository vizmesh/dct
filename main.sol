// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Vizmesh {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract DecentralizedCurationToken is ERC20, ERC20Burnable, Ownable {
    uint256 supplyCap = 21000000;
    uint256 supplyMinted = 0;
    address public vizmeshSmartContractAddress;
    mapping(uint256 => uint256) public lastClaimTimestamps;
    
    uint256[] multiplierFrmIds;
    uint256[] multiplierAmounts;
    uint256 distributionRate = 1;
    uint256 startBlockTimestamp = 1000000;

    function resetMultipliers() public onlyOwner {
        delete multiplierFrmIds;
        delete multiplierAmounts;
    }

    function addMultiplier(uint256 _frmId, uint256 _multiplierAmount) public onlyOwner {
        multiplierFrmIds.push(_frmId);
        multiplierAmounts.push(_multiplierAmount);
    }

    function setVizmeshSmartContractAddress(address _vizmeshSmartContractAddress) public onlyOwner {
        vizmeshSmartContractAddress = _vizmeshSmartContractAddress;
    }

    function getMultiplier(uint256 _frmId) public view returns(uint256) {
        uint256 multiplier = 0;
        for(uint256 i=0;i<multiplierFrmIds.length;i++ ) {
            if(_frmId <= multiplierFrmIds[i]) {
                multiplier += multiplierAmounts[i];
            }
        }
        return multiplier;
    }

    function getClaimable(uint256 frmId) private returns(uint256){
        if(lastClaimTimestamps[frmId] == 0) {
            lastClaimTimestamps[frmId] = startBlockTimestamp;
        }
        uint256 elapsed = block.timestamp - lastClaimTimestamps[frmId];
        if (elapsed < 0) {return 0;}
        return elapsed / uint256(86400); //This returns an integer
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
        vizmeshSmartContractAddress = 0xb7FDe9c440793E5a45e0b3C0B373870Ab79Df477;
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
