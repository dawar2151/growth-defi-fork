require('dotenv').config();
const Web3 = require('web3');
const HDWalletProvider = require('@truffle/hdwallet-provider');

// process

function idle() {
  return new Promise((resolve, reject) => { });
}

function sleep(delay) {
  return new Promise((resolve, reject) => setTimeout(resolve, delay));
}

function abort(e) {
  e = e || new Error('Program aborted');
  console.error(e.stack);
  process.exit(1);
}

function exit() {
  process.exit(0);
}

function entrypoint(main) {
  const args = process.argv;
  (async () => { try { await main(args); } catch (e) { abort(e); } exit(); })();
}

// web3

const network = process.env['NETWORK'] || 'development';

const infuraProjectId = process.env['INFURA_PROJECT_ID'] || '';

const privateKey = process.env['PRIVATE_KEY'];
if (!privateKey) throw new Error('Unknown private key');

const NETWORK_ID = {
  'mainnet': '1',
  'ropsten': '3',
  'rinkeby': '4',
  'kovan': '42',
  'goerli': '5',
  'development': '1',
};

const networkId = NETWORK_ID[network];

const HTTP_PROVIDER_URL = {
  'mainnet': 'https://mainnet.infura.io/v3/' + infuraProjectId,
  'ropsten': 'https://ropsten.infura.io/v3/' + infuraProjectId,
  'rinkeby': 'https://rinkeby.infura.io/v3/' + infuraProjectId,
  'kovan': 'https://kovan.infura.io/v3/' + infuraProjectId,
  'goerli': 'https://goerli.infura.io/v3/' + infuraProjectId,
  'development': 'http://localhost:8545/',
};

const WEBSOCKET_PROVIDER_URL = {
  'mainnet': 'wss://mainnet.infura.io/ws/v3/' + infuraProjectId,
  'ropsten': 'wss://ropsten.infura.io/ws/v3/' + infuraProjectId,
  'rinkeby': 'wss://rinkeby.infura.io/ws/v3/' + infuraProjectId,
  'kovan': 'wss://kovan.infura.io/ws/v3/' + infuraProjectId,
  'goerli': 'wss://goerli.infura.io/ws/v3/' + infuraProjectId,
  'development': 'http://localhost:8545/',
};

const web3 = new Web3(new HDWalletProvider(privateKey, HTTP_PROVIDER_URL[network]));
const web3ws = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER_URL[network]));

function connect() {
  const provider = new Web3.providers.WebsocketProvider(WEBSOCKET_PROVIDER_URL[network]);
  provider.on('error', () => abort(new Error('Connection error')));
  provider.on('end', connect);
  web3ws.setProvider(provider);
}

connect();

function blockSubscribe(f) {
  const subscription = web3ws.eth.subscribe('newBlockHeaders', (e, block) => {
    if (e) return abort(e);
    try {
      const { number } = block;
      f(number);
    } catch (e) {
      abort(e);
    }
  });
  return () => subscription.unsubscribe((e, success) => {
    if (e) return abort(e);
  });
}

function logSubscribe(events, f) {
  const topics = events.map(web3.eth.abi.encodeEventSignature);
  const params = events.map((event) => {
    const result = event.match(/\((.*)\)/);
    if (!result) throw new Error('Invalid event');
    const [, args] = result;
    if (args == '') return [];
    return args.split(',');
  });
  const map = {};
  for (const i in topics) map[topics[i]] = [events[i], params[i]];
  const subscription = web3ws.eth.subscribe('logs', { topics: [topics] }, (e, log) => {
    if (e) return abort(e);
    try {
      const { address, topics: [topic, ...values], data } = log;
      const [event, params] = map[topic];
      for (const i in values) values[i] = String(web3.eth.abi.decodeParameter(params[i], values[i]));
      const missing = params.slice(values.length);
      const result = web3.eth.abi.decodeParameters(missing, data);
      for (const i in missing) values.push(result[i]);
      f(address, event, values);
    } catch (e) {
      abort(e);
    }
  });
  return () => subscription.unsubscribe((e, success) => {
    if (e) return abort(e);
  });
}

function valid(amount, decimals) {
  const regex = new RegExp(`^\\d+${decimals > 0 ? `(\\.\\d{1,${decimals}})?` : ''}$`);
  return regex.test(amount);
}

function coins(units, decimals) {
  if (!valid(units, 0)) throw new Error('Invalid amount');
  if (decimals == 0) return units;
  const s = units.padStart(1 + decimals, '0');
  return s.slice(0, -decimals) + '.' + s.slice(-decimals);
}

function units(coins, decimals) {
  if (!valid(coins, decimals)) throw new Error('Invalid amount');
  let i = coins.indexOf('.');
  if (i < 0) i = coins.length;
  const s = coins.slice(i + 1);
  return coins.slice(0, i) + s + '0'.repeat(decimals - s.length);
}

// main

const [account] = web3.currentProvider.getAddresses();

const ABI_ERC20 = require('../build/contracts/ERC20.json').abi;
const ABI_CTOKEN = require('../build/contracts/CToken.json').abi;
const ABI_GTOKEN = require('../build/contracts/GToken.json').abi;
const ABI_GCTOKEN = require('../build/contracts/GCToken.json').abi;
const ABI_GEXCHANGE = require('../build/contracts/GUniswapV2Exchange.json').abi;

async function getEthBalance(address) {
  const amount = await web3.eth.getBalance(address);
  return coins(amount, 18);
}

async function mint(token, amount, maxCost) {
  const GEXCHANGE_ADDRESS = require('../build/contracts/GUniswapV2Exchange.json').networks[networkId].address;
  const contract = new web3.eth.Contract(ABI_GEXCHANGE, GEXCHANGE_ADDRESS);
  const _amount = units(amount, token.decimals);
  const value = units(maxCost, 18);
  await contract.methods.faucet(token.address, _amount).send({ from: account, value });
}

async function newERC20(address) {
  let self;
  const contract = new web3.eth.Contract(ABI_ERC20, address);
  const [name, symbol, _decimals] = await Promise.all([
    contract.methods.name().call(),
    contract.methods.symbol().call(),
    contract.methods.decimals().call(),
  ]);
  const decimals = Number(_decimals);
  return (self = {
    address,
    name,
    symbol,
    decimals,
    totalSupply: async () => {
      const amount = await contract.methods.totalSupply().call();
      return coins(amount, decimals);
    },
    balanceOf: async (owner) => {
      const amount = await contract.methods.balanceOf(owner).call();
      return coins(amount, decimals);
    },
    allowance: async (owner, spender) => {
      const amount = await contract.methods.allowance(owner, spender).call();
      return coins(amount, decimals);
    },
    approve: async (spender, amount) => {
      const _amount = units(amount, self.decimals);
      return (await contract.methods.approve(spender, _amount).send({ from: account })).status;
    }
  });
}

async function newCToken(address) {
  let self;
  const fields = await newERC20(address);
  const contract = new web3.eth.Contract(ABI_CTOKEN, address);
  return (self = {
    ...fields,
  });
}

async function newGToken(address) {
  let self;
  const fields = await newERC20(address);
  const contract = new web3.eth.Contract(ABI_GTOKEN, address);
  const stakesToken = await newCToken(await contract.methods.stakesToken().call());
  const reserveToken = await newCToken(await contract.methods.reserveToken().call());
  return (self = {
    ...fields,
    stakesToken,
    reserveToken,
    totalReserve: async () => {
      const amount = await contract.methods.totalReserve().call();
      return coins(amount, self.reserveToken.decimals);
    },
    deposit: async (cost) => {
      const _cost = units(cost, self.reserveToken.decimals);
      await contract.methods.deposit(_cost).send({ from: account });
    },
    withdraw: async (grossShares) => {
      const _grossShares = units(grossShares, self.decimals);
      await contract.methods.withdraw(_grossShares).send({ from: account });
    },
    allocateLiquidityPool: async (stakesAmount, sharesAmount) => {
      const _stakesAmount = units(stakesAmount, stakesToken.decimals);
      const _sharesAmount = units(sharesAmount, self.decimals);
      await contract.methods.allocateLiquidityPool(_stakesAmount, _sharesAmount).send({ from: account });
    },
  });
}

async function newGCToken(address) {
  let self;
  const fields = await newGToken(address);
  const contract = new web3.eth.Contract(ABI_GCTOKEN, address);
  const underlyingToken = await newERC20(await contract.methods.underlyingToken().call());
  return (self = {
    ...fields,
    underlyingToken,
    lendingReserveUnderlying: async () => {
      const _amount = await contract.methods.lendingReserveUnderlying().call();
      return coins(_amount, underlyingToken.decimals);
    },
    borrowingReserveUnderlying: async () => {
      const _amount = await contract.methods.borrowingReserveUnderlying().call();
      return coins(_amount, underlyingToken.decimals);
    },
    depositUnderlying: async (cost) => {
      const _cost = units(cost, self.underlyingToken.decimals);
      await contract.methods.depositUnderlying(_cost).send({ from: account });
    },
    withdrawUnderlying: async (grossShares) => {
      const _grossShares = units(grossShares, self.decimals);
      await contract.methods.withdrawUnderlying(_grossShares).send({ from: account });
    },
    setLeverageEnabled: async (enabled) => {
      await contract.methods.setLeverageEnabled(enabled).send({ from: account });
    },
  });
}

function randomInt(limit) {
  return Math.floor(Math.random() * limit)
}

function randomAmount(token, balance) {
  const _balance = units(balance, token.decimals);
  const _amount = randomInt(Number(_balance) + 1);
  return coins(String(_amount), token.decimals);
}

async function main(args) {
  const GTOKEN_ADDRESS = require('../build/contracts/gcDAI.json').networks[networkId].address;
  const gtoken = await newGCToken(GTOKEN_ADDRESS);
  const stoken = gtoken.stakesToken;
  const ctoken = gtoken.reserveToken;
  const utoken = gtoken.underlyingToken;

  blockSubscribe((number) => {
    console.log('block ' + number);
  });

  const events = [
    'Debug(address,string)',
    'Debug(address,string,uint256)',
    'Debug(address,string,address)',
  ];
  logSubscribe(events, (address, event, values) => {
    if (address == gtoken.address) {
      console.log('>>', values.slice(1).join(' '));
    }
  });

  console.log(network);
  console.log(stoken.name, stoken.symbol, stoken.decimals);
  console.log(gtoken.name, gtoken.symbol, gtoken.decimals);
  console.log(ctoken.name, ctoken.symbol, ctoken.decimals);
  console.log('approve', await stoken.approve(gtoken.address, '1000000000'));
  console.log('ctoken allowance', await stoken.allowance(account, gtoken.address));
  console.log('approve', await ctoken.approve(gtoken.address, '1000000000'));
  console.log('ctoken allowance', await ctoken.allowance(account, gtoken.address));
  console.log('approve', await utoken.approve(gtoken.address, '1000000000'));
  console.log('utoken allowance', await utoken.allowance(account, gtoken.address));
  console.log();

  async function printSummary() {
    console.log('total supply', await gtoken.totalSupply());
    console.log('total reserve', await gtoken.totalReserve());
    const lending = await gtoken.lendingReserveUnderlying();
    console.log('total lending', lending);
    const borrowing = await gtoken.borrowingReserveUnderlying();
    console.log('total borrowing', borrowing);
    console.log('collateralization', (100 * Number(borrowing)) / Number(lending));
    console.log('gtoken balance', await gtoken.balanceOf(account));
    console.log('ctoken balance', await ctoken.balanceOf(account));
    console.log('utoken balance', await utoken.balanceOf(account));
    console.log('stoken balance', await stoken.balanceOf(account));
    console.log('eth balance', await getEthBalance(account));
    console.log();
  }

  await printSummary();

  await mint(ctoken, '100', '1');
  await mint(stoken, '1', '1');
  await gtoken.deposit('1');
  try { await gtoken.allocateLiquidityPool(await stoken.balanceOf(account), await gtoken.balanceOf(account)); } catch (e) {}

  const ACTIONS = [
    'leverageOn',
    'leverageOff',
    'deposit',
    'depositAll',
    'withdraw',
    'withdrawAll',
  ];

  const MAX_EXECUTED_ACTIONS = 1000;

  for (let i = 0; i < MAX_EXECUTED_ACTIONS; i++) {

    await printSummary();

    await sleep(5 * 1000);

    const action = ACTIONS[randomInt(ACTIONS.length)];

    if (action == 'leverageOn') {
      console.log('LEVERAGE ON');
      try {
        await gtoken.setLeverageEnabled(true);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

    if (action == 'leverageOff') {
      console.log('LEVERAGE OFF');
      try {
        await gtoken.setLeverageEnabled(false);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

    if (action == 'deposit') {
      const balance = await ctoken.balanceOf(account);
      const amount = randomAmount(ctoken, balance);
      console.log('DEPOSIT', amount);
      try {
        if (Number(amount) > 0) await gtoken.deposit(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

    if (action == 'depositAll') {
      const balance = await ctoken.balanceOf(account);
      const amount = balance;
      console.log('DEPOSIT ALL', amount);
      try {
        if (Number(amount) > 0) await gtoken.deposit(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

    if (action == 'withdraw') {
      const balance = await gtoken.balanceOf(account);
      const amount = randomAmount(gtoken, balance);
      console.log('WITHDRAW', amount);
      try {
        if (Number(amount) > 0) await gtoken.withdraw(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

    if (action == 'withdrawAll') {
      const balance = await gtoken.balanceOf(account);
      const amount = balance;
      console.log('WITHDRAW ALL', amount);
      try {
        if (Number(amount) > 0) await gtoken.withdraw(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
      continue;
    }

  }
}

entrypoint(main);
