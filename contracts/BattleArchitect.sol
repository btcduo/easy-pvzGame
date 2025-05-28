// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "./PlantvsZombie.sol";
import "hardhat/console.sol";

contract BattleArchitect is PlantvsZombie {

    error GameNotActiveAndHasWinner();
    error GameNotOverAndNoWinner();
    error NotBattlePlayer();
    error OutOfBounds();
    error OutOfRow();
    error HasZombies();
    error InvalidZombieId();

    event TickLog(address indexed player, uint32 gameTime, string[] actions);

    uint256 public grid_row = 5;
    uint256 public grid_col = 9;

    struct BattleSession {
        address player;
        GameState state;
        Winner winner;
        uint16 sunBalance;
        uint32 sunDropTimes;
        uint32 startTime;
        uint32 gameTime;
        uint32 lastDropTime;
    }
    struct DeployedPlant {
        uint8 hp;
        uint8 damage;
        uint8 range;
        PlantType plantType;
        uint32 frequence;
        uint32 coolDownTime;
        uint32 lastPlantTime;
        uint32 lastActionTime;
        uint256 plantId;
    }
    struct DeployedZombie {
        uint8 hp;
        uint8 damage;
        uint8 position;
        uint32 speed;
        uint32 progress;
        uint32 frequence;
        uint32 lastAttackTime;
        uint32 lastMoveTime;
        uint256 zombieId;
    }
    enum GameState{Waiting, Active, GameOver}
    enum Winner{None, Plant, Zombie}

    mapping(address => BattleSession) public battles;
    mapping(uint256 => mapping(uint256 => DeployedPlant)) public plantsGrid;
    mapping(uint256 => DeployedZombie[]) public zombiesPerRow;

    modifier inBattle {
        BattleSession storage session = battles[msg.sender];
        if(session.state != GameState.Active && session.winner != Winner.None) revert GameNotActiveAndHasWinner();
        _;
    }

    modifier onlyGameOver {
        BattleSession storage session = battles[msg.sender];
        if(session.state != GameState.GameOver && session.winner == Winner.None) revert GameNotOverAndNoWinner();
        _;
    }

    modifier onlyBattleOwner {
        if(battles[msg.sender].player != msg.sender) revert NotBattlePlayer();
        _;
    }

    function _safeDmg(uint8 hp, uint8 dmg) internal pure returns (uint8) {
        return dmg >= hp ? 0 : hp - dmg;
    }

    function _dropSun() internal inBattle returns(bool) {
        bool didDrop = false;
        BattleSession storage session = battles[msg.sender];
        uint32 elapsed = session.gameTime - session.lastDropTime;
        if(elapsed < 10) {
            return false;
        }
        session.sunBalance += 25;
        session.sunDropTimes++;
        session.lastDropTime = session.gameTime;
        return didDrop = true;
    }

    function _spawnZombie(uint8 row, uint256 zombieId) internal inBattle {
        if(row >= grid_row) revert OutOfRow();
        if(zombiesPerRow[row].length > 0) revert HasZombies();
        if(zombieId >= zombies.length) revert InvalidZombieId();

        BattleSession storage session = battles[msg.sender];

        Zombie memory zombie = zombies[zombieId];
        zombiesPerRow[row].push(DeployedZombie({
            zombieId: zombieId,
            hp: zombie.hp,
            damage: zombie.damage,
            position: uint8(grid_col - 1),
            speed: zombie.speed,
            progress: 0,
            frequence: zombie.frequence,
            lastAttackTime: session.gameTime,
            lastMoveTime: session.gameTime
        }));
    }

    function _advanceGameTime() internal inBattle {
        string[5] memory logs;
        string[] memory output = new string[](5);
        for(uint256 i = 0; i < 5; i++) {
            output[i] = logs[i];
        }
        uint256 index = 0;
        if(_dropSun()) {
            logs[index++] = "dropSun";
        }
        if(_handleplantProduce()) {
            logs[index++] = "plantProduce";
        }
        if(_handlePlantAttack()) {
            logs[index++] = "plantAttack";
        }
        if(_handleZombieMove()) {
            logs[index++] = "zombieMove";
        }
        if(_handleZombieAttack()) {
            logs[index++] = "zombieAttack";
        }
        _gameWinnerVerdict();
        emit TickLog(msg.sender, battles[msg.sender].gameTime, output);
    }

    function _handleplantProduce() internal inBattle returns(bool) {
        bool didplantProduce = false;
        BattleSession storage session = battles[msg.sender];
        for(uint256 row = 0; row < grid_row; row++) {
            for(uint256 col = 0; col < grid_col; col++) {
                DeployedPlant storage plant = plantsGrid[row][col];
                if(plant.plantType != PlantType.Producer || plant.hp == 0 || session.gameTime < plant.lastActionTime + plant.frequence) {
                    continue;
                }
                session.sunBalance += 25;
                plant.lastActionTime = session.gameTime;
                didplantProduce = true;
            }
        }
        return didplantProduce;
    }

    function _handlePlantAttack() internal inBattle returns(bool) {
        bool zombieAttacked = false;
        BattleSession storage session = battles[msg.sender];
        for(uint256 row = 0; row < grid_row; row++) {
            for(uint256 col = 0; col < grid_col; col++) {
                DeployedPlant storage plant = plantsGrid[row][col];
                if(plant.hp == 0 || plant.plantType != PlantType.Soldier) {
                    continue;
                }
                DeployedZombie[] storage zombies = zombiesPerRow[row];
                if(zombies.length == 0) {
                    continue;
                }
                for(uint256 z = 0; z < zombies.length; z++) {
                    DeployedZombie storage zombie = zombies[z];
                    if(zombie.hp == 0 || zombie.position < col) {
                        continue;
                    }
                    uint256 distance = uint256(zombie.position) - col;
                    if(distance > plant.range || session.gameTime < plant.lastActionTime + plant.frequence) {
                        continue;
                    }
                    zombie.hp = _safeDmg(zombie.hp, plant.damage);
                    plant.lastActionTime = session.gameTime;
                    zombieAttacked = true;
                    if(zombie.hp == 0) {
                        _delDeadZombie(row, z);
                    }
                    break;
                }
            }
        }
        return zombieAttacked;
    }

    function _delDeadZombie(uint256 row, uint256 index) internal inBattle {
        DeployedZombie[] storage zombies = zombiesPerRow[row];
        zombies[index] = zombies[zombies.length - 1];
        zombies.pop();
    }

    function _handleZombieMove() internal inBattle returns(bool) {
        bool zombieMoved = false;
        BattleSession storage session = battles[msg.sender];
        for(uint256 row = 0; row < grid_row; row++) {
            DeployedZombie[] storage zombies = zombiesPerRow[row];
            if(zombies.length == 0) {
                continue;
            }
            for(uint256 z = 0; z < zombies.length; z++) {
                DeployedZombie storage zombie = zombies[z];
                if(zombie.hp == 0 || zombie.position >= grid_col || zombie.position == 0) {
                    continue;
                }
                DeployedPlant storage plant = plantsGrid[row][zombie.position];
                if(plant.hp > 0 || session.gameTime < zombie.lastMoveTime + zombie.frequence) {
                    continue;
                }
                zombie.progress += zombie.speed;
                zombieMoved = true;
                uint8 steps = 0;
                while(zombie.progress >= 100 && steps < 10) {
                    if(zombie.position == 0) {
                        break;
                    }
                    zombie.position -= 1;
                    zombie.progress -= 100;
                    steps++;
                }
                zombie.lastMoveTime = session.gameTime;
            }
        }
        return zombieMoved;
    }

    function _handleZombieAttack() internal inBattle returns(bool) {
        bool zombieAttacked = false;
        BattleSession storage session = battles[msg.sender];
        for(uint256 row = 0; row < grid_row; row++) {
            DeployedZombie[] storage zombies = zombiesPerRow[row];
            if(zombies.length == 0) {
                continue;
            }
            for(uint256 z = 0; z < zombies.length; z++) {
                DeployedZombie storage zombie = zombies[z];
                if(zombie.hp == 0 || zombie.position == 0 || zombie.position >= grid_col) {
                    continue;
                }
                DeployedPlant storage plant = plantsGrid[row][zombie.position];
                if(plant.hp == 0 || session.gameTime < zombie.lastAttackTime + zombie.frequence) {
                    continue;
                }
                plant.hp = _safeDmg(plant.hp, zombie.damage);
                zombie.lastAttackTime = session.gameTime;
                zombieAttacked = true;
                if(plant.hp == 0) {
                    delete plantsGrid[row][zombie.position];
                    break;
                }
            }
        }
        return zombieAttacked;
    }

    function _gameWinnerVerdict() internal inBattle {
        BattleSession storage session = battles[msg.sender];
        if(session.gameTime - session.startTime < 30) {
            return;
        }
        bool zombieExits = false;

        for(uint256 row = 0; row < grid_row; row++) {
            DeployedZombie[] storage zombies = zombiesPerRow[row];
            if(zombies.length == 0) {
                continue;
            }
            zombieExits = true;

            for(uint256 z = 0; z < zombies.length; z++) {
                DeployedZombie storage zombie = zombies[z];
                if(zombie.hp > 0 && zombie.position == 0) {
                    session.state = GameState.GameOver;
                    session.winner = Winner.Zombie;
                    return;
                }
            }
        }
        if(!zombieExits) {
            return;
        }

        for(uint256 row = 0; row < grid_row; row++) {
            DeployedZombie[] storage zombies = zombiesPerRow[row];
            if(zombies.length == 0) {
                continue;
            }
            for(uint256 z = 0; z < zombies.length; z++) {
                DeployedZombie storage zombie = zombies[z];
                if(zombie.hp > 0 && zombie.position > 0) {
                    return;
                }
            }
        }
        session.state = GameState.GameOver;
        session.winner = Winner.Plant;
    }

    function _resetBattle() internal onlyGameOver {
        BattleSession storage session = battles[msg.sender];
        for (uint256 row = 0; row < grid_row; row++) {
            delete zombiesPerRow[row];
            for (uint256 col = 0; col < grid_col; col++) {
                delete plantsGrid[row][col];
            }
        }

        session.state = GameState.Waiting;
        session.winner = Winner.None;
        session.sunBalance = 0;
        session.startTime = 0;
        session.gameTime = 0;
        session.lastDropTime = 0;

    }

}