import os

env = {}
with open(".env", "r") as f:
    for line in f:
        if "=" in line:
            key, val = line.strip().split("=", 1)
            env[key] = val

content = f"""server.host: "0.0.0.0"
server.publicBaseUrl: "https://{env.get('HOST_IP')}:5601"
elasticsearch.hosts: ["https://elastic:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "{env.get('KIBANA_PASSWORD')}"
elasticsearch.ssl.certificateAuthorities: ["config/certs/ca/ca.crt"]
xpack.security.encryptionKey: "{env.get('ENCRYPTION_KEY')}"
xpack.encryptedSavedObjects.encryptionKey: "{env.get('ENCRYPTION_KEY')}"
xpack.reporting.encryptionKey: "{env.get('ENCRYPTION_KEY')}"
"""

with open("kibana.yml", "w") as f:
    f.write(content)
print("kibana.yml generated successfully.")
