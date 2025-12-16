import json
import uuid

# Load the workflow JSON
with open('compose/n8n-mas-health-check.json', 'r') as f:
    data = json.load(f)

# Extract fields
name = data.get('name', 'MAS - Proactive Health Check & Report')
nodes = json.dumps(data.get('nodes', []), separators=(',', ':'))
connections = json.dumps(data.get('connections', {}), separators=(',', ':'))
settings = json.dumps(data.get('settings', {}), separators=(',', ':'))
static_data = "null"

# Generate IDs
workflow_id = "HealthCheckFinal01"
version_id = str(uuid.uuid4())

# Escape single quotes for SQL
def escape_sql(val):
    return val.replace("'", "''")

sql = f"""
INSERT INTO workflow_entity (
    "id", 
    "name", 
    "active", 
    "nodes", 
    "connections", 
    "settings", 
    "staticData", 
    "createdAt", 
    "updatedAt", 
    "versionId"
) VALUES (
    '{workflow_id}', 
    '{escape_sql(name)}', 
    true, 
    '{escape_sql(nodes)}', 
    '{escape_sql(connections)}', 
    '{escape_sql(settings)}', 
    {static_data}, 
    NOW(), 
    NOW(), 
    '{version_id}'
);
"""

with open('restore_workflow.sql', 'w') as f:
    f.write(sql)

print(f"SQL generated for Workflow ID: {workflow_id}")
