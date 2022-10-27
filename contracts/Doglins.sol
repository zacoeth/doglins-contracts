// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./lib/Administration.sol";
import "./lib/IENERGY.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Doglins is ERC721, Administration { 

    uint public price = 1 ether;
    uint public maxSupply = 5000;
    uint public maxFree = 2000;
    uint public freeCount = 0;
    uint public maxTx = 20;
    uint public totalSupply = 0;

    uint public cooldownTime = 0;

    uint public rerollPrice = 210 ether;
    uint public halfEnergyPrice = 30 ether;
    uint public lowEnergyPrice = 40 ether;
    uint public noEnergyPrice = 50 ether;

    uint public halfEnergyTime = 30 hours;
    uint public lowEnergyTime = 40 hours;
    uint public noEnergyTime = 50 hours;

    uint public maxTraits = 3;

    bool public mintOpen = false;
    bool public presaleOpen = true;

    address public energyAddress;

    address private _signer;

    mapping(address => uint) public free;
    mapping(uint => bool) public stakedToken;
    mapping(uint => mapping(uint => address)) public dna;
    mapping(uint => uint) public rerollCooldown;
    mapping(uint => uint) public energyTime;

    string internal baseTokenURI;

    modifier onlyOwnerOf(uint tokenId){
        require(ownerOf(tokenId) == _msgSender(), "Ownership: caller is not the owner");
        _;
    }

    modifier isTrait(uint traitId){
        require(traitId < maxTraits, "Trait not found");
        _;
    }
    
    constructor(address signer_, string memory tokenURI_) ERC721("Doglins", "DGLNS") {
        setSigner(signer_);
        setBaseTokenURI(tokenURI_);
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty, false);
    }

    function mintPresale(uint qty, bytes calldata signature_, bool stake_) external payable {
        require(presaleOpen, "closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        require(balanceOf(_msgSender()) + qty <= maxTx, "You can't buy more");
        _buy(qty, stake_);
    }
    
    function mint(uint qty, bool stake_) external payable {
        require(mintOpen, "closed");
        _buy(qty, stake_);
    }

    function _buy(uint qty, bool stake_) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        uint free_ = free[_msgSender()] == 0 && freeCount < maxFree ? 1 : 0;
        require(msg.value >= price * (qty - free_), "PAYMENT: invalid value");
        if(free[_msgSender()] == 0){
            freeCount++;
            free[_msgSender()] = 1;
        }
        _mintTo(_msgSender(), qty, stake_);
    }

    function _mintTo(address to, uint qty, bool stake_) internal {
        require(qty + totalSupply <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            totalSupply++;
            _mint(to, totalSupply);
            if(stake_){
                stake(totalSupply);
            }
        }
    }

    function tokensByOwner(address addr) external view returns (uint256[] memory)
    {
        uint256 count;
        uint256 walletBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](walletBalance);

        uint256 i;
        for (; i < maxSupply; ) {
            // early break if all tokens found
            if (count == walletBalance) {
                return tokens;
            }

            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }

            ++i;
        }
        return tokens;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(stakedToken[tokenId]){
            revert("ERROR: this NFT is staked. Unstake it before transfer.");
        }
        if (from != address(0)) {
            IENERGY(energyAddress).stopDripping(from, 1);
        }

        if (to != address(0)) {
            IENERGY(energyAddress).startDripping(to, 1);
        }

        super._beforeTokenTransfer(from, to, tokenId);      
    }

    function stakeBatch(uint[] calldata tokenIds) public {
        for(uint i=0; i < tokenIds.length; i++){
            stake(tokenIds[i]);
        }
    }

    function unstakeBatch(uint[] calldata tokenIds) public {
        for(uint i=0; i < tokenIds.length; i++){
            unstake(tokenIds[i]);
        }
    }

    function stake(uint tokenId) public onlyOwnerOf(tokenId){
        if(!stakedToken[tokenId]){
            stakedToken[tokenId] = true;
        }
    }

    function unstake(uint tokenId) public onlyOwnerOf(tokenId){
        if(stakedToken[tokenId]){
            stakedToken[tokenId] = false;
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }

    function setMaxFree(uint free_) public onlyOwner {
        maxFree = free_;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string memory uri_) public onlyOwner {
        baseTokenURI = uri_;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setEnergyAddress(address newAddress) external onlyOwner {
        energyAddress = newAddress;
    }

    function setCooldownTime(uint newTime) external onlyOwner {
        cooldownTime = newTime;
    }

    function setRerollPrice(uint newPrice) external onlyOwner {
        rerollPrice = newPrice;
    }

    function setHalfEnergyTime(uint new_) external onlyOwner {
        halfEnergyTime = new_;
    }

    function setLowEnergyTime(uint new_) external onlyOwner {
        lowEnergyTime = new_;
    }

    function setNoEnergyTime(uint new_) external onlyOwner {
        noEnergyTime = new_;
    }

    function setHalfEnergyPrice(uint new_) external onlyOwner {
        halfEnergyPrice = new_;
    }

    function setLowEnergyPrice(uint new_) external onlyOwner {
        lowEnergyPrice = new_;
    }

    function setNoEnergyPrice(uint new_) external onlyOwner {
        noEnergyPrice = new_;
    }

    // services functions

    // low number = more energy;
    function getEnergyTime(uint tokenId) public view returns (uint) {
        if(stakedToken[tokenId]){
            return 0;
        }
        return  block.timestamp - energyTime[tokenId];
    }

    function restoreEnergy(uint tokenId) external onlyOwnerOf(tokenId){
        uint tokenEnergy = getEnergyTime(tokenId);
        if(tokenEnergy < halfEnergyTime){
            return;
        }
        uint price_ = tokenEnergy >= noEnergyTime ? noEnergyPrice : tokenEnergy >= lowEnergyTime ? lowEnergyTime : halfEnergyPrice;
        IENERGY(energyAddress).burn(_msgSender(), price_);
        energyTime[tokenId] = block.timestamp;
    }

    function rerollTrait(uint tokenId, uint traitId) external onlyOwnerOf(tokenId) isTrait(traitId) {
        if(cooldownTime == 0 || rerollCooldown[tokenId] == 0){
            return _rerollTrait(tokenId, traitId);
        }
        uint time = block.timestamp - rerollCooldown[tokenId];
        require(time >= cooldownTime, "Cooldown error");
        rerollCooldown[tokenId] = block.timestamp;
        _rerollTrait(tokenId, traitId);
    }

    function _rerollTrait(uint tokenId, uint traitId) internal {
        IENERGY(energyAddress).burn(_msgSender(), rerollPrice);
        address addr = address(uint160(uint(keccak256(abi.encodePacked(
                        block.coinbase,
                        block.timestamp,
                        tokenId
                    )))));
        dna[tokenId][traitId] = addr;
    }

    function getAllTraits(uint tokenId) public view returns(address[] memory) {
        address[] memory traits = new address[](maxTraits);
        for(uint i; i < maxTraits; i++){
            traits[i] = dna[tokenId][i];
        }
        return traits;
    }
    
}
