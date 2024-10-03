Upnode Deploy is an open-source Docker Compose and UI tool for deploying an OP Stack chain.

Unlike Conduit, which is a paid, closed-source RaaS, Upnode Deploy is an open-source public good that helps developers customize and deploy their OP Stack chain.

## Getting Started

Clone the repository: https://github.com/upnodedev/opstack-compose

Copy the .env.example file to .env.

Edit the following sections in the .env file:

```
##################################################
#                 Accounts Info                  #
##################################################

# Admin account
ADMIN_PRIVATE_KEY=

# Batcher account
BATCHER_PRIVATE_KEY=

# Proposer account
PROPOSER_PRIVATE_KEY=

# Sequencer account
SEQUENCER_PRIVATE_KEY=

# Contract deployer account
DEPLOYER_PRIVATE_KEY=$ADMIN_PRIVATE_KEY

##################################################
#                 L1 RPC Info                    #
##################################################

# The kind of RPC provider, used to inform optimal transaction receipts
# fetching. Valid options: alchemy, quicknode, infura, parity, nethermind,
# debug_geth, erigon, basic, any.
L1_RPC_KIND=basic

# RPC URL for the L1 network to interact with
L1_RPC_URL=<Tenderly Fraxtal RPC Endpoint>

##################################################
#               Deployment Info                  #
##################################################

# The chain identifier for the L2 network
L2_CHAIN_ID=<Chain ID>
```

You can use the same private key for Admin, Batcher, Proposer, and Sequencer for ease of testing. However, this practice is not recommended on the mainnet.

After editing the .env file, deploy the chain using Docker Compose by running the following command:

```
docker compose --profile sequencer up -d --build
```

Wait for it to deploy the OP Stack chain as a Fraxtal L3.

Once the deployment is complete, your Fraxtal L3 will be accessible at:

* **RPC:** http://YOURIPADDRESS:8545
* **WS:** ws://YOURIPADDRESS:8545

To deploy the Blockscout explorer for your Fraxtal L3 chain, navigate to the blockscout folder and run:

```
docker compose -f geth.yml up -d --build
```

If you want to point a domain name to these endpoints or introduce a rate limit, you can use a reverse proxy such as Nginx or Traefik to handle this job.

Span batch activated by default!
