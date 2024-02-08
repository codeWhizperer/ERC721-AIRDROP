# ERC721 AIRDROP CONTRACT

## An implementation of ERC721 standard on Starknet

## How to use contract:

1. **Clone project**
```bash
git clone https://github.com/codeWhizperer/ERC721-AIRDROP
```
2. **Change directory into working project**

```bash
cd ERC721-AIRDROP
```

3. **Set up starknet-foundry account for declaration of contract**: https://foundry-rs.github.io/starknet-foundry/starknet/account.html

4. **Set up profile in scarb.toml for contract declaration**
 ```bash
 # ...
[sncast.myprofile]
account = "user"
accounts-file = "~/my_accounts.json"
url = "http://127.0.0.1:5050/rpc"
# ...
```
[Reference starknet-foundry for more information](https://foundry-rs.github.io/starknet-foundry/projects/configuration.html)

5. Declare contract via the command below:
```bash
sncast --profile <profile> declare --contract-name <contract_name>
```
6. Deploy Contract:

 [Reference the deployment script to deploy contract](https://github.com/codeWhizperer/ERC721-AIRDROP-SCRIPT)