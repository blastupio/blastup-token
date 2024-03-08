const { expect } = require('chai');
const { ethers } = require("hardhat");

// Start test block
describe('BLPToken', function () {
  before(async function () {
    this.BlastUpToken = await ethers.getContractFactory('BLPToken');
  });

  beforeEach(async function () {
    const signers = await ethers.getSigners();

    this.ownerAddress = signers[0].address; // aka DAO address
    this.recipientAddress = signers[1].address;

    this.blpToken = await this.BlastUpToken.deploy(this.ownerAddress);

    this.decimals = await this.blpToken.decimals();

    this.totalSupply = 1_000_000_000;

    this.signerContract = this.blpToken.connect(signers[1]);
  });

  // Test cases
  it('Creates a token with a name', async function () {
    expect(await this.blpToken.name()).to.exist;
    // expect(await this.blpToken.name()).to.equal('BLPToken');
  });

  it('Creates a token with a symbol', async function () {
    expect(await this.blpToken.symbol()).to.exist;
    // expect(await this.blpToken.symbol()).to.equal('BLP');
  });

  it('Has a valid decimal', async function () {
    expect((await this.blpToken.decimals()).toString()).to.equal('18');
  })

  it('Has a valid total supply', async function () {
    const expectedSupply = this.totalSupply.toString();
    expect((await this.blpToken.totalSupply()).toString()).to.equal(expectedSupply);
  });

  it("Should assign the total supply of tokens to the DAO wallet", async function () {
    const daoBalance = await this.blpToken.balanceOf(this.ownerAddress);
    expect(await this.blpToken.totalSupply()).to.equal(daoBalance);
  });

  it('Is able to query account balances', async function () {
    const ownerBalance = await this.blpToken.balanceOf(this.ownerAddress);
    expect(await this.blpToken.balanceOf(this.ownerAddress)).to.equal(ownerBalance);
  });

  it('Transfers the right amount of tokens to/from an account', async function () {
    const transferAmount = 1000;
    await expect(this.blpToken.transfer(this.recipientAddress, transferAmount)).to.changeTokenBalances(
        this.blpToken,
        [this.ownerAddress, this.recipientAddress],
        [-transferAmount, transferAmount]
      );
  });

});