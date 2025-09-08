package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"time"

	"github.com/docker/docker/client"
)

func main() {
	fmt.Println("=== Test Docker Auto-Start ===")
	
	// Créer un client Docker
	dockerClient, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		fmt.Printf("❌ Failed to create Docker client: %v\n", err)
		return
	}
	
	// Tester la connexion
	_, err = dockerClient.Ping(context.Background())
	if err == nil {
		fmt.Println("✅ Docker is already running")
		return
	}
	
	fmt.Println("⚠️  Docker is not running, attempting to start...")
	
	// Sur Windows, essayer de démarrer Docker Desktop
	if runtime.GOOS == "windows" {
		fmt.Println("🪟 Windows detected - starting Docker Desktop...")
		cmd := exec.Command("cmd", "/c", "start", "Docker Desktop")
		if err := cmd.Run(); err != nil {
			fmt.Printf("❌ Could not start Docker Desktop: %v\n", err)
			return
		}
		
		// Attendre que Docker soit prêt
		fmt.Println("⏳ Waiting for Docker to start...")
		for i := 0; i < 30; i++ {
			time.Sleep(2 * time.Second)
			_, err := dockerClient.Ping(context.Background())
			if err == nil {
				fmt.Println("✅ Docker started successfully!")
				return
			}
			fmt.Printf("⏳ Still waiting... (%d/30)\n", i+1)
		}
		fmt.Println("❌ Docker did not start within 60 seconds")
	} else {
		fmt.Println("🐧 Linux/macOS detected - starting Docker service...")
		cmd := exec.Command("sudo", "systemctl", "start", "docker")
		if err := cmd.Run(); err != nil {
			fmt.Printf("❌ Could not start Docker service: %v\n", err)
			return
		}
		
		// Attendre que Docker soit prêt
		fmt.Println("⏳ Waiting for Docker to start...")
		for i := 0; i < 15; i++ {
			time.Sleep(2 * time.Second)
			_, err := dockerClient.Ping(context.Background())
			if err == nil {
				fmt.Println("✅ Docker started successfully!")
				return
			}
			fmt.Printf("⏳ Still waiting... (%d/15)\n", i+1)
		}
		fmt.Println("❌ Docker did not start within 30 seconds")
	}
}
