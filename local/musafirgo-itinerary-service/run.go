package main

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
)

func main() {
	fmt.Println("=== MusafirGO Pipeline Go - Run Script ===")
	
	// Vérifier si Go est installé
	if err := exec.Command("go", "version").Run(); err != nil {
		fmt.Println("❌ Go n'est pas installé. Veuillez installer Go 1.21 ou plus récent.")
		fmt.Println("📥 Téléchargez Go depuis: https://golang.org/dl/")
		os.Exit(1)
	}
	
	fmt.Println("✅ Go détecté")
	
	// Télécharger les dépendances
	fmt.Println("📦 Téléchargement des dépendances...")
	if err := exec.Command("go", "mod", "tidy").Run(); err != nil {
		fmt.Printf("❌ Erreur lors du téléchargement des dépendances: %v\n", err)
		os.Exit(1)
	}
	
	// Compiler la pipeline
	fmt.Println("🔨 Compilation de la pipeline...")
	buildCmd := exec.Command("go", "build", "-o", "musafirgo-pipeline", "pipeline.go")
	if err := buildCmd.Run(); err != nil {
		fmt.Printf("❌ Erreur lors de la compilation: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println("✅ Compilation réussie!")
	
	// Exécuter la pipeline
	fmt.Println("🚀 Exécution de la pipeline...")
	fmt.Println("")
	
	var runCmd *exec.Cmd
	if runtime.GOOS == "windows" {
		runCmd = exec.Command(".\\musafirgo-pipeline.exe")
	} else {
		runCmd = exec.Command("./musafirgo-pipeline")
	}
	
	runCmd.Stdout = os.Stdout
	runCmd.Stderr = os.Stderr
	
	if err := runCmd.Run(); err != nil {
		fmt.Printf("❌ Erreur lors de l'exécution: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println("")
	fmt.Println("✅ Pipeline exécutée avec succès!")
}
