cp webf5pd /nanopore/bin/ # (3): Change '/nanopore/bin' to point to the location of (2) in webf5pd.service
cp scripts/webf5pd.service /etc/systemd/system/webf5pd.service
systemctl daemon-reload
systemctl enable f5pd
