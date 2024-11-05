This is the forked version of go-ethereum optimized for collecting large amounts of network data that otherwise is kept in memory and never persisted. (USING primary branch `indigo`)

**Objectives of the fork:**
1. Create a logging module ([indigo/](https://github.com/indigodata/geth/tree/indigo/indigo)) that can be used throughout the repository for persisting relevant network and peer data.
2. Perform fast writes to disk in order to not interupt performance of the core p2p functionality.
3. Add linux deployment scripts in [_infra/](https://github.com/indigodata/geth/tree/indigo/_infra).
4. Allow for easy rebasing for ongoing upgrades to open source main branch.
5. Add functionality to optimize node restarts and the cycling of peer nodes to get the broadest view of the network possible. (i.e. https://github.com/indigodata/geth/pull/14)
