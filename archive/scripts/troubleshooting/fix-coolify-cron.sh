#!/bin/bash
#
# Fix Coolify database schema issues
# 
# This script fixes common Coolify database migration gaps:
# 1. Missing cron expression columns:
#    - instance_settings.update_check_frequency (default: '0 * * * *' - hourly)
#    - instance_settings.auto_update_frequency (default: '0 0 * * *' - daily at midnight)
#    - server_settings.docker_cleanup_frequency (default: '0 2 * * *' - daily at 2 AM)
# 2. Missing soft delete columns:
#    - servers.deleted_at (TIMESTAMP NULL)
#    - services.deleted_at (TIMESTAMP NULL)
#
# These fixes resolve:
# - "translate_cron_expression(): Return value must be of type string, null returned" errors
# - "no such column: servers.deleted_at" errors
# - "no such column: services.deleted_at" errors
#
# Usage: ./scripts/fix-coolify-cron.sh
# Then restart: docker compose -f compose/coolify.yml --env-file .env restart coolify

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=== Coolify Cron Expression Fix ==="
echo ""

# Check if coolify container is running
if ! docker compose -f compose/coolify.yml --env-file .env ps coolify | grep -q "Up"; then
    echo "Error: Coolify container is not running"
    exit 1
fi

echo "Step 1: Adding missing columns to instance_settings..."
docker compose -f compose/coolify.yml --env-file .env exec -T coolify php artisan tinker <<'PHPCODE'
try {
    $cols = DB::select("PRAGMA table_info(instance_settings)");
    $colNames = array_column($cols, 'name');
    
    if (!in_array('update_check_frequency', $colNames)) {
        DB::statement("ALTER TABLE instance_settings ADD COLUMN update_check_frequency VARCHAR(255) DEFAULT '0 * * * *'");
        echo "  ✓ Added update_check_frequency column\n";
    }
    
    if (!in_array('auto_update_frequency', $colNames)) {
        DB::statement("ALTER TABLE instance_settings ADD COLUMN auto_update_frequency VARCHAR(255) DEFAULT '0 0 * * *'");
        echo "  ✓ Added auto_update_frequency column\n";
    }
    
    echo "Step 2: Updating NULL values with defaults...\n";
    DB::table('instance_settings')->where('id', 0)->update([
        'update_check_frequency' => DB::raw("COALESCE(update_check_frequency, '0 * * * *')"),
        'auto_update_frequency' => DB::raw("COALESCE(auto_update_frequency, '0 0 * * *')")
    ]);
    
    // Fix server_settings docker_cleanup_frequency
    $serverCols = DB::select("PRAGMA table_info(server_settings)");
    $serverColNames = array_column($serverCols, 'name');
    
    if (!in_array('docker_cleanup_frequency', $serverColNames)) {
        DB::statement("ALTER TABLE server_settings ADD COLUMN docker_cleanup_frequency VARCHAR(255) DEFAULT '0 2 * * *'");
        echo "  ✓ Added docker_cleanup_frequency column to server_settings\n";
    }
    
    $serverSettings = DB::table('server_settings')->get();
    foreach ($serverSettings as $setting) {
        if (empty($setting->docker_cleanup_frequency)) {
            DB::table('server_settings')
                ->where('id', $setting->id)
                ->update(['docker_cleanup_frequency' => '0 2 * * *']);
        }
    }
    
    echo "Step 3: Fixing soft delete columns in tables...\n";
    
    // Fix servers table
    $serverCols = DB::select("PRAGMA table_info(servers)");
    $serverColNames = array_column($serverCols, 'name');
    if (!in_array('deleted_at', $serverColNames)) {
        DB::statement("ALTER TABLE servers ADD COLUMN deleted_at TIMESTAMP NULL");
        echo "  ✓ Added deleted_at column to servers table\n";
    }
    
    // Fix services table
    try {
        $serviceCols = DB::select("PRAGMA table_info(services)");
        $serviceColNames = array_column($serviceCols, 'name');
        if (!in_array('deleted_at', $serviceColNames)) {
            DB::statement("ALTER TABLE services ADD COLUMN deleted_at TIMESTAMP NULL");
            echo "  ✓ Added deleted_at column to services table\n";
        }
    } catch (Exception $e) {
        echo "  ⚠ Could not check services table: " . $e->getMessage() . "\n";
    }
    
    echo "Step 4: Verifying fixes...\n";
    $setting = App\Models\InstanceSettings::get();
    echo "  update_check_frequency: " . ($setting->update_check_frequency ?? 'NULL') . "\n";
    echo "  auto_update_frequency: " . ($setting->auto_update_frequency ?? 'NULL') . "\n";
    
    // Test accessing the values to ensure no errors
    try {
        $test1 = $setting->update_check_frequency;
        $test2 = $setting->auto_update_frequency;
        echo "  ✓ Both cron expressions accessible without errors\n";
    } catch (Exception $e) {
        echo "  ✗ Error accessing cron expressions: " . $e->getMessage() . "\n";
        throw $e;
    }
    
    // Test servers table query with deleted_at
    try {
        $servers = DB::table('servers')->whereNull('deleted_at')->count();
        echo "  ✓ Servers table query with deleted_at works (found {$servers} servers)\n";
    } catch (Exception $e) {
        echo "  ✗ Error querying servers table: " . $e->getMessage() . "\n";
        throw $e;
    }
    
    // Test services table query with deleted_at (if table exists)
    try {
        $services = DB::table('services')->whereNull('deleted_at')->count();
        echo "  ✓ Services table query with deleted_at works (found {$services} services)\n";
    } catch (Exception $e) {
        echo "  ⚠ Services table query test skipped: " . $e->getMessage() . "\n";
    }
    
    echo "\n✓ SUCCESS: All database schema fixes applied!\n";
    echo "Restart Coolify to clear the errors: docker compose -f compose/coolify.yml --env-file .env restart coolify\n";
} catch (Exception $e) {
    echo "✗ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
PHPCODE

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "Fix completed successfully!"
else
    echo ""
    echo "Fix failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi
