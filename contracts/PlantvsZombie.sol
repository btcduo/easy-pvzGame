// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PlantvsZombie is Ownable, ERC721 {

    error HasMinted();
    error NotInitial();

    struct Plant {
        string name;
        uint8 damage;
        uint8 range;
        uint8 hp;
        PlantType plantType;
        uint16 costSun;
        uint32 frequence;
        uint32 coolDownTime;
    }
    struct Zombie {
        string name;
        uint8 damage;
        uint8 hp;
        uint32 speed;
        uint32 frequence;
    }
    Plant[] public plants;
    Zombie[] public zombies;

    enum PlantType{Soldier, Producer, Trapmaker, Defender}

    mapping(address => bool) public hasMinted;
    mapping(uint256 => uint256) public tokenIdToPlantId;
    uint256 public nextTokenId = 0;

    constructor() ERC721("PlantvsZombie", "PVZ") Ownable(msg.sender) {}

    bool internal initialized = false;

    function initPlant() external onlyOwner {
        plants.push(Plant("SunFlower", 0, 0, 5, PlantType.Producer, 50, 5, 10));
        plants.push(Plant("PeaShooter", 1, 9, 5, PlantType.Soldier, 100, 1, 15));
        initialized = true;
    }

    function initZombie() external {
        zombies.push(Zombie("Basic", 1, 10, 50, 1));
        zombies.push(Zombie("ConeHead",1, 20, 50, 1));
    }

    function mintPlant() external {
        if(hasMinted[msg.sender]) revert HasMinted();
        if(!initialized) revert NotInitial();
        for (uint256 i = 0; i < 2; i++) {
            uint256 tokenId = nextTokenId++;
            _safeMint(msg.sender, tokenId);
            tokenIdToPlantId[tokenId] = i;
        }
        hasMinted[msg.sender] = true;
    }
}