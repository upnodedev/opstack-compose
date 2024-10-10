# delete the existing folder if it exists
rm -rf bridge-indexer
rm -rf bridge-ui

git clone https://github.com/upnodedev/opstack-bridge-indexer-v2.git bridge-indexer
git clone https://github.com/upnodedev/opstack-bridge-ui-v2.git bridge-ui
