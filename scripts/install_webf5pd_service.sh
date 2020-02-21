cp scripts/webf5pd.service /etc/systemd/system/webf5pd.service
systemctl daemon-reload
systemctl enable f5pd
