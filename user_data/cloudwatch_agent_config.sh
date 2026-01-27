#!/bin/bash
sudo yum install -y amazon-cloudwatch-agent

# Writing config to a specific path
cat <<'EOT' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
            "log_group_name": "/aws/ec2/lab-rds-app",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/my-app.log",
            "log_group_name": "MyLogGroup/AppLogs",
            "log_stream_name": "app-stream",
            "timezone": "LOCAL"
          }
        ]
      }
    },
    "log_stream_name": "custom_log_stream_name",
    "force_flush_interval": 15
  }
}
EOT

# FIX: Point -c to the file path used above (/etc/amazon-cloudwatch-agent.json)
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# These are technically redundant if you use the '-s' flag above, but safe to keep
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
