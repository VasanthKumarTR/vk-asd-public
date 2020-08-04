Invoke-WebRequest -Uri "https://files.trendmicro.com/products/deepsecurity/en/12.0/Agent-Windows-12.0.0-1186.x86_64.zip" -OutFile TrendInstall.zip
Expand-Archive -Path TrendInstall.zip
.\TrendInstall\*.msi
