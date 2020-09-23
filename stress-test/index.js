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

const GTOKEN_ADDRESS = {
  'mainnet': '',
  'ropsten': '',
  'rinkeby': '',
  'kovan': '0xf2B75B09431E3E9b9Fb92fa593d260462A600470',
  'goerli': '',
  'development': '0x0D3aaBd23b827Dd63FE59888D792EE27C00B53A8',
};

const [account] = web3.currentProvider.getAddresses();

const ABI_ERC20 = require('../build/contracts/ERC20.json').abi;
const ABI_CTOKEN = require('../build/contracts/CToken.json').abi;
const ABI_GTOKEN = require('../build/contracts/gcDAI.json').abi;

async function getEthBalance(address) {
  const amount = await web3.eth.getBalance(address);
  return coins(amount, 18);
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
  const reserveToken = await newCToken(await contract.methods.reserveToken().call());
  return (self = {
    ...fields,
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
    mint: async (amount, maxCost) => {
      const _amount = units(amount, self.decimals);
      const value = units(maxCost, 18);
      await contract.methods.faucet(_amount).send({ from: account, value });
    },
  });
}

function randomAmount(token, balance) {
  const _balance = units(balance, token.decimals);
  const _amount = Math.floor(Math.random() * (Number(_balance) + 1));
  return coins(String(_amount), token.decimals);
}

async function main(args) {
  const gtoken = await newGToken(GTOKEN_ADDRESS[network]);
  const ctoken = gtoken.reserveToken;

  blockSubscribe((number) => {
    console.log('block ' + number);
  });

  const events = [
    'Debug(address,string)',
    'Debug(address,string,uint256)',
    'Debug(address,string,address)',
    'ReserveChange(uint256,uint256)',
  ];
  logSubscribe(events, (address, event, values) => {
    if (address == gtoken.address) {
      if (event == 'ReserveChange(uint256,uint256)') {
        console.log('**', (100 * Number(values[1])) / Number(values[0]));
      } else {
        console.log('>>', values.slice(1).join(' '));
      }
    }
  });

  await gtoken.mint('1', '1');

  console.log(network);
  console.log(gtoken.name, gtoken.symbol, gtoken.decimals);
  console.log(ctoken.name, ctoken.symbol, ctoken.decimals);
  console.log('total supply', await gtoken.totalSupply());
  console.log('total reserve', await gtoken.totalReserve());
  console.log('gtoken balance', await gtoken.balanceOf(account));
  console.log('ctoken balance', await ctoken.balanceOf(account));
  console.log('eth balance', await getEthBalance(account));

  const success = await ctoken.approve(gtoken.address, '1000000000');
  console.log('approve', success);
  console.log('ctoken allowance', await ctoken.allowance(account, gtoken.address));

  for (let i = 0; i < 40; i++) {
    if (i < 20) {
      const balance = await ctoken.balanceOf(account);
      const amount = i == 19 ? balance : randomAmount(ctoken, balance);
      console.log('DEPOSIT', amount);
      try {
        if (Number(amount) > 0) await gtoken.deposit(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
    } else {
      const balance = await gtoken.balanceOf(account);
      const amount = i == 39 ? balance : randomAmount(gtoken, balance);
      console.log('WITHDRAW', amount);
      try {
        if (Number(amount) > 0) await gtoken.withdraw(amount);
      } catch (e) {
        console.log('!!', e.message);
      }
    }
    console.log('total supply', await gtoken.totalSupply());
    console.log('total reserve', await gtoken.totalReserve());
    console.log('gtoken balance', await gtoken.balanceOf(account));
    console.log('ctoken balance', await ctoken.balanceOf(account));
    console.log('eth balance', await getEthBalance(account));
    await sleep(5 * 1000);
  }
}

entrypoint(main);
