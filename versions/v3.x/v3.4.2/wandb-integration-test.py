import os
import wandb
import sys
from rich import print

def clean_env_var(var_name):
    """Clean environment variable by removing = if present"""
    value = os.getenv(var_name, '')
    return value.split('=')[-1] if '=' in value else value

def test_wandb_integration():
    results = {
        "Token Configuration": False,
        "Project Creation": False,
        "Run Logging": False,
        "Artifact Upload": False
    }
    
    try:
        # Clean the WANDB API key
        wandb_key = clean_env_var("WANDB_API_KEY")
        if not wandb_key:
            print("Error: WANDB_API_KEY not set or empty")
            return

        # Set clean key in environment
        os.environ["WANDB_API_KEY"] = wandb_key
        
        # Test 1: Token Configuration
        if wandb.login(key=wandb_key):
            print("✓ WANDB Token Valid")
            results["Token Configuration"] = True

            # Test 2: Project Creation
            project_name = "pytorch240-test"
            run = wandb.init(
                project=project_name, 
                name="integration-test",
                config={"test": True}
            )
            
            if run:
                print(f"✓ Project Created: {project_name}")
                results["Project Creation"] = True

                # Test 3: Run Logging
                try:
                    wandb.log({"test_metric": 0.5})
                    print("✓ Metrics Logged")
                    results["Run Logging"] = True
                except Exception as e:
                    print(f"Logging error: {str(e)}")

                # Test 4: Artifact Upload
                try:
                    with open("test_artifact.txt", "w") as f:
                        f.write("test content")
                    
                    artifact = wandb.Artifact("test_artifact", type="dataset")
                    artifact.add_file("test_artifact.txt")
                    run.log_artifact(artifact)
                    print("✓ Artifact Uploaded")
                    results["Artifact Upload"] = True
                except Exception as e:
                    print(f"Artifact error: {str(e)}")
                finally:
                    if os.path.exists("test_artifact.txt"):
                        os.remove("test_artifact.txt")

                # Cleanup
                run.finish()

    except Exception as e:
        print(f"Error during testing: {str(e)}")
    finally:
        # Print results
        print("\n=== Test Results ===")
        for test, passed in results.items():
            status = "✓ PASSED" if passed else "✗ FAILED"
            print(f"{test}: {status}")

if __name__ == "__main__":
    test_wandb_integration()
