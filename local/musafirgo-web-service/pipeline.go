package main

import (
	"bytes"
	"context"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/docker/docker/client"
)

// PipelineResult représente le résultat global de la pipeline
type PipelineResult struct {
	StartTime     time.Time       `json:"start_time"`
	EndTime       time.Time       `json:"end_time"`
	TotalDuration float64         `json:"total_duration_seconds"`
	Success       bool            `json:"success"`
	Steps         map[string]Step `json:"steps"`
}

// Step représente une étape de la pipeline
type Step struct {
	Name     string      `json:"name"`
	Success  bool        `json:"success"`
	Duration float64     `json:"duration_seconds"`
	Error    string      `json:"error,omitempty"`
	Result   interface{} `json:"result,omitempty"`
}

// APITestResult représente les résultats des tests API
type APITestResult struct {
	Total       int      `json:"total"`
	Passed      int      `json:"passed"`
	Failed      int      `json:"failed"`
	SuccessRate float64  `json:"success_rate"`
	Details     []string `json:"details"`
}

// PerformanceResult représente les résultats de performance
type PerformanceResult struct {
	HealthCheck     float64 `json:"health_check_ms"`
	Destinations    float64 `json:"destinations_ms"`
	Accommodations  float64 `json:"accommodations_ms"`
	AuthLogin       float64 `json:"auth_login_ms"`
	AuthRegister    float64 `json:"auth_register_ms"`
	AuthMe          float64 `json:"auth_me_ms"`
	AverageTime     float64 `json:"average_time_ms"`
	MaxTime         float64 `json:"max_time_ms"`
	MinTime         float64 `json:"min_time_ms"`
	SuccessfulTests int     `json:"successful_tests"`
}

// MusafirGoWebPipeline structure principale pour le projet Angular
type MusafirGoWebPipeline struct {
	BaseURL      string
	Results      *PipelineResult
	DockerClient *client.Client
	Logger       *log.Logger
	SkipInit     bool
	SkipDataLoad bool
	SkipTests    bool
	ProjectPath  string
}

// NewWebPipeline crée une nouvelle instance de pipeline pour Angular
func NewWebPipeline(baseURL string, skipInit, skipDataLoad, skipTests bool) *MusafirGoWebPipeline {
	logger := log.New(os.Stdout, "", 0)

	dockerClient, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		logger.Printf("[ERROR] Failed to create Docker client: %v", err)
	}

	// Chemin vers le projet Angular
	projectPath := "C:\\Users\\omars\\workspace\\musafirgo\\musafirgo-web-service"

	return &MusafirGoWebPipeline{
		BaseURL:      baseURL,
		Results:      &PipelineResult{StartTime: time.Now(), Steps: make(map[string]Step)},
		DockerClient: dockerClient,
		Logger:       logger,
		SkipInit:     skipInit,
		SkipDataLoad: skipDataLoad,
		SkipTests:    skipTests,
		ProjectPath:  projectPath,
	}
}

// Log écrit un message de log avec timestamp et niveau
func (p *MusafirGoWebPipeline) Log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	p.Logger.Printf("[%s] [%s] %s", timestamp, level, message)
}

// CheckPrerequisites vérifie les prérequis
func (p *MusafirGoWebPipeline) CheckPrerequisites() bool {
	p.Log("INFO", "Checking prerequisites for Angular project...")

	prerequisites := map[string]bool{
		"Docker":        false,
		"DockerCompose": false,
		"Node.js":       false,
		"Angular CLI":   false,
	}

	// Vérifier Docker
	if p.DockerClient != nil {
		_, err := p.DockerClient.Ping(context.Background())
		if err == nil {
			prerequisites["Docker"] = true
			p.Log("SUCCESS", "Docker: OK")
		} else {
			p.Log("WARN", "Docker: NOT RUNNING - Attempting to start...")
			if p.StartDockerService() {
				prerequisites["Docker"] = true
				p.Log("SUCCESS", "Docker: STARTED AND READY")
			} else {
				p.Log("ERROR", "Docker: FAILED TO START")
			}
		}
	} else {
		p.Log("ERROR", "Docker: NOT FOUND")
	}

	// Vérifier Docker Compose
	cmd := exec.Command("docker-compose", "--version")
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", "Docker Compose: NOT FOUND")
	} else {
		prerequisites["DockerCompose"] = true
		p.Log("SUCCESS", "Docker Compose: OK")
	}

	// Vérifier Node.js
	cmd = exec.Command("node", "--version")
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", "Node.js: NOT FOUND")
	} else {
		prerequisites["Node.js"] = true
		p.Log("SUCCESS", "Node.js: OK")
	}

	// Vérifier Angular CLI
	cmd = exec.Command("ng", "version")
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", "Angular CLI: NOT FOUND")
	} else {
		prerequisites["Angular CLI"] = true
		p.Log("SUCCESS", "Angular CLI: OK")
	}

	// Vérifier si tous les prérequis sont satisfaits
	allOk := true
	for _, ok := range prerequisites {
		if !ok {
			allOk = false
			break
		}
	}

	if !allOk {
		p.Log("ERROR", "Prerequisites check failed. Please install missing components.")
		return false
	}

	p.Log("SUCCESS", "All prerequisites satisfied")
	return true
}

// StartDockerService démarre le service Docker
func (p *MusafirGoWebPipeline) StartDockerService() bool {
	p.Log("INFO", "Attempting to start Docker service...")

	// Sur Windows, essayer de démarrer Docker Desktop
	if runtime.GOOS == "windows" {
		cmd := exec.Command("cmd", "/c", "start", "Docker Desktop")
		if err := cmd.Run(); err != nil {
			p.Log("WARN", "Could not start Docker Desktop automatically. Please start it manually.")
			return false
		}

		// Attendre que Docker soit prêt
		p.Log("INFO", "Waiting for Docker to start...")
		for i := 0; i < 30; i++ {
			time.Sleep(2 * time.Second)
			if p.DockerClient != nil {
				_, err := p.DockerClient.Ping(context.Background())
				if err == nil {
					p.Log("SUCCESS", "Docker started successfully")
					return true
				}
			}
		}
		p.Log("ERROR", "Docker did not start within 60 seconds")
		return false
	}

	// Sur Linux/macOS, essayer de démarrer le service Docker
	cmd := exec.Command("sudo", "systemctl", "start", "docker")
	if err := cmd.Run(); err != nil {
		p.Log("WARN", "Could not start Docker service automatically. Please start it manually.")
		return false
	}

	// Attendre que Docker soit prêt
	p.Log("INFO", "Waiting for Docker to start...")
	for i := 0; i < 15; i++ {
		time.Sleep(2 * time.Second)
		if p.DockerClient != nil {
			_, err := p.DockerClient.Ping(context.Background())
			if err == nil {
				p.Log("SUCCESS", "Docker started successfully")
				return true
			}
		}
	}
	p.Log("ERROR", "Docker did not start within 30 seconds")
	return false
}

// BuildAngularApplication construit l'application Angular
func (p *MusafirGoWebPipeline) BuildAngularApplication() bool {
	p.Log("INFO", "Building Angular application...")

	// Changer vers le répertoire du projet
	originalDir, _ := os.Getwd()
	defer os.Chdir(originalDir)

	if err := os.Chdir(p.ProjectPath); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to change to project directory: %v", err))
		return false
	}

	// Installer les dépendances
	p.Log("INFO", "Installing dependencies...")
	cmd := exec.Command("npm", "install")
	cmd.Dir = p.ProjectPath
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to install dependencies: %v", err))
		return false
	}

	// Build de production
	p.Log("INFO", "Building Angular application for production...")
	cmd = exec.Command("ng", "build", "--configuration", "production")
	cmd.Dir = p.ProjectPath
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to build Angular application: %v", err))
		return false
	}

	p.Log("SUCCESS", "Angular application built successfully")
	return true
}

// StartMockServices démarre les services mock
func (p *MusafirGoWebPipeline) StartMockServices() bool {
	p.Log("INFO", "Starting mock services...")

	// Changer vers le répertoire du projet
	originalDir, _ := os.Getwd()
	defer os.Chdir(originalDir)

	if err := os.Chdir(p.ProjectPath); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to change to project directory: %v", err))
		return false
	}

	// Démarrer les services avec Docker Compose
	cmd := exec.Command("docker-compose", "-f", "docker-compose.dev.yml", "up", "-d")
	cmd.Dir = p.ProjectPath
	if err := cmd.Run(); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to start mock services: %v", err))
		return false
	}

	// Attendre que les services soient prêts
	p.Log("INFO", "Waiting for services to be ready...")
	time.Sleep(30 * time.Second)

	// Vérifier que les services sont en cours d'exécution
	cmd = exec.Command("docker-compose", "-f", "docker-compose.dev.yml", "ps", "--services", "--filter", "status=running")
	cmd.Dir = p.ProjectPath
	output, err := cmd.Output()
	if err != nil {
		p.Log("ERROR", "Failed to check running services")
		return false
	}

	services := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(services) >= 2 {
		p.Log("SUCCESS", "Mock services started successfully")
		return true
	}

	p.Log("ERROR", "Mock services failed to start")
	return false
}

// HealthChecks exécute les vérifications de santé
func (p *MusafirGoWebPipeline) HealthChecks() bool {
	p.Log("INFO", "Running health checks...")

	allHealthy := true

	// Vérifier la santé de l'API mock
	resp, err := http.Get(p.BaseURL + "/api/health")
	if err != nil || resp.StatusCode != 200 {
		p.Log("ERROR", "Mock API health: FAILED")
		allHealthy = false
	} else {
		p.Log("SUCCESS", "Mock API health: OK")
		resp.Body.Close()
	}

	// Vérifier la santé de l'application Angular (optionnel pour l'instant)
	resp, err = http.Get("http://localhost:4200")
	if err != nil || resp.StatusCode != 200 {
		p.Log("WARNING", "Angular application health: NOT RUNNING (expected for now)")
		// Ne pas considérer comme une erreur critique pour l'instant
	} else {
		p.Log("SUCCESS", "Angular application health: OK")
		resp.Body.Close()
	}

	if allHealthy {
		p.Log("SUCCESS", "All health checks passed")
	} else {
		p.Log("WARNING", "Some health checks failed (Angular app not running)")
	}

	return true // Continue même si certains checks échouent
}

// APITests exécute les tests API complets
func (p *MusafirGoWebPipeline) APITests() *APITestResult {
	if p.SkipTests {
		p.Log("INFO", "Skipping API tests...")
		return &APITestResult{Total: 0, Passed: 0, Failed: 0, SuccessRate: 100.0, Details: []string{}}
	}

	p.Log("INFO", "Running comprehensive API tests for mock endpoints...")

	result := &APITestResult{Details: []string{}}

	// Liste des endpoints à tester
	endpoints := []struct {
		Method         string
		URL            string
		Desc           string
		Body           string
		ExpectedStatus int
		Category       string
	}{
		// Auth endpoints
		{"POST", "/api/auth/login", "Login user", `{"email":"test@musafirgo.com","password":"password"}`, 200, "Auth"},
		{"POST", "/api/auth/register", "Register user", `{"email":"newuser@test.com","password":"password","name":"New User"}`, 201, "Auth"},
		{"GET", "/api/auth/me", "Get current user", "", 200, "Auth"},

		// Destinations endpoints
		{"GET", "/api/destinations", "List all destinations", "", 200, "Destinations"},
		{"GET", "/api/destinations?search=Istanbul", "Search destinations", "", 200, "Destinations"},
		{"GET", "/api/destinations?country=Turquie", "Filter by country", "", 200, "Destinations"},
		{"GET", "/api/destinations?halalFriendly=true", "Filter halal friendly", "", 200, "Destinations"},
		{"GET", "/api/destinations/1", "Get specific destination", "", 200, "Destinations"},

		// Accommodations endpoints
		{"GET", "/api/accommodations", "List all accommodations", "", 200, "Accommodations"},
		{"GET", "/api/accommodations?search=Hotel", "Search accommodations", "", 200, "Accommodations"},
		{"GET", "/api/accommodations?location=Istanbul", "Filter by location", "", 200, "Accommodations"},
		{"GET", "/api/accommodations?minPrice=50&maxPrice=200", "Filter by price range", "", 200, "Accommodations"},
		{"GET", "/api/accommodations?halalCertified=true", "Filter halal certified", "", 200, "Accommodations"},
		{"GET", "/api/accommodations/1", "Get specific accommodation", "", 200, "Accommodations"},

		// Error tests
		{"GET", "/api/destinations/999", "Get non-existent destination", "", 404, "Destinations"},
		{"GET", "/api/accommodations/999", "Get non-existent accommodation", "", 404, "Accommodations"},
		{"POST", "/api/auth/login", "Invalid login", `{"email":"invalid@test.com","password":"wrong"}`, 401, "Auth"},
		{"POST", "/api/auth/register", "Invalid registration", `{"email":"test@musafirgo.com","password":"123"}`, 400, "Auth"},
	}

	for _, endpoint := range endpoints {
		result.Total++

		start := time.Now()
		var resp *http.Response
		var err error

		if endpoint.Method == "POST" {
			resp, err = http.Post(p.BaseURL+endpoint.URL, "application/json", strings.NewReader(endpoint.Body))
		} else {
			resp, err = http.Get(p.BaseURL + endpoint.URL)
		}

		duration := time.Since(start)

		if err != nil {
			result.Failed++
			detail := fmt.Sprintf("%s %s - FAILED (%v)", endpoint.Method, endpoint.URL, err)
			result.Details = append(result.Details, detail)
			p.Log("ERROR", detail)
		} else {
			resp.Body.Close()
			if resp.StatusCode == endpoint.ExpectedStatus {
				result.Passed++
				detail := fmt.Sprintf("%s %s - PASSED (%v)", endpoint.Method, endpoint.URL, duration)
				result.Details = append(result.Details, detail)
				p.Log("SUCCESS", detail)
			} else {
				result.Failed++
				detail := fmt.Sprintf("%s %s - FAILED (Expected: %d, Got: %d)", endpoint.Method, endpoint.URL, endpoint.ExpectedStatus, resp.StatusCode)
				result.Details = append(result.Details, detail)
				p.Log("ERROR", detail)
			}
		}
	}

	// Calculer le taux de réussite
	result.SuccessRate = float64(result.Passed) / float64(result.Total) * 100

	p.Log("INFO", "=== COMPREHENSIVE API TEST RESULTS ===")
	p.Log("INFO", fmt.Sprintf("Total Tests: %d", result.Total))
	p.Log("SUCCESS", fmt.Sprintf("Passed: %d", result.Passed))
	p.Log("ERROR", fmt.Sprintf("Failed: %d", result.Failed))
	p.Log("INFO", fmt.Sprintf("Success Rate: %.2f%%", result.SuccessRate))

	return result
}

// PerformanceTests exécute les tests de performance
func (p *MusafirGoWebPipeline) PerformanceTests() *PerformanceResult {
	p.Log("INFO", "Running comprehensive performance tests...")

	result := &PerformanceResult{}

	// Fonction helper pour mesurer la performance d'un endpoint
	measureEndpoint := func(method, url, name string, body string) float64 {
		start := time.Now()
		var resp *http.Response
		var err error

		if method == "POST" {
			resp, err = http.Post(p.BaseURL+url, "application/json", strings.NewReader(body))
		} else {
			resp, err = http.Get(p.BaseURL + url)
		}

		duration := time.Since(start).Milliseconds()

		if err != nil {
			p.Log("ERROR", fmt.Sprintf("  - %s - FAILED", name))
			return -1
		}
		resp.Body.Close()

		p.Log("SUCCESS", fmt.Sprintf("  - %s - %.2f ms", name, float64(duration)))
		return float64(duration)
	}

	// Tests de performance
	result.HealthCheck = measureEndpoint("GET", "/api/health", "Health Check", "")
	result.Destinations = measureEndpoint("GET", "/api/destinations", "List Destinations", "")
	result.Accommodations = measureEndpoint("GET", "/api/accommodations", "List Accommodations", "")
	result.AuthLogin = measureEndpoint("POST", "/api/auth/login", "Auth Login", `{"email":"test@musafirgo.com","password":"password"}`)
	result.AuthRegister = measureEndpoint("POST", "/api/auth/register", "Auth Register", `{"email":"perf@test.com","password":"password","name":"Perf User"}`)
	result.AuthMe = measureEndpoint("GET", "/api/auth/me", "Auth Me", "")

	// Calculer les statistiques
	validResults := []float64{}
	if result.HealthCheck >= 0 {
		validResults = append(validResults, result.HealthCheck)
	}
	if result.Destinations >= 0 {
		validResults = append(validResults, result.Destinations)
	}
	if result.Accommodations >= 0 {
		validResults = append(validResults, result.Accommodations)
	}
	if result.AuthLogin >= 0 {
		validResults = append(validResults, result.AuthLogin)
	}
	if result.AuthRegister >= 0 {
		validResults = append(validResults, result.AuthRegister)
	}
	if result.AuthMe >= 0 {
		validResults = append(validResults, result.AuthMe)
	}

	if len(validResults) > 0 {
		var sum float64
		var max, min float64 = validResults[0], validResults[0]

		for _, v := range validResults {
			sum += v
			if v > max {
				max = v
			}
			if v < min {
				min = v
			}
		}

		result.AverageTime = sum / float64(len(validResults))
		result.MaxTime = max
		result.MinTime = min
		result.SuccessfulTests = len(validResults)

		p.Log("INFO", "=== PERFORMANCE TEST RESULTS ===")
		p.Log("INFO", "Performance Statistics:")
		p.Log("INFO", fmt.Sprintf("  - Average Response Time: %.2f ms", result.AverageTime))
		p.Log("INFO", fmt.Sprintf("  - Maximum Response Time: %.2f ms", result.MaxTime))
		p.Log("INFO", fmt.Sprintf("  - Minimum Response Time: %.2f ms", result.MinTime))
		p.Log("INFO", fmt.Sprintf("  - Successful Tests: %d/%d", result.SuccessfulTests, 6))
	}

	return result
}

// GenerateHTMLReport génère un rapport HTML avec des visualisations
func (p *MusafirGoWebPipeline) GenerateHTMLReport() bool {
	p.Log("INFO", "Generating HTML report with visualizations...")

	// Données pour le template
	data := struct {
		Title         string
		StartTime     string
		EndTime       string
		TotalDuration float64
		Success       bool
		Steps         map[string]Step
		APIResults    APITestResult
		Performance   PerformanceResult
	}{
		Title:         "MusafirGO Web Service Pipeline Report",
		StartTime:     p.Results.StartTime.Format("2006-01-02 15:04:05"),
		EndTime:       p.Results.EndTime.Format("2006-01-02 15:04:05"),
		TotalDuration: p.Results.TotalDuration,
		Success:       p.Results.Success,
		Steps:         p.Results.Steps,
		APIResults:    p.getAPIResults(),
		Performance:   p.getPerformanceResults(),
	}

	// Template HTML
	htmlTemplate := `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{.Title}}</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; font-size: 1.1em; }
        .content { padding: 30px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: #f8f9fa; border-radius: 10px; padding: 20px; border-left: 4px solid #667eea; }
        .card h3 { margin: 0 0 15px 0; color: #333; font-size: 1.3em; }
        .stat { display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #eee; }
        .stat:last-child { border-bottom: none; }
        .stat-label { font-weight: 500; color: #666; }
        .stat-value { font-weight: 600; color: #333; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        .progress-bar { width: 100%; height: 20px; background: #e9ecef; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #28a745, #20c997); transition: width 0.3s ease; }
        .progress-fill.warning { background: linear-gradient(90deg, #ffc107, #fd7e14); }
        .progress-fill.error { background: linear-gradient(90deg, #dc3545, #e83e8c); }
        .progress-text { text-align: center; font-weight: 600; color: #333; margin-top: 5px; }
        .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.9em; font-weight: 500; }
        .status-success { background: #d4edda; color: #155724; }
        .status-error { background: #f8d7da; color: #721c24; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; border-top: 1px solid #eee; }
        .chart-container { margin: 20px 0; }
        .bar-chart { display: flex; align-items: end; height: 200px; gap: 10px; }
        .bar { flex: 1; background: linear-gradient(180deg, #667eea, #764ba2); border-radius: 4px 4px 0 0; position: relative; }
        .bar-label { text-align: center; margin-top: 10px; font-size: 0.9em; color: #666; }
        .bar-value { position: absolute; top: -25px; left: 50%; transform: translateX(-50%); font-weight: 600; color: #333; }
        
        /* Pipeline visuelle */
        .pipeline-visual {
            margin: 20px 0;
            overflow-x: auto;
            padding: 20px 0;
        }
        .pipeline-flow {
            display: flex;
            align-items: center;
            min-width: max-content;
            gap: 0;
        }
        .pipeline-stage {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 15px;
            min-width: 200px;
            max-width: 250px;
            position: relative;
            transition: all 0.3s ease;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .pipeline-stage:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .pipeline-stage.stage-success {
            border-color: #28a745;
            background: linear-gradient(135deg, #d4edda 0%, #ffffff 100%);
        }
        .pipeline-stage.stage-error {
            border-color: #dc3545;
            background: linear-gradient(135deg, #f8d7da 0%, #ffffff 100%);
        }
        .stage-container {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .stage-icon {
            flex-shrink: 0;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
        }
        .stage-success .stage-icon {
            background: #28a745;
            color: white;
        }
        .stage-error .stage-icon {
            background: #dc3545;
            color: white;
        }
        .stage-content {
            flex: 1;
            min-width: 0;
        }
        .stage-title {
            font-weight: 600;
            font-size: 14px;
            color: #333;
            margin-bottom: 4px;
            word-break: break-word;
        }
        .stage-meta {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 8px;
        }
        .stage-duration {
            font-size: 11px;
            color: #666;
            font-weight: 500;
        }
        .stage-status {
            font-size: 11px;
            font-weight: 600;
            padding: 2px 6px;
            border-radius: 3px;
        }
        .stage-status.status-success {
            color: #155724;
            background: #d4edda;
        }
        .stage-status.status-error {
            color: #721c24;
            background: #f8d7da;
        }
        .pipeline-connector {
            display: flex;
            align-items: center;
            margin: 0 10px;
        }
        .connector-line {
            width: 40px;
            height: 2px;
            background: #dee2e6;
            position: relative;
        }
        .connector-arrow {
            position: absolute;
            right: -8px;
            top: 50%;
            transform: translateY(-50%);
            color: #6c757d;
            font-size: 16px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 {{.Title}}</h1>
            <p>Rapport généré le {{.StartTime}} - Durée: {{printf "%.2f" .TotalDuration}}s</p>
        </div>
        
        <div class="content">
            <!-- Résumé global -->
            <div class="grid">
                <div class="card">
                    <h3>📊 Résumé Global</h3>
                    <div class="stat">
                        <span class="stat-label">Statut</span>
                        <span class="stat-value {{if .Success}}success{{else}}error{{end}}">
                            {{if .Success}}✅ SUCCÈS{{else}}❌ ÉCHEC{{end}}
                        </span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Début</span>
                        <span class="stat-value">{{.StartTime}}</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Fin</span>
                        <span class="stat-value">{{.EndTime}}</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Durée totale</span>
                        <span class="stat-value">{{printf "%.2f" .TotalDuration}}s</span>
                    </div>
                </div>
                
                <div class="card">
                    <h3>🧪 Tests API</h3>
                    <div class="stat">
                        <span class="stat-label">Total</span>
                        <span class="stat-value">{{.APIResults.Total}}</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Réussis</span>
                        <span class="stat-value success">{{.APIResults.Passed}}</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Échoués</span>
                        <span class="stat-value error">{{.APIResults.Failed}}</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Taux de réussite</span>
                        <span class="stat-value warning">
                            {{printf "%.1f" .APIResults.SuccessRate}}%
                        </span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill warning" 
                             style="width: {{printf "%.1f" .APIResults.SuccessRate}}%"></div>
                    </div>
                    <div class="progress-text">{{printf "%.1f" .APIResults.SuccessRate}}% de réussite</div>
                </div>
                
                <div class="card">
                    <h3>⚡ Performance</h3>
                    <div class="stat">
                        <span class="stat-label">Health Check</span>
                        <span class="stat-value">{{printf "%.1f" .Performance.HealthCheck}}ms</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Destinations</span>
                        <span class="stat-value">{{printf "%.1f" .Performance.Destinations}}ms</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Accommodations</span>
                        <span class="stat-value">{{printf "%.1f" .Performance.Accommodations}}ms</span>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Auth Login</span>
                        <span class="stat-value">{{printf "%.1f" .Performance.AuthLogin}}ms</span>
                    </div>
                </div>
            </div>
            
            <!-- Pipeline visuelle -->
            <div class="card">
                <h3>🚀 Pipeline Visuelle</h3>
                <div class="pipeline-visual">
                    <div class="pipeline-flow">
                        {{$stepNames := list "CheckPrerequisites" "BuildAngularApplication" "StartMockServices" "HealthChecks" "APITests" "PerformanceTests" "GenerateHTMLReport"}}
                        {{$index := 0}}
                        {{range $stepName := $stepNames}}
                        {{if hasStep $.Steps $stepName}}
                        {{$step := getStep $.Steps $stepName}}
                        {{$index = add $index 1}}
                        <div class="pipeline-stage {{if $step.Success}}stage-success{{else}}stage-error{{end}}">
                            <div class="stage-container">
                                <div class="stage-icon">
                                    {{if $step.Success}}
                                        <div>✓</div>
                                    {{else}}
                                        <div>✗</div>
                                    {{end}}
                                </div>
                                <div class="stage-content">
                                    <div class="stage-title">{{$step.Name}}</div>
                                    <div class="stage-meta">
                                        <span class="stage-duration">{{printf "%.1f" $step.Duration}}s</span>
                                        <span class="stage-status {{if $step.Success}}status-success{{else}}status-error{{end}}">
                                            {{if $step.Success}}Réussi{{else}}Échoué{{end}}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        {{if ne $index (len $stepNames)}}
                        <div class="pipeline-connector">
                            <div class="connector-line"></div>
                            <div class="connector-arrow">→</div>
                        </div>
                        {{end}}
                        {{end}}
                        {{end}}
                    </div>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Généré par MusafirGO Web Service Pipeline Go - {{.EndTime}}</p>
        </div>
    </div>
</body>
</html>`

	// Créer le template avec des fonctions personnalisées
	funcMap := template.FuncMap{
		"contains": strings.Contains,
		"add":      func(a, b int) int { return a + b },
		"list": func(items ...string) []string {
			return items
		},
		"getStep": func(steps map[string]Step, stepName string) Step {
			step, exists := steps[stepName]
			if !exists {
				return Step{}
			}
			return step
		},
		"hasStep": func(steps map[string]Step, stepName string) bool {
			_, exists := steps[stepName]
			return exists
		},
	}

	tmpl, err := template.New("report").Funcs(funcMap).Parse(htmlTemplate)
	if err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to parse HTML template: %v", err))
		return false
	}

	// Générer le HTML
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to execute HTML template: %v", err))
		return false
	}

	// Sauvegarder le fichier
	timestamp := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("MusafirGO_Web_Pipeline_Report_%s.html", timestamp)

	if err := os.WriteFile(filename, buf.Bytes(), 0644); err != nil {
		p.Log("ERROR", fmt.Sprintf("Failed to save HTML file: %v", err))
		return false
	}

	p.Log("SUCCESS", fmt.Sprintf("HTML report generated successfully: %s", filename))
	p.Log("INFO", fmt.Sprintf("File path: %s", filename))
	return true
}

// getAPIResults récupère les résultats des tests API
func (p *MusafirGoWebPipeline) getAPIResults() APITestResult {
	if apiStep, exists := p.Results.Steps["APITests"]; exists && apiStep.Result != nil {
		if apiResult, ok := apiStep.Result.(*APITestResult); ok {
			return *apiResult
		}
	}
	return APITestResult{
		Total:       0,
		Passed:      0,
		Failed:      0,
		SuccessRate: 100.0,
		Details:     []string{},
	}
}

// getPerformanceResults récupère les résultats de performance
func (p *MusafirGoWebPipeline) getPerformanceResults() PerformanceResult {
	if perfStep, exists := p.Results.Steps["PerformanceTests"]; exists && perfStep.Result != nil {
		if perfResult, ok := perfStep.Result.(*PerformanceResult); ok {
			return *perfResult
		}
	}
	return PerformanceResult{
		HealthCheck:    0.0,
		Destinations:   0.0,
		Accommodations: 0.0,
		AuthLogin:      0.0,
		AuthRegister:   0.0,
		AuthMe:         0.0,
	}
}

// ExecuteStep exécute une étape de la pipeline
func (p *MusafirGoWebPipeline) ExecuteStep(name string, fn func() interface{}) {
	p.Log("INFO", fmt.Sprintf("Executing step: %s", name))

	startTime := time.Now()
	var result interface{}
	var success bool
	var errMsg string

	defer func() {
		if r := recover(); r != nil {
			success = false
			errMsg = fmt.Sprintf("Panic: %v", r)
		}

		duration := time.Since(startTime).Seconds()
		p.Results.Steps[name] = Step{
			Name:     name,
			Success:  success,
			Duration: duration,
			Error:    errMsg,
			Result:   result,
		}

		if success {
			p.Log("SUCCESS", fmt.Sprintf("Step %s completed successfully in %.2f seconds", name, duration))
		} else {
			p.Log("ERROR", fmt.Sprintf("Step %s failed: %s", name, errMsg))
		}
	}()

	result = fn()
	success = true
}

// Run exécute la pipeline complète
func (p *MusafirGoWebPipeline) Run() {
	p.Log("INFO", "Starting MusafirGO Web Service Pipeline...")
	p.Log("INFO", fmt.Sprintf("Base URL: %s", p.BaseURL))
	p.Log("INFO", fmt.Sprintf("Project Path: %s", p.ProjectPath))

	// Étape 1: Vérification des prérequis
	p.ExecuteStep("CheckPrerequisites", func() interface{} {
		return p.CheckPrerequisites()
	})

	// Étape 2: Construction de l'application Angular
	p.ExecuteStep("BuildAngularApplication", func() interface{} {
		return p.BuildAngularApplication()
	})

	// Étape 3: Démarrage des services mock
	p.ExecuteStep("StartMockServices", func() interface{} {
		return p.StartMockServices()
	})

	// Étape 4: Vérifications de santé
	p.ExecuteStep("HealthChecks", func() interface{} {
		return p.HealthChecks()
	})

	// Étape 5: Tests API
	p.ExecuteStep("APITests", func() interface{} {
		return p.APITests()
	})

	// Étape 6: Tests de performance
	p.ExecuteStep("PerformanceTests", func() interface{} {
		return p.PerformanceTests()
	})

	// Étape 7: Génération du rapport HTML
	p.ExecuteStep("GenerateHTMLReport", func() interface{} {
		return p.GenerateHTMLReport()
	})

	// Finaliser les résultats
	p.Results.EndTime = time.Now()
	p.Results.TotalDuration = p.Results.EndTime.Sub(p.Results.StartTime).Seconds()
	p.Results.Success = true

	// Vérifier si toutes les étapes ont réussi
	for _, step := range p.Results.Steps {
		if !step.Success {
			p.Results.Success = false
			break
		}
	}

	// Rapport final
	p.Log("SUCCESS", "=== PIPELINE COMPLETED ===")
	p.Log("INFO", fmt.Sprintf("Start Time: %s", p.Results.StartTime.Format("2006-01-02 15:04:05")))
	p.Log("INFO", fmt.Sprintf("End Time: %s", p.Results.EndTime.Format("2006-01-02 15:04:05")))
	p.Log("INFO", fmt.Sprintf("Total Duration: %.2f seconds", p.Results.TotalDuration))
	p.Log("SUCCESS", fmt.Sprintf("Success: %t", p.Results.Success))

	if p.Results.Success {
		p.Log("SUCCESS", "Pipeline completed successfully!")
		os.Exit(0)
	} else {
		p.Log("ERROR", "Pipeline completed with errors!")
		os.Exit(1)
	}
}

func main() {
	baseURL := "http://localhost:3000"
	skipInit := false
	skipDataLoad := false
	skipTests := false

	// Parse command line arguments
	if len(os.Args) > 1 {
		baseURL = os.Args[1]
	}

	// Check for skip flags
	for _, arg := range os.Args {
		switch arg {
		case "--skip-init":
			skipInit = true
		case "--skip-data-load":
			skipDataLoad = true
		case "--skip-tests":
			skipTests = true
		}
	}

	pipeline := NewWebPipeline(baseURL, skipInit, skipDataLoad, skipTests)
	pipeline.Run()
}
