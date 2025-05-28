//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "./BattleArchitect.sol";

contract Battle is BattleArchitect {

    error BattleAreWaitingOrHasWinner();
    error NotTheDefaultPlayer();
    error InvalidPlantId();
    error HasPlant();
    error PlantCoolDownNotReady();
    error InsufficientSunBalance();
    error GameTimeNotUpdate();

    function startBattle() external {
        BattleSession storage session = battles[msg.sender];
        if(session.state != GameState.Waiting && session.winner != Winner.None) revert BattleAreWaitingOrHasWinner();
        if(session.player != address(0)) revert NotTheDefaultPlayer();

        for (uint256 row = 0; row < grid_row; row++) {
            DeployedZombie[] storage zombies = zombiesPerRow[row];
            if (zombies.length == 0) {
                continue;
            }
            delete zombiesPerRow[row];

            for (uint8 col = 0; col < grid_col; col++) {
                DeployedPlant storage plant = plantsGrid[row][col];
                if (plant.hp == 0) {
                    continue;
                }
                delete plantsGrid[row][col];
            }
        }

        session.player = msg.sender;
        session.state = GameState.Active;
        session.sunBalance = 50;
        session.sunDropTimes = 0;
        session.startTime = uint32(block.timestamp);
        session.gameTime = session.startTime;
        session.lastDropTime = session.startTime;

    }

    function dropSun() external inBattle {
        _dropSun();
    }

    function placePlant(uint8 row, uint8 col, uint256 plantId) external inBattle {
        if(row >= grid_row || col >= grid_col) revert OutOfBounds();
        if(plantId >= plants.length) revert InvalidPlantId();
        if(plantsGrid[row][col].hp > 0) revert HasPlant();
        BattleSession storage session = battles[msg.sender];
        Plant memory plant = plants[plantId];

        bool isInitialGrace = (session.gameTime - session.startTime <= 10);
        bool readyToDeployPlant = (session.gameTime >= plantsGrid[row][col].lastPlantTime + plant.coolDownTime);
        if(!isInitialGrace && !readyToDeployPlant) revert PlantCoolDownNotReady();
        if(session.sunBalance < plant.costSun) revert InsufficientSunBalance();
        session.sunBalance -= plant.costSun;
        
        plantsGrid[row][col] = DeployedPlant({
            plantId: plantId,
            plantType: plant.plantType,
            range: plant.range,
            damage: plant.damage,
            hp: plant.hp,
            frequence: plant.frequence,
            coolDownTime: plant.coolDownTime,
            lastPlantTime: session.gameTime,
            lastActionTime: session.gameTime
        });
    }

    function spawnZombie(uint8 row, uint256 zombieId) external inBattle {
        _spawnZombie(row, zombieId);
    }

    function tick() external inBattle {
        BattleSession storage session = battles[msg.sender];
        uint32 currentTime = uint32(block.timestamp);
        if(currentTime <= session.gameTime) revert GameTimeNotUpdate();
        session.gameTime = currentTime;
        _advanceGameTime();
    }

    function resetBattle() external onlyGameOver {
        _resetBattle();
    }

}