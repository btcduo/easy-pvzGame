//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "./Battle.sol";

contract BattleHelper is Battle {

    error PlantDead();
    error InvalidZombie();

    function getBattleSession(address player) public view returns (
        GameState state,
        Winner winner,
        uint16 sunBalance, 
        uint32 startTime, 
        uint32 lastDropTime) {
        BattleSession storage ss = battles[player];
        return (ss.state, ss.winner, ss.sunBalance, ss.startTime, ss.lastDropTime);
    }

    function getState(address player) public view returns (GameState) {
        return battles[player].state;
    }

    function getWinner(address player) public view returns (Winner) {
        return battles[player].winner;
    }

    function getTimePassed(address player) public view returns(uint32) {
        BattleSession storage session = battles[player];
        uint32 elapsed = session.gameTime - session.startTime;
        return elapsed;
    }

    function getSunBalance(address player) public view returns (uint16) {
        return battles[player].sunBalance;
    }

    function getDeployedPlant(uint8 row, uint8 col) public view returns (uint8 hp, PlantType plantType, uint256 plantId) {
        if(row >= grid_row || col >= grid_col) revert OutOfBounds();
        DeployedPlant storage plant = plantsGrid[row][col];
        if(plant.hp == 0) revert PlantDead();
        return (plant.hp, plant.plantType, plant.plantId);
    }

    function getDeployedZombie(uint8 row, uint8 index) public view returns (uint8 hp, uint8 position, uint256 zombieId) {
        if(row >= grid_row) revert OutOfRow();
        if(index >= zombiesPerRow[row].length) revert InvalidZombie();
        DeployedZombie storage zombie = zombiesPerRow[row][index];
        return (zombie.hp, zombie.position, zombie.zombieId);
    }

    function getPlantInfo(uint256 plantId) public view returns (
        string memory name,
        PlantType plantType,
        uint8 damage,
        uint8 range,
        uint8 hp,
        uint16 costSun,
        uint32 frequence,
        uint32 coolDownTime
        ) {
            Plant storage pp = plants[plantId];
            return (pp.name, pp.plantType, pp.damage, pp.range, pp.hp, pp.costSun, pp.frequence, pp.coolDownTime);
    }

    function getZombieInfo(uint256 zombieId) public view returns (
        string memory name,
        uint8 damage,
        uint8 hp,
        uint32 speed,
        uint32 frequence
        ) {
        Zombie storage zz = zombies[zombieId];
        return (zz.name, zz.damage, zz.hp, zz.speed, zz.frequence);
    }
}