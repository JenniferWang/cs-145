rm -f AuctionBase.db
sqlite3 AuctionBase.db < create.sql
sqlite3 AuctionBase.db < load.txt
sqlite3 AuctionBase.db < constraints_verify.sql
sqlite3 AuctionBase.db < trigger_add.sql
