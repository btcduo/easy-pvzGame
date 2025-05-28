const { expect } = require("chai");

describe("PVZ", function() {
    let battle, owner, addr1;

    this.beforeEach(async function() {
        const Battle = await ethers.getContractFactory("BattleHelper");
        [owner, addr1] = await ethers.getSigners();
        battle = await Battle.deploy();
        await battle.waitForDeployment();
        await battle.initPlant();
        await battle.initZombie();
        await battle.startBattle();
    })

    async function increaseTime(times) {
        for(let i = 0; i < times; i++) {
            const block = await ethers.provider.getBlock("latest");
            const nextTime = block.timestamp + 1;
            await network.provider.send("evm_setNextBlockTimestamp", [nextTime]);
            await network.provider.send("evm_mine");
        }
    }
    
    async function sunBalance() {
        const tx = await battle.battles(owner.address);
        console.log(`sunBalance[${tx.sunBalance}]`);
    }

    async function placePlant({col,id}) {
        for(let row = 0; row < 5; row++) {
            await battle.placePlant(row, col, id);
        }
    }

    async function spawnZombie(id) {
        for(let row = 0; row < 5; row++) {
            await battle.spawnZombie(row,id);
        }
    }
    
    async function tick(times) {
        for(let i = 0; i < times; i++) {
            await battle.tick({gasLimit:10_000_000});
        }
    }

    async function getPlantInfo(col) {
        console.log(`plantcol[${col}]:`);
        for(let row = 0; row < 5; row++) {
            try {
                const tx = await battle.getPlant(row, col);
                if(tx.hp > 0) {
                    console.log(tx);
                }
            } catch (e) {

            }
        }
    }

    async function getZombieInfo(amount) {
        console.log(`zombies`);
        for(let row = 0; row < 5; row++) {
            for(let col = 0;col < amount; col++) {
                try {
                    const tx = await battle.getZombie(row,col)
                    if(tx.hp > 0) {
                        console.log(tx);
                    }
                } catch (e){

                }
            }
        }
    }


    it("autoBattle", async () => {
        await battle.placePlant(1,1,1);
        await battle.spawnZombie(2,1);
        await battle.placePlant(2,2,1);

        await tick(7);
        await tick(10);
        await tick(9);
        await expect(battle.tick()).to.emit(battle, "BattleEnded").withArgs(2,2);

        await getPlantInfo(1);
        await getZombieInfo(2);
        await sunBalance();
    })
})