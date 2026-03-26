resource "kubernetes_pod" "test_pod" {
  metadata {
    name      = "security-test"
    namespace = ""
  }

  spec {
    container {
      name  = "nginx"
      image = "nginx:1.25.3" # Best Practice: Use a specific version, not 'latest'

      security_context {
        # 1. DISABLE PRIVILEGED MODE
        privileged = false
        
        # 2. PREVENT PRIVILEGE ESCALATION
        allow_privilege_escalation = false
        
        # 3. RUN AS NON-ROOT (Use a high UID like 1000)
        run_as_non_root = true
        run_as_user     = 1000

        # 4. READ-ONLY FILESYSTEM
        read_only_root_filesystem = true

        capabilities {
          drop = ["ALL"] # Drop all Linux capabilities
        }
      }
    }
  }
}