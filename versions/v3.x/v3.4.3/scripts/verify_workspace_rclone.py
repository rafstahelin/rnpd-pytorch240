#!/usr/bin/env python3
import os
import stat
import subprocess
from datetime import datetime
from rich import print
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

console = Console()

def check_config_paths():
    """Check for rclone.conf in both workspace and root config paths"""
    paths = {
        'workspace': '/workspace/.config/rclone/rclone.conf',
        'root': '/root/.config/rclone/rclone.conf'
    }
    
    results = []
    
    for location, path in paths.items():
        if os.path.exists(path):
            stats = os.stat(path)
            perms = oct(stats.st_mode)[-3:]
            mtime = datetime.fromtimestamp(stats.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
            size = stats.st_size
            
            # Check if permissions are correct (600)
            perms_ok = perms == '600'
            
            results.append({
                "location": location,
                "path": path,
                "exists": True,
                "permissions": perms,
                "permissions_ok": perms_ok,
                "modified": mtime,
                "size": f"{size} bytes",
                "has_content": size > 0
            })
        else:
            results.append({
                "location": location,
                "path": path,
                "exists": False
            })
    
    return results

def test_rclone_functionality():
    """Test if rclone can read the config and list remotes"""
    try:
        # Test listremotes
        result = subprocess.run(['rclone', 'listremotes'], 
                              capture_output=True, 
                              text=True)
        if result.returncode == 0:
            remotes = result.stdout.strip().split('\n')
            has_dbx = any(remote.startswith('dbx:') for remote in remotes)
            return True, remotes if remotes[0] != '' else [], has_dbx
        return False, ["Error: Unable to list remotes"], False
    except Exception as e:
        return False, [f"Error: {str(e)}"], False

def main():
    console.print("\n[bold cyan]🔍 Checking Rclone Configuration[/]\n")
    
    # Check config files
    results = check_config_paths()
    
    # Display config file status
    table = Table(title="Rclone Configuration Status")
    table.add_column("Location", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Details", style="yellow")
    
    for result in results:
        if result["exists"]:
            status_parts = []
            if result["has_content"]:
                status_parts.append("✓ Has content")
            else:
                status_parts.append("⚠ Empty file")
            
            if result.get("permissions_ok"):
                status_parts.append("✓ Permissions OK")
            else:
                status_parts.append("⚠ Incorrect permissions")
            
            status = "\n".join(status_parts)
            
            details = f"Path: {result['path']}\n"
            details += f"Permissions: {result['permissions']}\n"
            details += f"Modified: {result['modified']}\n"
            details += f"Size: {result['size']}"
        else:
            status = "✗ Missing"
            details = f"Expected at:\n{result['path']}"
        
        table.add_row(
            result["location"].title(),
            status,
            details
        )
    
    console.print(table)
    
    # Test rclone functionality
    console.print("\n[bold cyan]🔄 Testing Rclone Functionality[/]\n")
    success, remotes, has_dbx = test_rclone_functionality()
    
    table = Table(title="Rclone Functionality Test")
    table.add_column("Test", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Details", style="yellow")
    
    table.add_row(
        "List Remotes",
        "✓ Success" if success else "✗ Failed",
        "\n".join(remotes) if remotes else "No remotes found"
    )
    
    if success:
        table.add_row(
            "Dropbox Remote",
            "✓ Found" if has_dbx else "✗ Missing",
            "dbx: remote is configured" if has_dbx else "dbx: remote not found"
        )
    
    console.print(table)
    
    # Summary and recommendations
    issues = []
    for result in results:
        if not result["exists"]:
            issues.append(f"Missing config at {result['path']}")
        elif not result.get("permissions_ok"):
            issues.append(f"Incorrect permissions on {result['path']} (should be 600)")
        elif not result.get("has_content"):
            issues.append(f"Empty config file at {result['path']}")
    
    if not success or not has_dbx:
        issues.append("Rclone cannot find or use the Dropbox remote")
    
    if issues:
        console.print("\n[bold red]❌ Issues found:[/]")
        for issue in issues:
            console.print(f"  • [red]{issue}[/]")
        
        console.print("\n[bold yellow]Recommendations:[/]")
        console.print("1. Ensure rclone.conf exists in /workspace/.config/rclone/")
        console.print("2. Set permissions to 600: chmod 600 /workspace/.config/rclone/rclone.conf")
        console.print("3. Restart the pod to allow proper configuration copying")
        return 1
    else:
        console.print("\n[bold green]✅ All checks passed! Rclone is properly configured.[/]")
        return 0

if __name__ == "__main__":
    exit(main())
