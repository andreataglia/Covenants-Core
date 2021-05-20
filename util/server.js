var memdown = require('memdown');
var ethers = require('ethers');
var context = require('./context.json');
(require('dotenv')).config();
var Web3 = require('web3');

var mnemonic = context.mnemonicTest || process.env.mnemonic;

async function main() {
    var options = {
        gasLimit: 10000000,
        db: memdown(),
        total_accounts: process.env.accounts || 15,
        default_balance_ether: 999999999999,
        asyncRequestProcessing : true,
        logger : console,
        verbose : true
    };

    if (process.env.blockchain_connection_string) {
        options.fork = process.env.blockchain_connection_string;
        options.gasLimit = parseInt((await new Web3(process.env.blockchain_connection_string).eth.getBlock("latest")).gasLimit);
    }

    global.gasLimit = options.gasLimit;

    if (mnemonic) {
        options.mnemonic = mnemonic;
        for (var i = 0; i < options.total_accounts; i++) {
            var wallet = ethers.Wallet.fromMnemonic(options.mnemonic, "m/44'/60'/0'/0/" + i);
            console.log(wallet.address, wallet.privateKey);
        }
    }

    const port = process.env.port || 8545;
    require("ganache-core").server(options).listen(port, async function(error, blockchain) {
        if(error) {
            return console.error(e);
        }
        global.accounts = await (global.web3 = new Web3(blockchain._provider)).eth.getAccounts();
        process.argv[2] && require('../server-verts/' + process.argv[2]);
        console.log('ganache server listening on port ' + port);
    });
}

main().catch(console.error);