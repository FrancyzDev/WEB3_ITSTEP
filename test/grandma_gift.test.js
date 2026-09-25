const { loadFixture, time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GrandmaGift", () => {
    const deploy = async () => {
        const [user1, user2, user3, user4] = await ethers.getSigners();

        const factory = await ethers.getContractFactory("GrandmaGift");
        const c_gift = await factory.connect(user3).deploy();
        await c_gift.waitForDeployment();

        return { c_gift, user1, user2, user3, user4 };
    }

    it("grandma can deploy, deposit and add grandchildren", async () => {
        const { c_gift, user1, user2, user3 } = await loadFixture(deploy);

        console.log("Contract address: ", await c_gift.getAddress());

        const contract_address = await c_gift.getAddress();
        expect(contract_address, "Contract address isn't correct").to.be.properAddress;

        const grandma = await c_gift.grandma();
        expect(grandma, "Grandma must be user3").to.be.eq(user3.address);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const day = 24 * 60 * 60;
        const birthday1 = current_block.timestamp + day;
        const birthday2 = current_block.timestamp + 2 * day;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday1);
        await c_gift.connect(user3).add_grandchild(user2.address, birthday2);

        const grandchild1 = await c_gift.grandchildren(user1.address);
        const grandchild2 = await c_gift.grandchildren(user2.address);

        console.log("grandchild1: ", grandchild1);
        console.log("grandchild2: ", grandchild2);

        expect(grandchild1.registered, "Expected registered and result same").to.be.eq(true);
        expect(grandchild1.claimed, "Expected claimed and result same").to.be.eq(false);
        expect(grandchild1.birthday, "Expected birthday and result same").to.be.eq(birthday1);
        expect(grandchild2.birthday, "Expected birthday and result same").to.be.eq(birthday2);

        const count = await c_gift.count();
        expect(count, "Count of grandchildren must be: 2").to.be.eq(2);

        const deposit_value = ethers.parseUnits("2", "ether");

        await expect(() => c_gift.connect(user3).deposit({ value: deposit_value })).to.changeEtherBalance(user3, -deposit_value);
        console.log("User3 balance: ", await ethers.provider.getBalance(user3.address));

        const contract_balance = await ethers.provider.getBalance(contract_address);
        expect(contract_balance, "Contract balance must be equal to deposit").to.be.eq(deposit_value);

        const deposited = await c_gift.deposited();
        expect(deposited, "Deposited must be true").to.be.eq(true);
    })

    it("gift is divided correctly", async () => {
        const { c_gift, user1, user2, user3, user4 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const birthday = current_block.timestamp;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);
        await c_gift.connect(user3).add_grandchild(user2.address, birthday);
        await c_gift.connect(user3).add_grandchild(user4.address, birthday);

        const deposit_value = ethers.parseUnits("3", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        const count = await c_gift.count();
        const gift = await c_gift.gift();
        console.log("Gift: ", gift);

        expect(gift, "Gift must be deposit / count").to.be.eq(deposit_value / count);
        expect(gift, "Gift must be: 1 ETH").to.be.eq(ethers.parseUnits("1", "ether"));
    })

    it("claim on birthday", async () => {
        const { c_gift, user1, user2, user3 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const day = 24 * 60 * 60;
        const birthday = current_block.timestamp + day;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);
        await c_gift.connect(user3).add_grandchild(user2.address, birthday);

        const deposit_value = ethers.parseUnits("2", "ether");
        const gift_value = ethers.parseUnits("1", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        await time.setNextBlockTimestamp(birthday);

        await expect(() => c_gift.connect(user1).claim()).to.changeEtherBalance(user1, gift_value);
        console.log("User1 balance: ", await ethers.provider.getBalance(user1.address));

        const claim_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        expect(claim_block.timestamp, "Claim must be on birthday").to.be.eq(birthday);

        const grandchild1 = await c_gift.grandchildren(user1.address);
        expect(grandchild1.claimed, "Expected claimed and result same").to.be.eq(true);
    })

    it("claim after birthday", async () => {
        const { c_gift, user1, user2, user3 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const day = 24 * 60 * 60;
        const birthday = current_block.timestamp - 10 * day;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);
        await c_gift.connect(user3).add_grandchild(user2.address, birthday);

        const deposit_value = ethers.parseUnits("2", "ether");
        const gift_value = ethers.parseUnits("1", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        await expect(() => c_gift.connect(user1).claim()).to.changeEtherBalance(user1, gift_value);

        await expect(() => c_gift.connect(user2).claim()).to.changeEtherBalance(c_gift, -gift_value);

        const contract_balance = await ethers.provider.getBalance(await c_gift.getAddress());
        expect(contract_balance, "Contract balance must be 0 after all claims").to.be.eq(0);
    })

    it("claim before birthday", async () => {
        const { c_gift, user1, user3 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const day = 24 * 60 * 60;
        const birthday = current_block.timestamp + day;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);

        const deposit_value = ethers.parseUnits("1", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        const reverted_message = "birthday has not come yet";

        await expect(c_gift.connect(user1).claim()).to.revertedWith(reverted_message);
    })

    it("second claim", async () => {
        const { c_gift, user1, user3 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const birthday = current_block.timestamp;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);

        const deposit_value = ethers.parseUnits("1", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        await c_gift.connect(user1).claim();

        const reverted_message = "already claimed";

        await expect(c_gift.connect(user1).claim()).to.revertedWith(reverted_message);
    })

    it("stranger call", async () => {
        const { c_gift, user1, user3, user4 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const birthday = current_block.timestamp;

        const deposit_value = ethers.parseUnits("1", "ether");
        const reverted_message = "only grandma";

        await expect(c_gift.connect(user4).add_grandchild(user4.address, birthday)).to.revertedWith(reverted_message);

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);

        await expect(c_gift.connect(user4).deposit({ value: deposit_value })).to.revertedWith(reverted_message);

        await c_gift.connect(user3).deposit({ value: deposit_value });

        const not_grandchild_message = "not a grandchild";

        await expect(c_gift.connect(user4).claim()).to.revertedWith(not_grandchild_message);
    })

    it("claim event", async () => {
        const { c_gift, user1, user3 } = await loadFixture(deploy);

        const current_block = await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber()
        );
        const birthday = current_block.timestamp;

        await c_gift.connect(user3).add_grandchild(user1.address, birthday);

        const deposit_value = ethers.parseUnits("1", "ether");

        await c_gift.connect(user3).deposit({ value: deposit_value });

        const event_name = "Claimed";

        const tx = await c_gift.connect(user1).claim();

        await expect(tx).to.emit(c_gift, event_name).withArgs(user1.address, deposit_value)
    })
})
